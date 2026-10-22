import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/i18n.dart';

/// Xavfli muhit aniqlanganda ko'rsatiladigan bloklovchi ekran.
/// Barcha marshrutlar ustidan chiqadi — orqaga qaytib bo'lmaydi.
class ThreatScreen extends StatelessWidget {
  final String type;
  const ThreatScreen({super.key, required this.type});

  static const _title = {
    'uz': 'Xavfsiz bo\'lmagan muhit',
    'uzc': 'Хавфсиз бўлмаган муҳит',
    'ru': 'Небезопасная среда',
    'en': 'Unsafe environment',
  };

  static const _body = {
    'uz': 'Moliyaviy ma\'lumotlaringizni himoya qilish uchun FINN AI bu qurilmada ishlamaydi. '
        'Sessiya yopildi.',
    'uzc': 'Молиявий маълумотларингизни ҳимоя қилиш учун FINN AI бу қурилмада ишламайди. '
        'Сессия ёпилди.',
    'ru': 'Чтобы защитить ваши финансовые данные, FINN AI не работает на этом устройстве. '
        'Сеанс завершён.',
    'en': 'To protect your financial data, FINN AI does not run on this device. '
        'Your session has been closed.',
  };

  static const _reason = {
    'root': {
      'uz': 'Qurilmada root / jailbreak aniqlandi',
      'uzc': 'Қурилмада root / jailbreak аниқланди',
      'ru': 'Обнаружен root / jailbreak',
      'en': 'Root / jailbreak detected',
    },
    'hook': {
      'uz': 'Dinamik tahlil vositasi (hook) aniqlandi',
      'uzc': 'Динамик таҳлил воситаси (hook) аниқланди',
      'ru': 'Обнаружен инструмент динамического анализа (hook)',
      'en': 'Dynamic analysis tool (hook) detected',
    },
    'integrity': {
      'uz': 'Ilova kodi yoki imzosi o\'zgartirilgan',
      'uzc': 'Илова коди ёки имзоси ўзгартирилган',
      'ru': 'Код или подпись приложения изменены',
      'en': 'App code or signature has been modified',
    },
    'emulator': {
      'uz': 'Ilova emulyatorda ishga tushirilgan',
      'uzc': 'Илова эмуляторда ишга туширилган',
      'ru': 'Приложение запущено в эмуляторе',
      'en': 'App is running in an emulator',
    },
    'debug': {
      'uz': 'Ilovaga debugger ulangan',
      'uzc': 'Иловага debugger уланган',
      'ru': 'К приложению подключён отладчик',
      'en': 'A debugger is attached to the app',
    },
  };

  static const _exit = {'uz': 'Chiqish', 'uzc': 'Чиқиш', 'ru': 'Выйти', 'en': 'Exit'};

  @override
  Widget build(BuildContext context) {
    final l = I18n.i.lang;
    String pick(Map<String, String> m) => m[l] ?? m['uz']!;
    final reason = _reason[type];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF070A12),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0x26E8394E),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x66E8394E)),
                  ),
                  child: const Icon(Icons.gpp_bad_rounded, size: 46, color: Color(0xFFE8394E)),
                ),
                const SizedBox(height: 28),
                Text(
                  pick(_title),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFF0F3F9), fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  pick(_body),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF8A94A8), fontSize: 15, height: 1.5),
                ),
                if (reason != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1520),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E2636)),
                    ),
                    child: Text(
                      pick(reason),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFE8394E), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2636),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => SystemNavigator.pop(),
                    child: Text(pick(_exit), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
