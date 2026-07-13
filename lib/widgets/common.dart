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
              Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: .45))),
            ]),
          ),
          if (action != null) action!,
        ]),
      );
}

/// Statistika kartasi (gradient chegara + katta raqam)
class StatCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color, this.unit = ''});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: C.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .22)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              if (unit.isNotEmpty)
                Text(' $unit', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: .5))),
            ]),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: .5))),
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
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 13.5)),
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
            backgroundColor: C.cardDark,
            onRefresh: onRefresh,
            child: builder(d),
          );
        },
      );
}
