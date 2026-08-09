// notifications ekrani tarjimalari.
// Format: 'kalit': {'uz','uzc','ru','en'}.
// Eslatma: bildirishnoma title/body/date API'dan keladi — tarjima qilinmaydi.
const Map<String, Map<String, String>> tr = {
  'notif.title': {'uz': 'Xabarlar', 'uzc': 'Хабарлар', 'ru': 'Сообщения', 'en': 'Notifications'},
  // "$unread ta o'qilmagan" — son Dart'da, so'z bu yerda.
  'notif.unread': {'uz': 'ta o\'qilmagan', 'uzc': 'та ўқилмаган', 'ru': 'непрочитанных', 'en': 'unread'},
  'notif.markAllRead': {'uz': 'Hammasi o\'qildi', 'uzc': 'Ҳаммаси ўқилди', 'ru': 'Прочитать все', 'en': 'Mark all read'},
  'notif.important': {'uz': 'Muhim', 'uzc': 'Муҳим', 'ru': 'Важные', 'en': 'Important'},
  'notif.payment': {'uz': 'To\'lov', 'uzc': 'Тўлов', 'ru': 'Платёж', 'en': 'Payment'},
  'notif.empty': {'uz': 'Bildirishnoma yo\'q', 'uzc': 'Билдиришнома йўқ', 'ru': 'Нет уведомлений', 'en': 'No notifications'},
  'notif.noData': {'uz': 'Ma\'lumot olinmadi', 'uzc': 'Маълумот олинмади', 'ru': 'Данные не получены', 'en': 'No data received'},

  // ── Telefon bildirishnomalari (lokal push — qurilmada, joriy tilda) ──
  'notif.push.channel': {'uz': 'Muddat eslatmalari', 'uzc': 'Муддат эслатмалари', 'ru': 'Напоминания о сроках', 'en': 'Deadline reminders'},
  'notif.push.channelDesc': {'uz': 'Soliq hisobotlari va penya eslatmalari', 'uzc': 'Солиқ ҳисоботлари ва пеня эслатмалари', 'ru': 'Напоминания об отчётах и пене', 'en': 'Tax report and penalty reminders'},
  'notif.push.deadlineTitle': {'uz': 'Yaqin muddat', 'uzc': 'Яқин муддат', 'ru': 'Ближайший срок', 'en': 'Upcoming deadline'},
  'notif.push.inDays': {'uz': '{n} kun qoldi', 'uzc': '{n} кун қолди', 'ru': 'осталось {n} дн.', 'en': '{n} days left'},
  'notif.push.today': {'uz': 'Bugun oxirgi kun', 'uzc': 'Бугун охирги кун', 'ru': 'Сегодня последний день', 'en': 'Due today'},
  'notif.push.overdue': {'uz': '{n} kun kechikdi', 'uzc': '{n} кун кечикди', 'ru': 'просрочено на {n} дн.', 'en': 'overdue by {n} days'},
};
