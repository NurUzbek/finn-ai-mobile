import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/api.dart';
import 'services/idle_guard.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const FinnApp());
}

/// FINN AI brend ranglari (veb bilan bir xil)
class C {
  static const navy = Color(0xFF0A2540);
  static const blue = Color(0xFF1A56DB);
  static const sky = Color(0xFF3B82F6);
  static const cyan = Color(0xFF22D3EE);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const violet = Color(0xFF8B5CF6);
  static const bgDark = Color(0xFF050D1A);
  static const cardDark = Color(0xFF0F1B2E);
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

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: C.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: C.blue,
        secondary: C.cyan,
        surface: C.cardDark,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: C.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    return MaterialApp(
      navigatorKey: navKey,
      title: 'FINN AI',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: _loggedIn == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : IdleGuard(
              timeout: const Duration(minutes: 3),
              onTimeout: _forceLogout,
              child: _loggedIn! ? const HomeShell() : const LoginScreen(),
            ),
    );
  }
}
