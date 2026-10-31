import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_bead_nav.dart';
import '../widgets/gov_sources.dart';
import '../services/i18n.dart';

/// Ekran karkasi.
///
/// Pastdagi bo'sh joy muammosining yechimi shu faylda.
/// Uchta qoida buzilmasligi kerak:
///   1. Skroll ichidagi Column da mainAxisSize: MainAxisSize.min
///   2. Skroll ichida Expanded / Spacer ISHLATILMAYDI
///   3. GridView bo'lsa: shrinkWrap: true + NeverScrollableScrollPhysics
/// Pastki nav elementlari — TZ mobil modullariga MOS (5 modul + Profil):
/// Asosiy · Mening tashkilotlarim · Monitoring · Ma'lumotlar · Bildirishnomalar · Profil.
List<FinnNavItem> finnNavItems() => [
      FinnNavItem(Icons.dashboard_rounded, tr('nav.home')),        // Asosiy
      FinnNavItem(Icons.apartment_rounded, tr('nav.orgs')),        // Mening tashkilotlarim
      FinnNavItem(Icons.swap_vert_rounded, tr('nav.monitoring')),  // Monitoring
      FinnNavItem(Icons.assessment_outlined, tr('nav.data')),      // Ma'lumotlar
      FinnNavItem(Icons.notifications_rounded, tr('nav.notif')),   // Bildirishnomalar
      FinnNavItem(Icons.person_rounded, tr('nav.profile')),        // Profil
    ];

class FinnScreen extends StatelessWidget {
  const FinnScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.leading,
    this.actions,
    this.showNav = true,
    this.reserveNav = false,
    this.navIndex = 0,
    this.onNavChanged,
    this.govSources = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? leading;
  final List<Widget>? actions;

  /// push va profil ichki ekranlarida false
  final bool showNav;

  /// Nav'ni bu ekran O'ZI chizmaydi (HomeShell yagona nav chizadi), lekin
  /// pastdagi bo'sh joy (nav balandligi) SAQLANADI — kontent nav ostida qolmasin.
  final bool reserveNav;
  final int navIndex;
  final ValueChanged<int>? onNavChanged;

  /// Davlat ma'lumoti ko'rsatiladigan ekran — oxirida rasmiy manbalar va
  /// "davlat organi emas" yozuvi chiqadi (Google Play Misleading Claims).
  final bool govSources;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(
                  title: title,
                  subtitle: subtitle,
                  leading: leading,
                  actions: actions,
                ),
                // Faqat shu Expanded to'g'ri: u Scaffold ichida,
                // skroll ichida emas.
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: FinnTokens.screenPad,
                      right: FinnTokens.screenPad,
                      bottom: (showNav || reserveNav)
                          ? FinnTokens.scrollBottom
                          : 28,
                    ),
                    child: Column(
                      // ── MUHIM: busiz kontent ostida bo'sh joy qoladi ──
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...children,
                        if (govSources) const GovSourcesFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showNav)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FinnBeadNav(
                index: navIndex,
                onChanged: onNavChanged ?? (_) {},
                items: finnNavItems(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          FinnTokens.screenPad, 18, FinnTokens.screenPad, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: FinnText.screenTitle(t.ink)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: FinnText.screenSub(t.ink3)),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Namuna: muddat kartalari 2×2 to'rda
//  Bu ham bo'sh joy chiqadigan tipik joy.
// ═══════════════════════════════════════════════════════════

class DeadlineGrid extends StatelessWidget {
  const DeadlineGrid({super.key, required this.items});

  final List<DeadlineData> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      // ── MUHIM: ikkalasi ham bo'lishi shart ──
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: FinnTokens.gapGrid,
      crossAxisSpacing: FinnTokens.gapGrid,
      childAspectRatio: 2.1, // HTML dagi kartaga mos nisbat
      padding: EdgeInsets.zero,
      children: items.map((d) => DeadlineCard(data: d)).toList(),
    );
  }
}

class DeadlineData {
  const DeadlineData({
    required this.days,
    required this.title,
    required this.date,
    required this.progress, // 0..1
    required this.color,
  });

  final int days;
  final String title;
  final String date;
  final double progress;
  final Color color;
}

class DeadlineCard extends StatelessWidget {
  const DeadlineCard({super.key, required this.data});

  final DeadlineData data;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rLg),
        border: Border.all(color: t.line, width: 1),
        boxShadow: t.sh,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CustomPaint(
              painter: RingPainter(
                progress: data.progress,
                color: data.color,
                track: t.key,
                stroke: 4,
              ),
              child: Center(
                child: Text(
                  '${data.days}',
                  style: TextStyle(
                    fontFamily: 'InterTight',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.39,
                    color: t.ink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.20,
                    height: 1.25,
                    color: t.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 10.5, color: t.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Halqa progressi. Boshlanish −90° (yuqoridan), uchi yumaloq.
class RingPainter extends CustomPainter {
  RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    this.stroke = 4,
  });

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect, 0, 6.2831853, false, bg);
    canvas.drawArc(rect, -1.5707963, 6.2831853 * progress.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(covariant RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
