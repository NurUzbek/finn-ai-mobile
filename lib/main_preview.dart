import 'package:flutter/material.dart';
import 'theme/finn_tokens.dart';
import 'widgets/finn_screen.dart';
import 'screens/dashboard_screen.dart';

// finn.uz/preview — real layoutni brauzerda ko'rish uchun (mock ma'lumot).
void main() => runApp(const _PreviewApp());

DashboardData _mock(FinnTokens t) => DashboardData(
      balance: 511958000,
      orgCount: 5,
      cleanCount: 3,
      lateCount: 4,
      penyaTotal: 702333,
      penyaPerDay: 9333,
      deadlines: [
        DeadlineData(days: 6, title: "Foyda solig'i", date: '11.08', progress: 0.93, color: t.red),
        DeadlineData(days: 12, title: 'QQS', date: '15.08', progress: 0.66, color: t.amber),
        DeadlineData(days: 28, title: 'Aylanma soliq', date: '20.08', progress: 0.35, color: t.blue),
        DeadlineData(days: 54, title: 'INPS hisobot', date: '15.09', progress: 0.15, color: t.green),
      ],
      profit: 277418000,
      growth: 54,
      income: 511958000,
      expense: 234540000,
      flowPoints: const [0.30, 0.44, 0.40, 0.60, 0.55, 0.70, 0.76],
      riskScore: 22,
      debtTotal: 21200000,
      overdueCount: 4,
      aiTitle: "Kechikkan to'lovni yoping",
      aiBody:
          "Kuniga 9 333 so'm — penya shu qarzdan o'sib bormoqda. Yopsangiz kunlik o'sish to'xtaydi.",
      quickActions: [
        QuickAction(Icons.description_outlined, 'Hujjatlar', (t) => t.tBlu, (t) => t.blue),
        QuickAction(Icons.receipt_long_outlined, 'Didox', (t) => t.tPur, (t) => t.purple),
        QuickAction(Icons.currency_exchange_rounded, 'Valyuta', (t) => t.tTea, (t) => t.teal),
        QuickAction(Icons.handshake_outlined, 'Kontragent', (t) => t.tAmb, (t) => t.amber),
      ],
    );

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();
  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  // URL fragment '#dark' bo'lsa tungi rejimda ochiladi (headless skrinshot uchun).
  bool _dark = Uri.base.fragment.contains('dark');

  ThemeData _theme(Brightness b) => ThemeData(
        useMaterial3: true,
        brightness: b,
        scaffoldBackgroundColor:
            b == Brightness.dark ? FinnTokens.dark.bg : FinnTokens.light.bg,
        fontFamily: 'Inter',
        extensions: [b == Brightness.dark ? FinnTokens.dark : FinnTokens.light],
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      // Desktop brauzerda ham telefondek ko'rinishi uchun — 390×844 ramka,
      // markazda. MediaQuery ham telefon o'lchamiga majburlanadi.
      home: Container(
        color: _dark ? const Color(0xFF05070C) : const Color(0xFFDFE5EF),
        alignment: Alignment.center,
        child: Container(
          width: 390,
          height: 844,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 18)),
            ],
          ),
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              devicePixelRatio: 3,
              padding: EdgeInsets.only(top: 44, bottom: 12),
              viewPadding: EdgeInsets.only(top: 44, bottom: 12),
            ),
            child: Builder(
              builder: (context) => Stack(
                children: [
                  DashboardScreen(
                    data: _mock(context.tokens),
                    navIndex: 0,
                    onNavChanged: (_) {},
                  ),
                  // AI konsultant FAB (nav ustida, o'ngda) — dizayn: .fabai
                  Positioned(
                    right: 16,
                    bottom: 128,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: FinnTokens.brand,
                        borderRadius: BorderRadius.circular(19),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF1745C9).withOpacity(.42),
                              blurRadius: 20,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 50,
                    child: GestureDetector(
                      onTap: () => setState(() => _dark = !_dark),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.tokens.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.tokens.line),
                        ),
                        child: Icon(_dark ? Icons.light_mode : Icons.dark_mode,
                            size: 18, color: context.tokens.ink2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
