// audit ekrani (Audit jurnali) tarjimalari — uz/uzc/ru/en.
// Format: 'kalit': {'uz','uzc','ru','en'}.
const Map<String, Map<String, String>> tr = {
  // ── Sarlavha ──
  'audit.title': {'uz': 'Audit jurnali', 'uzc': 'Аудит журнали', 'ru': 'Журнал аудита', 'en': 'Audit log'},
  'audit.subtitle': {'uz': 'Barcha harakatlar tarixi', 'uzc': 'Барча ҳаракатлар тарихи', 'ru': 'История всех действий', 'en': 'History of all actions'},
  'audit.csvSoon': {'uz': 'CSV eksport tez orada', 'uzc': 'CSV экспорт тез орада', 'ru': 'Экспорт CSV скоро', 'en': 'CSV export coming soon'},

  // ── Chiplar ──
  'audit.chipAll': {'uz': 'Hammasi', 'uzc': 'Ҳаммаси', 'ru': 'Все', 'en': 'All'},
  'audit.chipDoc': {'uz': 'Hujjat', 'uzc': 'Ҳужжат', 'ru': 'Документ', 'en': 'Document'},
  'audit.chipPay': {'uz': "To'lov", 'uzc': 'Тўлов', 'ru': 'Платёж', 'en': 'Payment'},
  'audit.chipSetting': {'uz': 'Sozlama', 'uzc': 'Созлама', 'ru': 'Настройка', 'en': 'Setting'},

  // ── Kun guruhlari ──
  'audit.today': {'uz': 'Bugun', 'uzc': 'Бугун', 'ru': 'Сегодня', 'en': 'Today'},
  'audit.yesterday': {'uz': 'Kecha', 'uzc': 'Кеча', 'ru': 'Вчера', 'en': 'Yesterday'},
  'audit.otherGroup': {'uz': 'Boshqa', 'uzc': 'Бошқа', 'ru': 'Другое', 'en': 'Other'},

  // ── Namuna yozuvlari ──
  'audit.s1Title': {'uz': 'Shartnoma №146 imzolandi', 'uzc': 'Шартнома №146 имзоланди', 'ru': 'Договор №146 подписан', 'en': 'Contract No.146 signed'},
  'audit.s1Sub': {'uz': 'Gulnora Saidova · 00:12', 'uzc': 'Гулнора Саидова · 00:12', 'ru': 'Гульнора Саидова · 00:12', 'en': 'Gulnora Saidova · 00:12'},
  'audit.s2Title': {'uz': "QQS to'lovi amalga oshirildi", 'uzc': 'ҚҚС тўлови амалга оширилди', 'ru': 'Оплата НДС произведена', 'en': 'VAT payment made'},
  'audit.s2Sub': {'uz': "Nuriddin Abdullayev · 09 200 000 so'm · 22:40", 'uzc': 'Нуриддин Абдуллаев · 09 200 000 сўм · 22:40', 'ru': 'Нуриддин Абдуллаев · 09 200 000 сум · 22:40', 'en': 'Nuriddin Abdullayev · 09,200,000 UZS · 22:40'},
  'audit.s3Title': {'uz': 'Jasur Tolipov taklif qilindi', 'uzc': 'Жасур Толипов таклиф қилинди', 'ru': 'Джасур Толипов приглашён', 'en': 'Jasur Tolipov invited'},
  'audit.s3Sub': {'uz': 'Rol: Kuzatuvchi · Nuriddin A. · 18:05', 'uzc': 'Рол: Кузатувчи · Нуриддин А. · 18:05', 'ru': 'Роль: Наблюдатель · Нуриддин А. · 18:05', 'en': 'Role: Viewer · Nuriddin A. · 18:05'},
  'audit.s4Title': {'uz': "Sessiya muddati o'zgartirildi", 'uzc': 'Сессия муддати ўзгартирилди', 'ru': 'Время сессии изменено', 'en': 'Session timeout changed'},
  'audit.s4Sub': {'uz': '15 daqiqa → 3 daqiqa · Nuriddin A.', 'uzc': '15 дақиқа → 3 дақиқа · Нуриддин А.', 'ru': '15 минут → 3 минуты · Нуриддин А.', 'en': '15 min → 3 min · Nuriddin A.'},
  'audit.s5Title': {'uz': 'Yangi qurilmadan kirildi', 'uzc': 'Янги қурилмадан кирилди', 'ru': 'Вход с нового устройства', 'en': 'Signed in from new device'},
  'audit.s5Sub': {'uz': 'iPhone 14 · Samarqand · 09:30', 'uzc': 'iPhone 14 · Самарқанд · 09:30', 'ru': 'iPhone 14 · Самарканд · 09:30', 'en': 'iPhone 14 · Samarkand · 09:30'},

  // ── Izoh (footer) ──
  'audit.footer': {'uz': "Jurnal 24 oy saqlanadi va o'chirilmaydi. CSV shaklida yuklab olish mumkin.", 'uzc': 'Журнал 24 ой сақланади ва ўчирилмайди. CSV шаклида юклаб олиш мумкин.', 'ru': 'Журнал хранится 24 месяца и не удаляется. Можно скачать в формате CSV.', 'en': 'The log is kept for 24 months and cannot be deleted. It can be downloaded as CSV.'},
};
