import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Uchinchi, Dart darajasidagi klient tekshiruvi (Android).
///
/// Ekspertiza (2026-11-02) ko'rsatdiki, Kotlin/Java qatlami (freeRASP
/// dispetcheri, DeviceSecurityPlugin) smali tahriri bilan bir necha qatorda
/// o'chiriladi. Bu tekshiruvlar esa Dart'da — AOT bilan obfuskatsiyalangan
/// ARM64 mashina kodiga (libapp.so) kompilyatsiya bo'ladi va MethodChannel'ga
/// tayanmaydi: ularni o'chirish uchun mashina kodini patch qilish kerak.
///
///   • imzo     — o'z APK faylimizni diskdan o'qib, APK Signing Block (v2/v3)
///                ichidagi sertifikat SHA-256 ni kutilgan kalitlar bilan solishtiradi
///   • hook     — /proc/self/maps da instrumentatsiya izlari
///   • debug    — /proc/self/status TracerPid
///   • root     — su binarlari
///
/// Natija faqat ANIQ dalil bo'lganda xavf qaytaradi; faylni o'qib bo'lmasa
/// (noma'lum format) jim o'tadi — server attestatsiyasi baribir ushlaydi.
class Integrity {
  Integrity._();

  /// Kutilgan imzo sertifikatlari SHA-256 (base64) — security.dart bilan bir xil.
  static const _expected = {
    'j7mLhbvRfbzqX6c2akR9l1g3l6lPT8sbCsdPT9TY4xk=', // finn.uz upload kaliti (sideload)
    'bZCeu8rBIOqfWyQyQnHCPB/GMtEU+PZuUPaJ23+Qwdo=', // Play App Signing kaliti
  };

  /// Aniqlangan xavflar (security.dart turlari bilan bir xil nomlar).
  static Future<List<String>> check() async {
    if (!Platform.isAndroid) return const [];
    final flags = <String>[];
    String maps = '';
    try {
      maps = await File('/proc/self/maps').readAsString();
    } catch (_) {}

    try {
      if (_hooked(maps)) flags.add('hook');
    } catch (_) {}
    try {
      if (await _traced()) flags.add('debug');
    } catch (_) {}
    try {
      if (_rooted()) flags.add('root');
    } catch (_) {}
    try {
      if (await _signatureForeign(maps)) flags.add('integrity');
    } catch (_) {}
    return flags;
  }

  // ───────────────────────── hook ─────────────────────────
  static bool _hooked(String maps) {
    final m = maps.toLowerCase();
    const needles = ['frida', 'gum-js-loop', 'gadget', 'linjector', 'xposed', 'lsposed', 'substrate', 'zygisk'];
    return needles.any(m.contains);
  }

  // ───────────────────────── debugger ─────────────────────────
  static Future<bool> _traced() async {
    final status = await File('/proc/self/status').readAsLines();
    for (final l in status) {
      if (l.startsWith('TracerPid:')) {
        return (int.tryParse(l.substring(10).trim()) ?? 0) != 0;
      }
    }
    return false;
  }

  // ───────────────────────── root ─────────────────────────
  static bool _rooted() {
    const paths = [
      '/system/bin/su', '/system/xbin/su', '/sbin/su', '/system/sd/xbin/su',
      '/system/bin/failsafe/su', '/data/local/su', '/data/local/xbin/su',
      '/su/bin/su', '/magisk/.core/bin/su', '/data/adb/magisk',
    ];
    return paths.any((p) => File(p).existsSync() || Directory(p).existsSync());
  }

  // ───────────────────────── imzo ─────────────────────────

  /// true — APK imzosi aniq o'qildi va bizniki EMAS.
  static Future<bool> _signatureForeign(String maps) async {
    final apk = _baseApkPath(maps);
    if (apk == null) return false;
    final certs = await _signerCerts(apk);
    if (certs.isEmpty) return false; // o'qib bo'lmadi — dalil yo'q
    for (final c in certs) {
      if (_expected.contains(base64.encode(sha256.convert(c).bytes))) return false;
    }
    return true;
  }

  /// APK imzolovchi sertifikatlarining SHA-256 (base64) — test uchun ham.
  static Future<List<String>> certHashes(String apkPath) async =>
      [for (final c in await _signerCerts(apkPath)) base64.encode(sha256.convert(c).bytes)];

  /// Jarayonga yuklangan o'z base.apk yo'li (/data/app/.../base.apk).
  static String? _baseApkPath(String maps) {
    for (final line in const LineSplitter().convert(maps)) {
      final i = line.indexOf('/data/app/');
      if (i < 0) continue;
      final p = line.substring(i).trim();
      if (p.endsWith('/base.apk') && p.contains('uz.finn.app')) return p;
    }
    return null;
  }

  static const _sigV2 = 0x7109871a;
  static const _sigV3 = 0xf05368c0;
  static const _sigV31 = 0x1b93ad61;

  /// APK Signing Block'dan imzolovchi sertifikatlar (DER).
  static Future<List<Uint8List>> _signerCerts(String path) async {
    final f = await File(path).open();
    try {
      final len = await f.length();

      // 1) End of Central Directory (oxirgi 64 KB + 22 bayt ichida)
      final tailLen = len < 65557 ? len : 65557;
      await f.setPosition(len - tailLen);
      final tail = await f.read(tailLen);
      int eocd = -1;
      for (var i = tail.length - 22; i >= 0; i--) {
        if (tail[i] == 0x50 && tail[i + 1] == 0x4b && tail[i + 2] == 0x05 && tail[i + 3] == 0x06) {
          eocd = i;
          break;
        }
      }
      if (eocd < 0) return const [];
      final cdOffset = ByteData.sublistView(tail, eocd + 16, eocd + 20).getUint32(0, Endian.little);

      // 2) Signing Block oxiri: [size u64][magic 16 bayt] — CD dan oldin
      if (cdOffset < 32) return const [];
      await f.setPosition(cdOffset - 24);
      final footer = await f.read(24);
      if (ascii.decode(footer.sublist(8), allowInvalid: true) != 'APK Sig Block 42') return const [];
      final blockSize = ByteData.sublistView(footer, 0, 8).getUint64(0, Endian.little);
      final start = cdOffset - blockSize - 8;
      if (start < 0 || blockSize > 16 * 1024 * 1024) return const [];

      // 3) ID-qiymat juftliklari
      await f.setPosition(start + 8);
      final pairs = await f.read(blockSize - 24);
      final bd = ByteData.sublistView(pairs);
      final found = <int, Uint8List>{};
      var p = 0;
      while (p + 12 <= pairs.length) {
        final pLen = bd.getUint64(p, Endian.little);
        final id = bd.getUint32(p + 8, Endian.little);
        final vStart = p + 12;
        final vEnd = p + 8 + pLen;
        if (pLen < 4 || vEnd > pairs.length) break;
        found[id] = Uint8List.sublistView(pairs, vStart, vEnd);
        p = vEnd;
      }
      final block = found[_sigV31] ?? found[_sigV3] ?? found[_sigV2];
      if (block == null) return const [];
      return _certsFromScheme(block);
    } finally {
      await f.close();
    }
  }

  /// v2/v3 tuzilmasi: signers → signer → signedData → (digests, certificates).
  static List<Uint8List> _certsFromScheme(Uint8List v) {
    final out = <Uint8List>[];
    final signers = _LP(v).next();
    if (signers == null) return out;
    final sr = _LP(signers);
    for (var signer = sr.next(); signer != null; signer = sr.next()) {
      final signedData = _LP(signer).next();
      if (signedData == null) continue;
      final sd = _LP(signedData);
      sd.next(); // digests
      final certs = sd.next();
      if (certs == null) continue;
      final cr = _LP(certs);
      for (var c = cr.next(); c != null; c = cr.next()) {
        out.add(c);
      }
    }
    return out;
  }
}

/// uint32 (LE) uzunlik prefiksli ketma-ketlik o'quvchisi.
class _LP {
  _LP(this.b);
  final Uint8List b;
  int _p = 0;

  Uint8List? next() {
    if (_p + 4 > b.length) return null;
    final n = ByteData.sublistView(b, _p, _p + 4).getUint32(0, Endian.little);
    final s = _p + 4;
    if (s + n > b.length) return null;
    _p = s + n;
    return Uint8List.sublistView(b, s, s + n);
  }
}
