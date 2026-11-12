import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../services/i18n.dart';

/// Asosiy ekran (dashboard).
///
/// Bu fayl HTML prototipdan 1:1 ko'chirilgan. AGENT BU FAYLNI
/// O'ZGARTIRMAYDI — faqat ma'lumot manbasini ulaydi.
///
/// Diqqat: butun kontent oddiy `Column`. `Stack` faqat halqa
/// markazidagi raqam uchun ishlatilgan. Hech bir karta boshqasining
/// ustiga qo'yilmaydi.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.data,
    this.navIndex = 0,
    this.onNavChanged,
    this.onMenu,
    this.onRefresh,
    this.onNotif,
    this.onAiTap,
    this.onKalendar,
    this.onBatafsil,
    this.onBalance,
    this.onPenya,
  });

  final DashboardData data;
  final int navIndex;
  final ValueChanged<int>? onNavChanged;
  // Funksional ulanishlar (dizayn o'zgarmaydi — faqat harakat qo'shiladi).
  final VoidCallback? onMenu, onRefresh, onNotif, onAiTap, onKalendar,
      onBatafsil, onBalance, onPenya;

  @override
  Widget build(BuildContext context) {
    return FinnScreen(
      govSources: true,
      demoData: const ['soliq'],
      title: tr('nav.home'),
      subtitle: tr('dash.subtitle'),
      showNav: false,
      reserveNav: true,
      // ☰ modullar menyusi TZ bo'yicha OLIB TASHLANGAN — leading yo'q.
      actions: [
        _IconButtonSquare(icon: Icons.refresh_rounded, onTap: onRefresh ?? () {}),
        const SizedBox(width: 8),
        _IconButtonSquare(
            icon: Icons.notifications_none_rounded, onTap: onNotif ?? () {}),
      ],
      children: [
        const SizedBox(height: 12),
        GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBalance,
            child: BalanceCard(data: data)),

        const SizedBox(height: 11),
        GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPenya,
            child: PenyaRow(total: data.penyaTotal, perDay: data.penyaPerDay)),

        const SizedBox(height: 24),
        SectionHeader(tr('dash.deadlines'), action: tr('mod.calendar'), onTap: onKalendar),
        const SizedBox(height: 12),
        DeadlineGrid(items: data.deadlines),

        const SizedBox(height: 24),
        SectionHeader(tr('dash.cashflow'), action: tr('common.details'), onTap: onBatafsil),
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBatafsil,
          child: CashFlowCard(
            profit: data.profit,
            growth: data.growth,
            income: data.income,
            expense: data.expense,
            points: data.flowPoints,
          ),
        ),

        const SizedBox(height: 24),
        SectionHeader(tr('dash.status')),
        const SizedBox(height: 12),
        StatusRow(
            risk: data.riskScore,
            debt: data.debtTotal,
            overdue: data.overdueCount),

        // ── AI kartasi: ODDIY QATOR, hech narsaning ustida emas ──
        const SizedBox(height: 24),
        SectionHeader(tr('dash.finnAi')),
        const SizedBox(height: 12),
        AiCard(
          title: data.aiTitle,
          body: data.aiBody,
          onTap: onAiTap ?? () {},
        ),

        const SizedBox(height: 24),
        SectionHeader(tr('dash.quickAccess')),
        const SizedBox(height: 12),
        QuickActions(items: data.quickActions),
      ],
    );
  }
}

// ═══════════════════════ ma'lumot ═══════════════════════

class DashboardData {
  const DashboardData({
    required this.balance,
    required this.orgCount,
    required this.cleanCount,
    required this.lateCount,
    required this.penyaTotal,
    required this.penyaPerDay,
    required this.deadlines,
    required this.profit,
    required this.growth,
    required this.income,
    required this.expense,
    required this.flowPoints,
    required this.riskScore,
    required this.debtTotal,
    required this.overdueCount,
    required this.aiTitle,
    required this.aiBody,
    required this.quickActions,
  });

  final int balance, orgCount, cleanCount, lateCount;
  final double penyaTotal;
  final int penyaPerDay;
  final List<DeadlineData> deadlines;
  final int profit, growth, income, expense;
  /// 0..1 oralig'idagi nuqtalar, kirim va chiqim uchun
  final List<double> flowPoints;
  final int riskScore, debtTotal, overdueCount;
  final String aiTitle, aiBody;
  final List<QuickAction> quickActions;
}

class QuickAction {
  const QuickAction(this.icon, this.label, this.tint, this.on, {this.onTap});
  final IconData icon;
  final String label;
  final Color Function(FinnTokens) tint;
  final Color Function(FinnTokens) on;
  final VoidCallback? onTap;
}

// ═══════════════════════ komponentlar ═══════════════════════

String _fmt(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return (n < 0 ? '−' : '') + b.toString();
}

class _IconButtonSquare extends StatelessWidget {
  const _IconButtonSquare({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.line, width: 1),
        ),
        child: Icon(icon, size: 18, color: t.ink2),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Text(title.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: t.line)),
        if (action != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onTap,
            child: Text(action!,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: t.blue)),
          ),
        ],
      ],
    );
  }
}

/// Gradient balans kartasi + sparkline
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: FinnTokens.brand,
        borderRadius: BorderRadius.circular(FinnTokens.rXl),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 10),
            blurRadius: 26,
            color: const Color(0xFF1440A0).withOpacity(0.22),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('dash.totalBalance'),
                    style: FinnText.label(Colors.white.withOpacity(0.82))),
                const SizedBox(height: 9),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(_fmt(data.balance),
                        style: FinnText.heroValue(Colors.white)),
                    const SizedBox(width: 7),
                    Text(tr('common.som'),
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            width: double.infinity,
            child: CustomPaint(painter: _SparkPainter(data.flowPoints)),
          ),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
            child: Row(
              children: [
                _stat('${data.orgCount}', tr('dash.orgs')),
                _stat('${data.cleanCount}', tr('dash.clean')),
                _stat('${data.lateCount}', tr('dash.overdue')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String v, String l) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(v,
                style: const TextStyle(
                    fontFamily: 'InterTight',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.63,
                    color: Colors.white)),
            const SizedBox(height: 3),
            Text(l,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    color: Colors.white.withOpacity(0.78))),
          ],
        ),
      );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.points);
  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path();
    final step = size.width / (points.length - 1);
    for (var i = 0; i < points.length; i++) {
      final x = i * step;
      final y = size.height - points[i].clamp(0, 1) * (size.height - 6) - 3;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fill, Paint()..color = Colors.white.withOpacity(0.16));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.points != points;
}

/// Jonli penya qatori
class PenyaRow extends StatelessWidget {
  const PenyaRow({super.key, required this.total, required this.perDay});
  final double total;
  final int perDay;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: t.tRed,
        borderRadius: BorderRadius.circular(FinnTokens.rLg),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: t.red, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('dash.penyaLive'),
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 11.5, color: t.onRed)),
                const SizedBox(height: 3),
                Text(_fmt(total),
                    style: TextStyle(
                        fontFamily: 'InterTight',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.99,
                        color: t.red)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('+${_fmt(perDay)}',
                  style: TextStyle(
                      fontFamily: 'InterTight',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.onRed)),
              const SizedBox(height: 2),
              Text(tr('dash.somPerDay'),
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      color: t.onRed.withOpacity(0.75))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pul oqimi kartasi — ikkita chiziq
class CashFlowCard extends StatelessWidget {
  const CashFlowCard({
    super.key,
    required this.profit,
    required this.growth,
    required this.income,
    required this.expense,
    required this.points,
  });

  final int profit, growth, income, expense;
  final List<double> points;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(FinnTokens.cardPad),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rXl),
        border: Border.all(color: t.line, width: 1),
        boxShadow: t.sh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tr('dash.netProfitMonth'),
                        style: FinnText.label(t.ink3)),
                    const SizedBox(height: 9),
                    Text('+${_fmt(profit)}',
                        style: FinnText.bigValue(t.onGrn)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.tGrn,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('+$growth%', style: FinnText.pill(t.onGrn)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 92,
            width: double.infinity,
            child: CustomPaint(
              painter: _FlowPainter(
                points: points,
                income: t.green,
                expense: t.red,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legend(t.green, '${tr('dash.income')} ${_fmt(income)}', t.ink2),
              const SizedBox(width: 16),
              _legend(t.red, '${tr('dash.expense')} ${_fmt(expense)}', t.ink2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String s, Color textColor) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(s,
              style: TextStyle(
                  fontFamily: 'Inter', fontSize: 12, color: textColor)),
        ],
      );
}

class _FlowPainter extends CustomPainter {
  _FlowPainter({
    required this.points,
    required this.income,
    required this.expense,
  });

  final List<double> points;
  final Color income, expense;

  Path _line(Size size, List<double> pts, double offset) {
    final p = Path();
    final step = size.width / (pts.length - 1);
    for (var i = 0; i < pts.length; i++) {
      final x = i * step;
      final y =
          size.height - (pts[i].clamp(0, 1) * 0.7 + offset) * size.height;
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final inPath = _line(size, points, 0.25);
    final outPath = _line(
        size, points.map((v) => (v * 0.72).clamp(0.0, 1.0)).toList(), 0.10);

    final fill = Path.from(inPath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [income.withOpacity(0.26), income.withOpacity(0)],
        ).createShader(Offset.zero & size),
    );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(inPath, stroke..color = income);
    canvas.drawPath(outPath, stroke..color = expense);
  }

  @override
  bool shouldRepaint(covariant _FlowPainter old) => old.points != points;
}

/// Risk halqasi + umumiy qarz — ikki ustun
class StatusRow extends StatelessWidget {
  const StatusRow({
    super.key,
    required this.risk,
    required this.debt,
    required this.overdue,
  });

  final int risk, debt, overdue;

  Color _riskColor(FinnTokens t) {
    if (risk >= 66) return t.red;
    if (risk >= 33) return t.amber;
    return t.green;
  }

  String get _riskLabel {
    if (risk >= 66) return tr('dash.riskHigh');
    if (risk >= 33) return tr('dash.riskMid');
    return tr('dash.riskLow');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final rc = _riskColor(t);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(FinnTokens.cardPad),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(FinnTokens.rXl),
                border: Border.all(color: t.line, width: 1),
                boxShadow: t.sh,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: CustomPaint(
                        painter: RingPainter(
                          progress: risk / 100,
                          color: rc,
                          track: t.key,
                          stroke: 8,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$risk',
                                  style: TextStyle(
                                      fontFamily: 'InterTight',
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -1.17,
                                      color: rc)),
                              Text(tr('dash.score'),
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      color: t.ink3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(tr('dash.riskLevel'), style: FinnText.label(t.ink3)),
                  const SizedBox(height: 5),
                  Text(_riskLabel,
                      style: TextStyle(
                          fontFamily: 'InterTight',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.51,
                          color: rc)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(FinnTokens.cardPad),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(FinnTokens.rXl),
                border: Border.all(color: t.line, width: 1),
                boxShadow: t.sh,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: t.tRed,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(Icons.account_balance_rounded,
                        size: 17, color: t.onRed),
                  ),
                  const SizedBox(height: 14),
                  Text(tr('dash.totalDebt').toUpperCase(), style: FinnText.label(t.ink3)),
                  const SizedBox(height: 8),
                  Text(_fmt(debt),
                      style: TextStyle(
                          fontFamily: 'InterTight',
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.95,
                          color: t.red)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 6,
                      color: t.key,
                      child: FractionallySizedBox(
                        widthFactor: 1,
                        child: Container(color: t.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("$overdue ${tr('dash.overduePayments')}",
                      style: TextStyle(
                          fontFamily: 'Inter', fontSize: 12, color: t.ink3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// To'q AI kartasi — ODDIY QATOR, hech narsaning ustida emas
class AiCard extends StatelessWidget {
  const AiCard({
    super.key,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title, body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: FinnTokens.darkSurface(isDark),
          borderRadius: BorderRadius.circular(FinnTokens.rXl),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 12),
              blurRadius: 32,
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.24),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome,
                    size: 16, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 8),
                Text(tr('dash.todayRecommendation'),
                    style: FinnText.label(Colors.white.withOpacity(0.55))),
              ],
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                    fontFamily: 'InterTight',
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.57,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(body,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    height: 1.58,
                    color: Colors.white.withOpacity(0.64))),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr('common.review'),
                      style: const TextStyle(
                          fontFamily: 'InterTight',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0A0F1E))),
                  const SizedBox(width: 7),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 14, color: Color(0xFF0A0F1E)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tez kirish — 4 ta yumaloq tugma
class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.items});
  final List<QuickAction> items;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: items
          .map((a) => Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: a.onTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: t.card,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: t.line, width: 1),
                          boxShadow: t.sh,
                        ),
                        child: Icon(a.icon, size: 19, color: a.on(t)),
                      ),
                      const SizedBox(height: 8),
                      Text(a.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: t.ink2)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}
