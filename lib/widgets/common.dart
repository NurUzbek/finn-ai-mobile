import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';

final _nf = NumberFormat('#,###', 'ru');
String money(num v) => _nf.format(v.round()).replaceAll(',', ' ');

/// Sarlavha (har ekran boshida)
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;
  const ScreenHeader({super.key, required this.title, required this.icon, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [C.blue, C.cyan]),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: C.text(context))),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(fontSize: 12, color: C.muted(context, .5))),
            ]),
          ),
          if (action != null) action!,
        ]),
      );
}

/// Bosqichma-bosqich kirish animatsiyasi (fade + pastdan yuqoriga siljish).
/// `index` — kechikishni belgilaydi (har biri ~55ms).
class StaggerIn extends StatefulWidget {
  final int index;
  final Widget child;
  const StaggerIn({super.key, required this.index, required this.child});
  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 40 + widget.index * 55), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOut,
        opacity: _shown ? 1 : 0,
        // FIKSLANGAN 10px yuqoriga siljish (AnimatedSlide FRAKSIYA edi — baland
        // kartada katta piksel bo'lib pastdagi kartani USTIGA bosardi = overlap).
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _shown ? 0 : 10, 0),
          child: widget.child,
        ),
      );
}

/// Kichik trend / holat chipi (yashil ↑ / qizil ↓ yoki neytral).
class TrendChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const TrendChip({super.key, required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 11, color: color), const SizedBox(width: 3)],
          Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
        ]),
      );
}

/// Statistika kartasi (yumshoq ikonka + katta raqam + ixtiyoriy trend chipi)
class StatCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  final Widget? badge;
  final num? animateValue;
  final String Function(num)? valueFormat;
  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color, this.unit = '', this.badge, this.animateValue, this.valueFormat});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: C.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .2)),
          boxShadow: C.isDark(context)
              ? null
              : [BoxShadow(color: C.inkLight.withValues(alpha: .05), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 16, color: color),
            ),
            const Spacer(),
            if (badge != null) badge!,
          ]),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              if (animateValue != null)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: animateValue!.toDouble()),
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeOutCubic,
                  builder: (c, v, _) => Text(
                    (valueFormat ?? (x) => x.round().toString())(v),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: C.text(context)),
                  ),
                )
              else
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: C.text(context))),
              if (unit.isNotEmpty)
                Text(' $unit', style: TextStyle(fontSize: 11, color: C.muted(context, .5))),
            ]),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11.5, color: C.muted(context, .5))),
        ]),
      );
}

/// Bo'sh holat
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const EmptyState({super.key, required this.icon, required this.text, this.color = C.green});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: color.withValues(alpha: .1), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: C.muted(context, .5), fontSize: 13.5)),
          ]),
        ),
      );
}

/// Yuklanish / xato holati bilan ma'lumot yuklovchi qobiq
class Loader extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final Widget Function(Map<String, dynamic> data) builder;
  final Future<void> Function() onRefresh;
  const Loader({super.key, required this.future, required this.builder, required this.onRefresh});

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: C.cyan));
          }
          final d = snap.data ?? {'ok': false, 'message': 'Xatolik'};
          if (d['ok'] != true) {
            return EmptyState(icon: Icons.cloud_off_rounded, color: C.red, text: d['message'] ?? 'Ma\'lumot olinmadi');
          }
          return RefreshIndicator(
            color: C.cyan,
            backgroundColor: C.card(ctx),
            onRefresh: onRefresh,
            child: builder(d),
          );
        },
      );
}
