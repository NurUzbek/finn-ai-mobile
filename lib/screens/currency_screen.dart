import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Valyuta kurslari ekrani — CBU kurslari, o'zgarish trendi bilan.
class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.currency();
  }

  Future<void> _refresh() async {
    setState(() => _future = Api.currency());
    await _future;
  }

  /// Valyuta kodiga mos brend rangi.
  Color _codeColor(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return C.green;
      case 'EUR':
        return C.blue;
      case 'RUB':
        return C.red;
      case 'GBP':
        return C.cyan;
      default:
        return C.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      appBar: AppBar(
        backgroundColor: C.bg(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Valyuta kurslari',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
            color: C.text(context),
          ),
        ),
        iconTheme: IconThemeData(color: C.text(context)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: C.cyan));
          }

          final data = snap.data ?? const {'ok': false};
          if (data['ok'] != true) {
            return _ErrorView(onRetry: _refresh);
          }

          final rawRates = data['rates'];
          final rates = <Map<String, dynamic>>[];
          if (rawRates is List) {
            for (final r in rawRates) {
              if (r is Map) rates.add(Map<String, dynamic>.from(r));
            }
          }

          return RefreshIndicator(
            color: C.cyan,
            backgroundColor: C.card(context),
            onRefresh: _refresh,
            child: rates.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.currency_exchange_rounded,
                        text: 'Kurslar yo\'q',
                        color: C.amber,
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: rates.length,
                    itemBuilder: (c, i) {
                      final m = rates[i];
                      final code = (m['code'] ?? '—').toString();
                      final rate = (m['rate'] is num)
                          ? m['rate'] as num
                          : num.tryParse('${m['rate']}') ?? 0;
                      final diff = (m['diff'] is num)
                          ? m['diff'] as num
                          : num.tryParse('${m['diff']}') ?? 0;
                      final date = (m['date'] ?? '').toString();
                      return StaggerIn(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RateCard(
                            code: code,
                            rate: rate,
                            diff: diff,
                            date: date,
                            color: _codeColor(code),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  final String code;
  final num rate;
  final num diff;
  final String date;
  final Color color;

  const _RateCard({
    required this.code,
    required this.rate,
    required this.diff,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dark = C.isDark(context);
    final up = diff > 0;
    final down = diff < 0;
    final trendColor = up
        ? C.green
        : down
            ? C.red
            : C.muted(context, .5);
    final trendIcon = up
        ? Icons.arrow_upward_rounded
        : down
            ? Icons.arrow_downward_rounded
            : Icons.remove_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : const Color(0xFF1B2A4A))
                .withValues(alpha: dark ? .25 : .06),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bayroqsimon dumaloq nishon
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: .3), width: 1.5),
            ),
            child: Text(
              code.length >= 2 ? code.substring(0, 2) : code,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Kod + sana
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: C.text(context),
                  ),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(fontSize: 11.5, color: C.muted(context, .5)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Kurs + trend chipi
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: money(rate),
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: C.text(context),
                        ),
                      ),
                      TextSpan(
                        text: ' so\'m',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: C.muted(context, .5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TrendChip(
                text: money(diff.abs()),
                color: trendColor,
                icon: trendIcon,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: C.red.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 32, color: C.red),
            ),
            const SizedBox(height: 16),
            Text(
              'Server bilan aloqa yo\'q',
              textAlign: TextAlign.center,
              style: TextStyle(color: C.muted(context, .6), fontSize: 13.5),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: C.cyan),
              label: const Text('Qayta urinish', style: TextStyle(color: C.cyan)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: C.cyan.withValues(alpha: .5)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
