import 'package:flutter/foundation.dart';

import 'api.dart';

/// RBAC — foydalanuvchi roli va ruxsatlari (TZ 3.13).
///
/// Hisob egasi (roli biriktirilmagan) = 'super-admin' (to'liq huquq).
/// JAMOAga taklif qilingan a'zolar o'z roliga qarab cheklanadi:
///  • admin      — obuna/audit/tarjimadan tashqari hammasi
///  • accountant — moliya/hujjat/hisobot (view/create/edit, delete yo'q)
///  • observer   — faqat ko'rish (read-only)
class PermState {
  PermState._();
  static final PermState i = PermState._();

  String role = 'super-admin';
  Set<String> perms = {};
  bool loaded = false;

  /// Hali demo rejimidagi davlat integratsiyalari ('soliq', 'mib').
  /// Server javobigacha ikkalasi ham demo deb olinadi — xato tomonga emas,
  /// ochiqlik tomonga: belgi keraksiz chiqsa ham, yashirin qolmasin.
  static final ValueNotifier<Set<String>> demo = ValueNotifier({'soliq', 'mib'});

  bool get isOwner => role == 'super-admin';
  bool get isObserver => role == 'observer';

  /// "module.action" ruxsati bormi (egada doim bor).
  bool can(String permission) => isOwner || perms.contains(permission);

  /// Modulni ko'rish mumkinmi (perm null bo'lsa — doim ha).
  bool canView(String? modulePerm) =>
      modulePerm == null || can(modulePerm);

  /// Tahrir/qo'shish/o'chirish — observer uchun doim yo'q.
  bool canEdit(String module) =>
      !isObserver && (isOwner || perms.contains('$module.edit') || perms.contains('$module.create'));

  Future<void> load() async {
    try {
      final d = await Api.me();
      if (d['ok'] == true) {
        role = (d['role'] ?? 'super-admin').toString();
        perms = ((d['permissions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toSet();
        loaded = true;
        final ds = d['demo_sources'];
        if (ds is Map) {
          demo.value = {for (final e in ds.entries) if (e.value == true) e.key.toString()};
        }
      }
    } catch (_) {
      // Aloqa yo'q — egasi sifatida (to'liq) qoldiramiz, xavfsiz tomonga emas
      // balki foydalanuvchi ishlay olishi uchun (offline). Backend baribir tekshiradi.
    }
  }

  void clear() {
    role = 'super-admin';
    perms = {};
    loaded = false;
  }
}
