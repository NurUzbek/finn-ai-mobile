// subscription ekrani tarjimalari — sub.* namespace, 4 til (uz, uzc, ru, en).
// Tarif nomi/tavsifi API'dan keladi — tarjima qilinmaydi.
const Map<String, Map<String, String>> tr = {
  // ── Sarlavha / umumiy ──
  'sub.title': {'uz': 'Tariflar', 'uzc': 'Тарифлар', 'ru': 'Тарифы', 'en': 'Plans'},
  'sub.pickTitle': {'uz': 'Tarifni tanlang', 'uzc': 'Тарифни танланг', 'ru': 'Выберите тариф', 'en': 'Choose a plan'},
  'sub.pickSub': {'uz': 'Istalgan vaqtda o\'zgartirasiz', 'uzc': 'Исталган вақтда ўзгартирасиз', 'ru': 'Меняйте в любое время', 'en': 'Change anytime'},
  'sub.currentPlan': {'uz': 'Joriy tarif', 'uzc': 'Жорий тариф', 'ru': 'Текущий тариф', 'en': 'Current plan'},
  'sub.current': {'uz': 'Joriy', 'uzc': 'Жорий', 'ru': 'Текущий', 'en': 'Current'},
  'sub.currentMode': {'uz': 'Joriy rejim', 'uzc': 'Жорий режим', 'ru': 'Текущий режим', 'en': 'Current plan'},
  'sub.mode': {'uz': 'rejim', 'uzc': 'режим', 'ru': 'тариф', 'en': 'plan'},
  'sub.days': {'uz': 'kun', 'uzc': 'кун', 'ru': 'дн', 'en': 'days'},

  // ── Limit banneri (joriy tarif) ──
  'sub.orgsBand': {
    'uz': '{n} tadan {u} ta tashkilot band',
    'uzc': '{n} тадан {u} та ташкилот банд',
    'ru': 'занято {u} из {n} организаций',
    'en': '{u} of {n} organizations used',
  },
  'sub.limNote': {
    'uz': 'Limitga yetdingiz. Yangi firma qo\'shish uchun tarifni kengaytiring.',
    'uzc': 'Лимитга етдингиз. Янги фирма қўшиш учун тарифни кенгайтиринг.',
    'ru': 'Достигнут лимит. Расширьте тариф, чтобы добавить организацию.',
    'en': 'You\'ve reached the limit. Upgrade your plan to add a company.',
  },

  // ── Sikl (oylik/yillik) ──
  'sub.monthly': {'uz': 'Oylik', 'uzc': 'Ойлик', 'ru': 'Ежемесячно', 'en': 'Monthly'},
  'sub.yearly': {'uz': 'Yillik', 'uzc': 'Йиллик', 'ru': 'Ежегодно', 'en': 'Yearly'},
  'sub.saveHint': {
    'uz': 'Yillik to\'lovda 2.4 oy bepul',
    'uzc': 'Йиллик тўловда 2.4 ой бепул',
    'ru': 'При годовой оплате 2.4 месяца бесплатно',
    'en': '2.4 months free with yearly billing',
  },
  'sub.somPerMonth': {'uz': 'so\'m/oy', 'uzc': 'сўм/ой', 'ru': 'сум/мес', 'en': 'so\'m/mo'},
  'sub.somPerYear': {'uz': 'so\'m/yil', 'uzc': 'сўм/йил', 'ru': 'сум/год', 'en': 'so\'m/yr'},
  'sub.trialUnit': {'uz': '14 kun sinov', 'uzc': '14 кун синов', 'ru': '14 дней пробный', 'en': '14-day trial'},
  'sub.custom': {'uz': 'Kelishuv', 'uzc': 'Келишув', 'ru': 'Договорная', 'en': 'Custom'},
  'sub.individual': {'uz': 'individual', 'uzc': 'индивидуал', 'ru': 'индивидуально', 'en': 'individual'},
  'sub.contact': {'uz': 'Bog\'lanish', 'uzc': 'Боғланиш', 'ru': 'Связаться', 'en': 'Contact'},
  'sub.compare': {
    'uz': 'Barcha imkoniyatlarni solishtirish',
    'uzc': 'Барча имкониятларни солиштириш',
    'ru': 'Сравнить все возможности',
    'en': 'Compare all features',
  },
  'sub.trNote': {
    'uz': 'To\'lov Payme, Click yoki Uzum orqali. Bekor qilganingizda joriy davr oxirigacha ishlaydi.',
    'uzc': 'Тўлов Payme, Click ёки Uzum орқали. Бекор қилганингизда жорий давр охиригача ишлайди.',
    'ru': 'Оплата через Payme, Click или Uzum. При отмене действует до конца текущего периода.',
    'en': 'Payment via Payme, Click or Uzum. If cancelled, it works until the end of the current period.',
  },

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
