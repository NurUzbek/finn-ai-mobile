import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'i18n.dart';

/// Lokal bildirishnomalar — soliq muddati/penya eslatmalari.
/// Bildirishnoma matni QURILMADA yaratiladi, shuning uchun ilovaning
/// joriy tilida (uz/uzc/ru/en) chiqadi — `tr()` orqali.
class Notifs {
  Notifs._();
  static final Notifs i = Notifs._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  /// Push'dan kelgan tayyor sarlavha+matnni darhol ko'rsatadi (FCM old plan).
  Future<void> showRaw(String title, String body) async {
    await init();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
      title, body, _details,
    );
  }

  /// Bildirishnoma ruxsatini so'raydi (Android 13+ / iOS).
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return granted ?? true;
  }

  NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails(
          'finn_deadlines',
          tr('notif.push.channel'),
          channelDescription: tr('notif.push.channelDesc'),
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  String _bodyFor(String title, int days) {
    final b = days < 0
        ? tr('notif.push.overdue').replaceFirst('{n}', (-days).toString())
        : days == 0
            ? tr('notif.push.today')
            : tr('notif.push.inDays').replaceFirst('{n}', days.toString());
    return '$title — $b';
  }

  /// Deadline ro'yxatini eslatmaga aylantiradi. Har safar yangilanadi.
  /// [items]: {title, days}. Yaqin (<=2 kun) — darhol; uzoq — 2 kun oldin 09:00.
  Future<void> syncDeadlines(List<Map<String, dynamic>> items) async {
    await init();
    await _plugin.cancelAll();
    var id = 100;
    for (final it in items) {
      final title = trReport((it['title'] ?? '').toString());
      final days = ((it['days'] ?? 0) as num).toInt();
      final headline = tr('notif.push.deadlineTitle');
      final body = _bodyFor(title, days);
      if (days <= 2) {
        // Shoshilinch — darhol ko'rsatamiz.
        await _plugin.show(id++, headline, body, _details);
      } else {
        // Muddatdan 2 kun oldin, soat 09:00 ga rejalashtiramiz.
        final remindDay = days - 2;
        final now = tz.TZDateTime.now(tz.local);
        final when = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + remindDay,
          9,
        );
        try {
          await _plugin.zonedSchedule(
            id++,
            headline,
            body,
            when.isAfter(now) ? when : now.add(const Duration(seconds: 5)),
            _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (_) {
          // Rejalash imkoni bo'lmasa — jim o'tkazamiz.
        }
      }
    }
  }
}
