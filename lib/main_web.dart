import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

/// finn.uz/preview uchun — REAL ilovani (FinnApp) telefon o'lchamli
/// ramkada, markazda ko'rsatadi. Real APK bunga bog'liq emas (main.dart
/// ishlatiladi). Shunda desktop brauzerda ham telefondek ko'rinadi va
/// hamma tugma/nav/API ishlaydi.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const _WebPreview());
}

class _WebPreview extends StatelessWidget {
  const _WebPreview();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFF0B0E16),
        alignment: Alignment.center,
        child: Container(
          width: 430,
          height: 924,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 50,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: const FinnApp(),
        ),
      ),
    );
  }
}
