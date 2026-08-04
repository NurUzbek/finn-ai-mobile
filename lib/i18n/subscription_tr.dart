// subscription ekrani tarjimalari — sub.* namespace, 4 til (uz, uzc, ru, en).
// Tarif nomi/tavsifi API'dan keladi — tarjima qilinmaydi.
const Map<String, Map<String, String>> tr = {
  // ── Sarlavha / umumiy ──
  'sub.title': {'uz': 'Tariflar', 'uzc': 'Тарифлар', 'ru': 'Тарифы', 'en': 'Plans'},
  'sub.currentPlan': {'uz': 'Joriy tarif', 'uzc': 'Жорий тариф', 'ru': 'Текущий тариф', 'en': 'Current plan'},
  'sub.current': {'uz': 'Joriy', 'uzc': 'Жорий', 'ru': 'Текущий', 'en': 'Current'},
  'sub.currentMode': {'uz': 'Joriy rejim', 'uzc': 'Жорий режим', 'ru': 'Текущий режим', 'en': 'Current plan'},
  'sub.days': {'uz': 'kun', 'uzc': 'кун', 'ru': 'дн', 'en': 'days'},

  // ── Sikl (oylik/yillik) ──
  'sub.monthly': {'uz': 'Oylik', 'uzc': 'Ойлик', 'ru': 'Ежемесячно', 'en': 'Monthly'},
  'sub.yearly': {'uz': 'Yillik', 'uzc': 'Йиллик', 'ru': 'Ежегодно', 'en': 'Yearly'},
  'sub.somPerMonth': {'uz': 'so\'m/oy', 'uzc': 'сўм/ой', 'ru': 'сум/мес', 'en': 'so\'m/mo'},

  // ── Tugmalar / belgilar ──
  'sub.trial14': {'uz': '14 kun bepul sinash', 'uzc': '14 кун бепул синаш', 'ru': '14 дней бесплатно', 'en': '14-day free trial'},
  'sub.noCard': {'uz': 'Karta talab qilinmaydi', 'uzc': 'Карта талаб қилинмайди', 'ru': 'Карта не требуется', 'en': 'No card required'},
  'sub.popular': {'uz': 'KO\'P TANLANADI', 'uzc': 'КЎП ТАНЛАНАДИ', 'ru': 'ПОПУЛЯРНЫЙ', 'en': 'MOST POPULAR'},
  'sub.footer': {
    'uz': 'Istalgan vaqtda bekor qilasiz. To\'lov Payme, Click yoki Uzum orqali.',
    'uzc': 'Исталган вақтда бекор қиласиз. Тўлов Payme, Click ёки Uzum орқали.',
    'ru': 'Отмена в любое время. Оплата через Payme, Click или Uzum.',
    'en': 'Cancel anytime. Payment via Payme, Click or Uzum.',
  },

  // ── Xususiyatlar matritsasi ──
  'sub.feat.orgs': {'uz': 'Tashkilotlar kuzatuvi', 'uzc': 'Ташкилотлар кузатуви', 'ru': 'Мониторинг организаций', 'en': 'Organization monitoring'},
  'sub.feat.risk': {'uz': 'Risk balli va tekshiruv prognozi', 'uzc': 'Риск балли ва текширув прогнози', 'ru': 'Риск-балл и прогноз проверок', 'en': 'Risk score and inspection forecast'},
  'sub.feat.ai': {'uz': 'Finn AI tavsiyalari', 'uzc': 'Finn AI тавсиялари', 'ru': 'Рекомендации Finn AI', 'en': 'Finn AI recommendations'},
  'sub.feat.counterparty': {'uz': 'Kontragent tekshiruvi', 'uzc': 'Контрагент текшируви', 'ru': 'Проверка контрагентов', 'en': 'Counterparty check'},
  'sub.feat.cadastre': {'uz': 'Kadastr va mulk ma\'lumotlari', 'uzc': 'Кадастр ва мулк маълумотлари', 'ru': 'Кадастр и данные об имуществе', 'en': 'Cadastre and property data'},
  'sub.feat.audit': {'uz': 'Audit jurnali va hisobotlar', 'uzc': 'Аудит журнали ва ҳисоботлар', 'ru': 'Журнал аудита и отчёты', 'en': 'Audit log and reports'},
  'sub.feat.team': {'uz': 'Jamoa uchun ko\'p foydalanuvchi', 'uzc': 'Жамоа учун кўп фойдаланувчи', 'ru': 'Многопользовательский для команды', 'en': 'Multi-user for teams'},

  // ── To'lov ──
  'sub.payment': {'uz': 'To\'lov', 'uzc': 'Тўлов', 'ru': 'Оплата', 'en': 'Payment'},
  'sub.choosePayment': {'uz': 'To\'lov usulini tanlang', 'uzc': 'Тўлов усулини танланг', 'ru': 'Выберите способ оплаты', 'en': 'Choose a payment method'},
  'sub.paymentFailed': {'uz': 'To\'lovni yaratib bo\'lmadi', 'uzc': 'Тўловни яратиб бўлмади', 'ru': 'Не удалось создать платёж', 'en': 'Failed to create payment'},
  'sub.linkFailed': {'uz': 'To\'lov havolasi olinmadi', 'uzc': 'Тўлов ҳаволаси олинмади', 'ru': 'Ссылка на оплату не получена', 'en': 'Payment link not received'},
  'sub.appNotFound': {'uz': 'ilovasi topilmadi', 'uzc': 'иловаси топилмади', 'ru': 'приложение не найдено', 'en': 'app not found'},
  'sub.paid': {'uz': 'To\'lov qabul qilindi', 'uzc': 'Тўлов қабул қилинди', 'ru': 'Платёж принят', 'en': 'Payment accepted'},
};
