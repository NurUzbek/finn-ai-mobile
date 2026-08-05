import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/api.dart';
import 'services/idle_guard.dart';
import 'services/theme.dart';
import 'services/i18n.dart';
import 'services/sfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/lock.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/pin_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const FinnApp());
}

/// FINN AI brend ranglari + mavzuga bog'liq (dark/light) yordamchi ranglar.
/// Brend akssent ranglari (blue/cyan/green/amber/red/violet) ikkala mavzuda ham o'zgarmaydi.
class C {
  // ── Brend akssentlari (o'zgarmas) ──
  static const navy = Color(0xFF0A2540);
  static const blue = Color(0xFF1A56DB);
  static const sky = Color(0xFF3B82F6);
  static const cyan = Color(0xFF22D3EE);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const violet = Color(0xFF8B5CF6);

  // ── Qorong'i palitra ──
  static const bgDark = Color(0xFF050D1A);
  static const cardDark = Color(0xFF0F1B2E);

  // ── Yorug' palitra ──
  static const bgLight = Color(0xFFF4F7FB);
  static const cardLight = Color(0xFFFFFFFF);
  static const inkLight = Color(0xFF0A1A33);

  // ── Mavzuga bog'liq yordamchilar ──
  static bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

  /// Fon rangi (Scaffold).
  static Color bg(BuildContext c) => isDark(c) ? bgDark : bgLight;

  /// Karta / sirt rangi.
  static Color card(BuildContext c) => isDark(c) ? cardDark : cardLight;

  /// Sirt ustidagi asosiy rang (matn tayanchi): qorong'ida oq, yorug'da to'q ko'k.
  static Color ink(BuildContext c) => isDark(c) ? Colors.white : inkLight;

  /// Asosiy matn rangi.
  static Color text(BuildContext c) => ink(c);

  /// Xira matn / ikonka / ajratuvchi — eski `Colors.white.withValues(alpha: a)` o'rnini bosadi.
  static Color muted(BuildContext c, [double a = .55]) => ink(c).withValues(alpha: a);

  /// Karta chegarasi.
  static Color border(BuildContext c, [double a = .07]) =>
      isDark(c) ? Colors.white.withValues(alpha: a) : inkLight.withValues(alpha: a);

  /// Kirish maydoni / yumshoq to'ldirish foni.
  static Color fill(BuildContext c, [double a = .04]) =>
      isDark(c) ? Colors.white.withValues(alpha: a) : inkLight.withValues(alpha: a);

  // ── Dizayn tizimi (finn-app-screens.html) ──
  /// Brend akssent (dizayn) — yorqinroq ko'k.
  static const brand = Color(0xFF246BFD);
  static const brand2 = Color(0xFF25C4E8);
  /// Asosiy brend gradienti (tugma/karta/nav).
  static const grad = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1745C9), Color(0xFF2A6DF5), Color(0xFF25C4E8)],
  );
  /// Tinted fon — accent rang ustida yumshoq to'ldirish (pill/karta foni).
  static Color tint(BuildContext c, Color base, {double light = .09, double dark = .15}) =>
      base.withValues(alpha: isDark(c) ? dark : light);
  /// Tinted fon ustidagi o'qiladigan matn rangi (mavzuga moslashgan).
  static Color onRed(BuildContext c) => isDark(c) ? const Color(0xFFFF7A87) : const Color(0xFFB3222F);
  static Color onAmb(BuildContext c) => isDark(c) ? const Color(0xFFF0A94E) : const Color(0xFFB0740F);
  static Color onGrn(BuildContext c) => isDark(c) ? const Color(0xFF3DD9A4) : const Color(0xFF0E9067);
  static Color onPur(BuildContext c) => isDark(c) ? const Color(0xFFB694FF) : const Color(0xFF6D28D9);
  static const teal = Color(0xFF14B8C6);
  static Color onTea(BuildContext c) => isDark(c) ? const Color(0xFF3FD3DE) : const Color(0xFF0B7F8A);
  /// Yumshoq soya (tinted, chegara o'rniga).
  static List<BoxShadow> shadow(BuildContext c, {double y = 8, double blur = 24, double a = .045}) => [
        BoxShadow(color: (isDark(c) ? Colors.black : const Color(0xFF0A1027)).withValues(alpha: isDark(c) ? a * 5 : a), blurRadius: blur, offset: Offset(0, y)),
      ];
}

final navKey = GlobalKey<NavigatorState>();
/// HomeShell Scaffold kaliti — ichki ekranlardan drawer'ni ochish uchun.
final homeScaffoldKey = GlobalKey<ScaffoldState>();
/// Asosiy tab indeksini boshqarish — dashboard tugmalari (Soliq/Firmalar/…)
/// pastki tabga o'tishi uchun. HomeShell shu qiymatni kuzatadi.
final homeTab = ValueNotifier<int>(0);

class FinnApp extends StatefulWidget {
  const FinnApp({super.key});
  @override
  State<FinnApp> createState() => _FinnAppState();
}

class _FinnAppState extends State<FinnApp> {
  Widget? _start;

  @override
  void initState() {
    super.initState();
    ThemeState.i.load();
    I18n.i.load();
    Sfx.i.load();
    _decideStart();
  }

  /// Boshlang'ich ekran:
  ///  • Yangi o'rnatish → SMS login (iOS keychain saqlab qolgan token tozalanadi)
  ///  • Avval kirgan + PIN bor → PIN/biometrika unlock
  ///  • Token bor, PIN yo'q → to'g'ridan-to'g'ri HomeShell
  Future<void> _decideStart() async {
    final sp = await SharedPreferences.getInstance();
    final fresh = !(sp.getBool('installed') ?? false);
    if (fresh) {
      await Api.clearToken();
      await Lock.clear();
      await sp.setBool('installed', true);
      if (mounted) setState(() => _start = const LoginScreen());
      return;
    }
    final token = await Api.token;
    if (token == null) {
      if (mounted) setState(() => _start = const LoginScreen());
    } else if (await Lock.hasPin()) {
      if (mounted) setState(() => _start = const PinScreen(mode: 'unlock'));
    } else {
      if (mounted) setState(() => _start = const HomeShell());
    }
  }

  /// TZ: 3 daqiqa harakatsizlikda qulflanadi. PIN bo'lsa — PIN unlock, aks holda SMS.
  Future<void> _forceLogout() async {
    if (await Lock.hasPin()) {
      navKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PinScreen(mode: 'unlock')), (_) => false);
    } else {
      await Api.clearToken();
      navKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen(expired: true)), (_) => false);
    }
  }

  ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = dark
        ? const ColorScheme.dark(
            primary: C.blue,
            secondary: C.cyan,
            surface: C.cardDark,
            onSurface: Colors.white,
          )
        : const ColorScheme.light(
            primary: C.blue,
            secondary: C.cyan,
            surface: C.cardLight,
            onSurface: C.inkLight,
            surfaceTint: Colors.transparent,
          );

    final baseText = GoogleFonts.dmSansTextTheme(
      (dark ? ThemeData.dark() : ThemeData.light()).textTheme,
    ).apply(
      bodyColor: dark ? Colors.white : C.inkLight,
      displayColor: dark ? Colors.white : C.inkLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: dark ? C.bgDark : C.bgLight,
      colorScheme: scheme,
      textTheme: baseText,
      cardTheme: CardThemeData(
        color: dark ? C.cardDark : C.cardLight,
        elevation: dark ? 0 : 1,
        shadowColor: dark ? Colors.transparent : C.inkLight.withValues(alpha: .10),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerColor: dark ? Colors.white.withValues(alpha: .08) : C.inkLight.withValues(alpha: .08),
      iconTheme: IconThemeData(color: dark ? Colors.white : C.inkLight),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.cyan),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? C.cardDark : C.inkLight,
        contentTextStyle: TextStyle(color: dark ? Colors.white : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? Colors.white.withValues(alpha: .04) : C.inkLight.withValues(alpha: .04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeState.i, I18n.i]),
      builder: (context, _) => MaterialApp(
        navigatorKey: navKey,
        title: 'FINN AI',
        debugShowCheckedModeBanner: false,
        theme: _build(Brightness.light),
        darkTheme: _build(Brightness.dark),
        themeMode: ThemeState.i.mode,
        home: _start == null
            ? const Scaffold(body: Center(child: CircularProgressIndicator(color: C.cyan)))
            : IdleGuard(
                timeout: const Duration(minutes: 3),
                onTimeout: _forceLogout,
                child: _start!,
              ),
      ),
    );
  }
}
