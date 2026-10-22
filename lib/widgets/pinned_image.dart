import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/pinned_http.dart';

/// `Image.network` o'rnini bosadi: finn.uz'dan keladigan rasm SSL pinning
/// qilingan klient orqali yuklanadi (ekspertiza 2.2.3). `Image.network`
/// Flutter'ning standart klientidan foydalanadi va pinning'ni chetlab o'tardi.
///
/// Boshqa hostdagi rasm (masalan, tashqi profil surati) oddiy `Image.network`
/// bilan ko'rsatiladi — pinned klient uni rad etib, rasmni buzmasligi uchun.
class PinnedImage extends StatefulWidget {
  final String url;
  final BoxFit? fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  const PinnedImage(this.url, {super.key, this.fit, this.errorBuilder});

  @override
  State<PinnedImage> createState() => _PinnedImageState();
}

class _PinnedImageState extends State<PinnedImage> {
  // Ilova davomida qayta yuklamaslik uchun (avatar bir necha ekranda chiqadi).
  static final Map<String, Uint8List> _cache = {};

  Uint8List? _bytes;
  Object? _error;
  late bool _pinned;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant PinnedImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _resolve();
  }

  void _resolve() {
    final uri = Uri.tryParse(widget.url);
    _pinned = uri != null && PinnedHttp.isFinnHost(uri.host);
    _bytes = _cache[widget.url];
    _error = null;
    if (_pinned && _bytes == null) _load(widget.url);
  }

  Future<void> _load(String url) async {
    try {
      final client = await PinnedHttp.client();
      final r = await client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200 || r.bodyBytes.isEmpty) {
        throw Exception('HTTP ${r.statusCode}');
      }
      _cache[url] = r.bodyBytes;
      if (mounted && widget.url == url) setState(() => _bytes = r.bodyBytes);
    } catch (e) {
      if (mounted && widget.url == url) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_pinned) {
      return Image.network(widget.url, fit: widget.fit, errorBuilder: widget.errorBuilder);
    }
    final b = _bytes;
    if (b != null) {
      return Image.memory(b, fit: widget.fit, errorBuilder: widget.errorBuilder);
    }
    final e = _error;
    if (e != null) {
      return widget.errorBuilder?.call(context, e, null) ?? const SizedBox.shrink();
    }
    return const SizedBox.shrink(); // yuklanmoqda
  }
}
