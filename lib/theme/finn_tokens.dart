import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

/// FINN dizayn tokenlari.
///
/// HTML manbadagi `:root`, `[data-theme="light"]` va `[data-theme="dark"]`
/// bloklaridan 1:1 ko'chirilgan. Kod ichida ochiq rang yozilmaydi —
/// hamma joyda `context.tokens.<nom>` ishlatiladi.
@immutable
class FinnTokens extends ThemeExtension<FinnTokens> {
  // brend
  final Color blue, blue2, cyan;
  // holat
  final Color red, green, amber, purple, teal;
  // sirt
  final Color bg, card, page, key;
  // matn
  final Color ink, ink2, ink3, ink4;
  // chiziq
  final Color line, line2, glass;
  // tint (fon)
  final Color tRed, tAmb, tGrn, tBlu, tPur, tTea;
  // tint ustidagi matn
  final Color onRed, onAmb, onGrn, onPur, onTea;
  // soya
  final List<BoxShadow> sh;

  const FinnTokens({
    required this.blue,
    required this.blue2,
    required this.cyan,
    required this.red,
    required this.green,
    required this.amber,
    required this.purple,
    required this.teal,
    required this.bg,
    required this.card,
    required this.page,
    required this.key,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.line,
    required this.line2,
    required this.glass,
    required this.tRed,
    required this.tAmb,
    required this.tGrn,
    required this.tBlu,
    required this.tPur,
    required this.tTea,
    required this.onRed,
    required this.onAmb,
    required this.onGrn,
    required this.onPur,
    required this.onTea,
    required this.sh,
  });

  // ── radius ──
  static const double rXl = 26;
  static const double rLg = 20;
  static const double rMd = 15;
  static const double rSm = 10;

  // ── oraliqlar ──
  static const double screenPad = 20;
  static const double scrollBottom = 110; // nav 64 + 20 + zaxira 26
  static const double cardPad = 18;
  static const double gapList = 9;
  static const double gapGrid = 10;

  // ── animatsiya egri chiziqlari ──
  /// bosish, sakrash
  static const Curve spring = Cubic(0.32, 1.5, 0.6, 1.0);
  /// siljish, ochilish
  static const Curve ease = Cubic(0.22, 0.61, 0.36, 1.0);
  /// bead navigatsiya
  static const Curve bead = Cubic(0.34, 1.42, 0.5, 1.0);
  static const Duration beadDur = Duration(milliseconds: 620);

  // ── brend gradienti ──
  static const LinearGradient brand = LinearGradient(
    begin: Alignment(-0.56, -0.83), // CSS 146deg
    end: Alignment(0.56, 0.83),
    colors: [Color(0xFF1745C9), Color(0xFF2A6DF5), Color(0xFF25C4E8)],
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient darkSurface(bool isDark) => LinearGradient(
        begin: const Alignment(-0.42, -0.91), // CSS 155deg
        end: const Alignment(0.42, 0.91),
        colors: isDark
            ? const [Color(0xFF1C2742), Color(0xFF151E33), Color(0xFF1E2B4A)]
            : const [Color(0xFF101728), Color(0xFF0A0F1E), Color(0xFF121B33)],
        stops: const [0.0, 0.6, 1.0],
      );

  // ═══════════ YORUG' ═══════════
  static const light = FinnTokens(
    blue: Color(0xFF246BFD),
    blue2: Color(0xFF1745C9),
    cyan: Color(0xFF25C4E8),
    red: Color(0xFFE8394E),
    green: Color(0xFF12B981),
    amber: Color(0xFFE8912A),
    purple: Color(0xFF8B5CF6),
    teal: Color(0xFF14B8C6),
    bg: Color(0xFFF7F9FC),
    card: Color(0xFFFFFFFF),
    page: Color(0xFFE9EDF4),
    key: Color(0x0A0A1027), // rgba(10,16,39,.04)
    ink: Color(0xFF080D1C),
    ink2: Color(0xFF565F73),
    ink3: Color(0xFF98A0B2),
    ink4: Color(0xFFC7CCD8),
    line: Color(0x120A1027), // rgba(10,16,39,.07)
    line2: Color(0x0B0A1027), // rgba(10,16,39,.045)
    glass: Color(0xB8FFFFFF), // rgba(255,255,255,.72)
    tRed: Color(0x12E8394E),
    tAmb: Color(0x1AE8912A),
    tGrn: Color(0x1A12B981),
    tBlu: Color(0x14246BFD),
    tPur: Color(0x1A8B5CF6),
    tTea: Color(0x1A14B8C6),
    onRed: Color(0xFFB3222F),
    onAmb: Color(0xFFB0740F),
    onGrn: Color(0xFF0E9067),
    onPur: Color(0xFF6D28D9),
    onTea: Color(0xFF0B7F8A),
    sh: [
      BoxShadow(
        offset: Offset(0, 1),
        blurRadius: 2,
        color: Color(0x080A1027), // rgba(10,16,39,.03)
      ),
      BoxShadow(
        offset: Offset(0, 8),
        blurRadius: 24,
        color: Color(0x0B0A1027), // rgba(10,16,39,.045)
      ),
    ],
  );

  // ═══════════ TUNGI ═══════════
  static const dark = FinnTokens(
    blue: Color(0xFF246BFD),
    blue2: Color(0xFF1745C9),
    cyan: Color(0xFF25C4E8),
    red: Color(0xFFE8394E),
    green: Color(0xFF12B981),
    amber: Color(0xFFE8912A),
    purple: Color(0xFF8B5CF6),
    teal: Color(0xFF14B8C6),
    bg: Color(0xFF070A12),
    card: Color(0xFF0F1520),
    page: Color(0xFF0A0E17),
    key: Color(0x0DFFFFFF), // rgba(255,255,255,.05)
    ink: Color(0xFFF0F3F9),
    ink2: Color(0xFF98A2B8),
    ink3: Color(0xFF646F86),
    ink4: Color(0xFF3A4459),
    line: Color(0x14FFFFFF), // rgba(255,255,255,.08)
    line2: Color(0x0DFFFFFF), // rgba(255,255,255,.05)
    glass: Color(0xB3141B2A), // rgba(20,27,42,.70)
    tRed: Color(0x21E8394E),
    tAmb: Color(0x24E8912A),
    tGrn: Color(0x2412B981),
    tBlu: Color(0x24246BFD),
    tPur: Color(0x298B5CF6),
    tTea: Color(0x2914B8C6),
    onRed: Color(0xFFFF7A87),
    onAmb: Color(0xFFF0A94E),
    onGrn: Color(0xFF3DD9A4),
    onPur: Color(0xFFB694FF),
    onTea: Color(0xFF3FD3DE),
    sh: [
      BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x4D000000)),
      BoxShadow(offset: Offset(0, 12), blurRadius: 30, color: Color(0x52000000)),
    ],
  );

  @override
  FinnTokens copyWith({
    Color? blue,
    Color? blue2,
    Color? cyan,
    Color? red,
    Color? green,
    Color? amber,
    Color? purple,
    Color? teal,
    Color? bg,
    Color? card,
    Color? page,
    Color? key,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? ink4,
    Color? line,
    Color? line2,
    Color? glass,
    Color? tRed,
    Color? tAmb,
    Color? tGrn,
    Color? tBlu,
    Color? tPur,
    Color? tTea,
    Color? onRed,
    Color? onAmb,
    Color? onGrn,
    Color? onPur,
    Color? onTea,
    List<BoxShadow>? sh,
  }) {
    return FinnTokens(
      blue: blue ?? this.blue,
      blue2: blue2 ?? this.blue2,
      cyan: cyan ?? this.cyan,
      red: red ?? this.red,
      green: green ?? this.green,
      amber: amber ?? this.amber,
      purple: purple ?? this.purple,
      teal: teal ?? this.teal,
      bg: bg ?? this.bg,
      card: card ?? this.card,
      page: page ?? this.page,
      key: key ?? this.key,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      ink4: ink4 ?? this.ink4,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      glass: glass ?? this.glass,
      tRed: tRed ?? this.tRed,
      tAmb: tAmb ?? this.tAmb,
      tGrn: tGrn ?? this.tGrn,
      tBlu: tBlu ?? this.tBlu,
      tPur: tPur ?? this.tPur,
      tTea: tTea ?? this.tTea,
      onRed: onRed ?? this.onRed,
      onAmb: onAmb ?? this.onAmb,
      onGrn: onGrn ?? this.onGrn,
      onPur: onPur ?? this.onPur,
      onTea: onTea ?? this.onTea,
      sh: sh ?? this.sh,
    );
  }

  @override
  FinnTokens lerp(ThemeExtension<FinnTokens>? other, double t) {
    if (other is! FinnTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return FinnTokens(
      blue: c(blue, other.blue),
      blue2: c(blue2, other.blue2),
      cyan: c(cyan, other.cyan),
      red: c(red, other.red),
      green: c(green, other.green),
      amber: c(amber, other.amber),
      purple: c(purple, other.purple),
      teal: c(teal, other.teal),
      bg: c(bg, other.bg),
      card: c(card, other.card),
      page: c(page, other.page),
      key: c(key, other.key),
      ink: c(ink, other.ink),
      ink2: c(ink2, other.ink2),
      ink3: c(ink3, other.ink3),
      ink4: c(ink4, other.ink4),
      line: c(line, other.line),
      line2: c(line2, other.line2),
      glass: c(glass, other.glass),
      tRed: c(tRed, other.tRed),
      tAmb: c(tAmb, other.tAmb),
      tGrn: c(tGrn, other.tGrn),
      tBlu: c(tBlu, other.tBlu),
      tPur: c(tPur, other.tPur),
      tTea: c(tTea, other.tTea),
      onRed: c(onRed, other.onRed),
      onAmb: c(onAmb, other.onAmb),
      onGrn: c(onGrn, other.onGrn),
      onPur: c(onPur, other.onPur),
      onTea: c(onTea, other.onTea),
      sh: BoxShadow.lerpList(sh, other.sh, t) ?? sh,
    );
  }
}

extension FinnTokensX on BuildContext {
  FinnTokens get tokens =>
      Theme.of(this).extension<FinnTokens>() ?? FinnTokens.light;
}

/// Matn uslublari katalogi.
///
/// letterSpacing qiymatlari CSS `em` dan o'girilgan: em × fontSize.
/// Masalan 23px / −0.038em → −0.87. Bu qiymatlarni O'ZGARTIRMANG.
class FinnText {
  static const _tight = 'InterTight';
  static const _inter = 'Inter';
  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle screenTitle(Color c) => TextStyle(
      fontFamily: _tight,
      fontSize: 23,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.87,
      height: 1.1,
      color: c);

  static TextStyle screenSub(Color c) => TextStyle(
      fontFamily: _inter, fontSize: 12.5, height: 1.4, color: c);

  static TextStyle heroValue(Color c) => TextStyle(
      fontFamily: _tight,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.62,
      height: 1.0,
      fontFeatures: _tabular,
      color: c);

  static TextStyle bigValue(Color c) => TextStyle(
      fontFamily: _tight,
      fontSize: 27,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.22,
      height: 1.0,
      fontFeatures: _tabular,
      color: c);

  static TextStyle cardTitle(Color c) => TextStyle(
      fontFamily: _tight,
      fontSize: 19,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.57,
      height: 1.2,
      color: c);

  static TextStyle rowTitle(Color c) => TextStyle(
      fontFamily: _inter,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.21,
      height: 1.3,
      color: c);

  static TextStyle rowSub(Color c) => TextStyle(
      fontFamily: _inter, fontSize: 11.5, height: 1.4, color: c);

  static TextStyle rowValue(Color c) => TextStyle(
      fontFamily: _tight,
      fontSize: 14.5,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.29,
      height: 1.2,
      fontFeatures: _tabular,
      color: c);

  static TextStyle body(Color c) => TextStyle(
      fontFamily: _inter, fontSize: 14.5, height: 1.6, color: c);

  /// UPPERCASE yoziladi
  static TextStyle eyebrow(Color c) => TextStyle(
      fontFamily: _inter,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.40,
      height: 1.2,
      color: c);

  static TextStyle label(Color c) => TextStyle(
      fontFamily: _inter,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.30,
      height: 1.2,
      color: c);

  static TextStyle pill(Color c) => TextStyle(
      fontFamily: _inter, fontSize: 11.5, fontWeight: FontWeight.w500, color: c);

  static TextStyle chip(Color c) => TextStyle(
      fontFamily: _inter, fontSize: 13, fontWeight: FontWeight.w500, color: c);

  static TextStyle button(Color c) => TextStyle(
      fontFamily: _tight,
      fontSize: 15.5,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.23,
      color: c);

  static TextStyle navLabel(Color c) => TextStyle(
      fontFamily: _tight,
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.11,
      color: c);
}
