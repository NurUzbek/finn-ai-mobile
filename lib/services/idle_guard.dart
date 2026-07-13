import 'dart:async';
import 'package:flutter/material.dart';

/// TZ 4.1.6.7: foydalanuvchi hech qanday harakat qilmaganda sessiyaning amal qilish
/// vaqti 3 daqiqadan oshmasligi kerak — muddat tugagach sessiya avtomatik tugatiladi
/// va qayta autentifikatsiya talab qilinadi.
///
/// Butun ilovani shu widget bilan o'raymiz: har qanday teginish taymerni qayta boshlaydi.
class IdleGuard extends StatefulWidget {
  final Widget child;
  final Duration timeout;
  final VoidCallback onTimeout;

  const IdleGuard({
    super.key,
    required this.child,
    required this.onTimeout,
    this.timeout = const Duration(minutes: 3),
  });

  @override
  State<IdleGuard> createState() => _IdleGuardState();
}

class _IdleGuardState extends State<IdleGuard> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, widget.onTimeout);
  }

  /// Ilova fonga o'tib qaytganda ham muddat hisoblanadi (TZ talabi).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      final away = _backgroundedAt == null ? Duration.zero : DateTime.now().difference(_backgroundedAt!);
      if (away >= widget.timeout) {
        widget.onTimeout();
      } else {
        _reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _reset(),
      onPointerMove: (_) => _reset(),
      child: widget.child,
    );
  }
}
