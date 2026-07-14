import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/api.dart';
import 'services/idle_guard.dart';
import 'services/theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

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
}

final navKey = GlobalKey<NavigatorState>();

class FinnApp extends StatefulWidget {
  const FinnApp({super.key});
  @override
  State<FinnApp> createState() => _FinnAppState();
}

class _FinnAppState extends State<FinnApp> {
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    ThemeState.i.load();
    Api.token.then((t) => setState(() => _loggedIn = t != null));
  }

  /// TZ: 3 daqiqa harakatsizlikda sessiya tugatiladi va qayta autentifikatsiya so'raladi.
  Future<void> _forceLogout() async {
    await Api.clearToken();
    navKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen(expired: true)),
      (_) => false,
    );
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
      animation: ThemeState.i,
      builder: (context, _) => MaterialApp(
        navigatorKey: navKey,
        title: 'FINN AI',
        debugShowCheckedModeBanner: false,
        theme: _build(Brightness.light),
        darkTheme: _build(Brightness.dark),
        themeMode: ThemeState.i.mode,
        home: _loggedIn == null
            ? const Scaffold(body: Center(child: CircularProgressIndicator(color: C.cyan)))
            : IdleGuard(
                timeout: const Duration(minutes: 3),
                onTimeout: _forceLogout,
                child: _loggedIn! ? const HomeShell() : const LoginScreen(),
              ),
      ),
    );
  }
}
