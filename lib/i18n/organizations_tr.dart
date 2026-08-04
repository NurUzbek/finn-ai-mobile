// organizations ekrani tarjimalari.
// Format: 'kalit': {'uz','uzc','ru','en'}.
// Eslatma: firma nomlari, STIR raqamlari, pul, rahbar/bank qiymatlari — dinamik, tarjima qilinmaydi.
const Map<String, Map<String, String>> tr = {
  // ── Sarlavha ──
  'org.title': {'uz': 'Tashkilotlarim', 'uzc': 'Ташкилотларим', 'ru': 'Мои организации', 'en': 'My organizations'},
  // Subtitle: "$n ta firma · $m tasi toza" — sonlar Dart'da, so'zlar shu yerda.
  'org.firmsWord': {'uz': 'ta firma', 'uzc': 'та фирма', 'ru': 'фирм', 'en': 'firms'},
  'org.cleanWord': {'uz': 'tasi toza', 'uzc': 'таси тоза', 'ru': 'чистых', 'en': 'clean'},

  // ── Filter chiplari ──
  'org.debtor': {'uz': 'Qarzdor', 'uzc': 'Қарздор', 'ru': 'Должник', 'en': 'Debtor'},
  'org.clean': {'uz': 'Toza', 'uzc': 'Тоза', 'ru': 'Чистая', 'en': 'Clean'},

  // ── Bo'sh holatlar ──
  'org.empty': {'uz': 'Hozircha tashkilot yo\'q', 'uzc': 'Ҳозирча ташкилот йўқ', 'ru': 'Пока нет организаций', 'en': 'No organizations yet'},
  'org.noCleanFound': {'uz': 'Toza firma topilmadi', 'uzc': 'Тоза фирма топилмади', 'ru': 'Чистых фирм не найдено', 'en': 'No clean firms found'},
  'org.noDebtor': {'uz': 'Qarzdor firma yo\'q', 'uzc': 'Қарздор фирма йўқ', 'ru': 'Нет должников', 'en': 'No debtor firms'},

  // ── Karta ──
  'org.stir': {'uz': 'STIR', 'uzc': 'СТИР', 'ru': 'ИНН', 'en': 'TIN'},
  'org.penalty': {'uz': 'penya', 'uzc': 'пеня', 'ru': 'пеня', 'en': 'penalty'},

  // ── Akkordeon qatorlari ──
  'org.director': {'uz': 'Rahbar', 'uzc': 'Раҳбар', 'ru': 'Руководитель', 'en': 'Director'},
  'org.account': {'uz': 'Hisob raqam', 'uzc': 'Ҳисоб рақам', 'ru': 'Расчётный счёт', 'en': 'Account'},
  'org.bank': {'uz': 'Bank', 'uzc': 'Банк', 'ru': 'Банк', 'en': 'Bank'},
  'org.address': {'uz': 'Manzil', 'uzc': 'Манзил', 'ru': 'Адрес', 'en': 'Address'},
  'org.noData': {'uz': 'Ma\'lumot yo\'q', 'uzc': 'Маълумот йўқ', 'ru': 'Нет данных', 'en': 'No data'},

  // ── Snackbar ──
  'org.comingSoon': {'uz': 'Tez orada', 'uzc': 'Тез орада', 'ru': 'Скоро', 'en': 'Coming soon'},
};
