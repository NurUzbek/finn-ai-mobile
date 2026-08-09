// dashboard ekrani tarjimalari — 'dash.' fazosi. Umumiy kalitlar common_tr.dart'da.
// Format: 'kalit': {'uz','uzc','ru','en'}.
const Map<String, Map<String, String>> tr = {
  // ── Balans kartasi ──
  'dash.totalBalance': {'uz': 'UMUMIY BALANS', 'uzc': 'УМУМИЙ БАЛАНС', 'ru': 'ОБЩИЙ БАЛАНС', 'en': 'TOTAL BALANCE'},
  'dash.orgs': {'uz': 'Tashkilot', 'uzc': 'Ташкилот', 'ru': 'Фирмы', 'en': 'Firms'},
  'dash.clean': {'uz': 'Toza', 'uzc': 'Тоза', 'ru': 'Чисто', 'en': 'Clean'},
  'dash.overdue': {'uz': 'Kechikkan', 'uzc': 'Кечиккан', 'ru': 'Просрочено', 'en': 'Overdue'},

  // ── Upsell ──
  'dash.freePlan': {
    'uz': 'Bepul rejim — 3 tadan ortiq firma kuzatilmaydi',
    'uzc': 'Бепул режим — 3 тадан ортиқ фирма кузатилмайди',
    'ru': 'Бесплатный режим — отслеживается не более 3 фирм',
    'en': 'Free plan — no more than 3 firms are tracked'
  },

  // ── Ogohlantirish / AI penya ──
  // "$overdue ta to'lov kechikkan" — son interpolatsiya kalitdan tashqarida.
  'dash.overduePayments': {'uz': 'ta to\'lov kechikkan', 'uzc': 'та тўлов кечиккан', 'ru': 'просроченных платежей', 'en': 'payments overdue'},
  'dash.total': {'uz': 'Jami', 'uzc': 'Жами', 'ru': 'Всего', 'en': 'Total'},
  'dash.penalty': {'uz': 'penya', 'uzc': 'пеня', 'ru': 'пени', 'en': 'penalty'},

  // ── Bo'lim sarlavhalari ──
  'dash.financialStatus': {'uz': 'Moliyaviy holat', 'uzc': 'Молиявий ҳолат', 'ru': 'Финансовое состояние', 'en': 'Financial status'},
  'dash.yourFirms': {'uz': 'Firmalaringiz', 'uzc': 'Фирмаларингиз', 'ru': 'Ваши фирмы', 'en': 'Your firms'},
  'dash.recommendation': {'uz': 'Tavsiya', 'uzc': 'Тавсия', 'ru': 'Рекомендация', 'en': 'Recommendation'},
  'dash.recentAlerts': {'uz': 'So\'nggi xabarlar', 'uzc': 'Сўнгги хабарлар', 'ru': 'Последние сообщения', 'en': 'Recent alerts'},
  'dash.sections': {'uz': 'Bo\'limlar', 'uzc': 'Бўлимлар', 'ru': 'Разделы', 'en': 'Sections'},
  // Modul yorliqlari (dashboard grid)
  'mod.financial': {'uz': 'Kirim/chiqim', 'uzc': 'Кирим/чиқим', 'ru': 'Приход/расход', 'en': 'Cash flow'},
  'mod.wallet': {'uz': 'Hamyon', 'uzc': 'Ҳамён', 'ru': 'Кошелёк', 'en': 'Wallet'},
  'mod.currency': {'uz': 'Valyuta', 'uzc': 'Валюта', 'ru': 'Валюта', 'en': 'Currency'},
  'mod.documents': {'uz': 'Hujjatlar', 'uzc': 'Ҳужжатлар', 'ru': 'Документы', 'en': 'Documents'},
  'mod.didox': {'uz': 'E-hujjat', 'uzc': 'Э-ҳужжат', 'ru': 'Э-документ', 'en': 'E-invoice'},
  'mod.reports': {'uz': 'Hisobotlar', 'uzc': 'Ҳисоботлар', 'ru': 'Отчёты', 'en': 'Reports'},
  'mod.calendar': {'uz': 'Kalendar', 'uzc': 'Календар', 'ru': 'Календарь', 'en': 'Calendar'},
  'mod.employees': {'uz': 'Xodimlar', 'uzc': 'Ходимлар', 'ru': 'Сотрудники', 'en': 'Employees'},
  'mod.team': {'uz': 'Jamoa', 'uzc': 'Жамоа', 'ru': 'Команда', 'en': 'Team'},
  'mod.counterparty': {'uz': 'Kontragent', 'uzc': 'Контрагент', 'ru': 'Контрагент', 'en': 'Counterparty'},
  'mod.audit': {'uz': 'Audit', 'uzc': 'Аудит', 'ru': 'Аудит', 'en': 'Audit'},
  'mod.enforcement': {'uz': 'Ijro', 'uzc': 'Ижро', 'ru': 'Взыскание', 'en': 'Enforcement'},

  // ── Moliyaviy kartalar ──
  'dash.totalDebt': {'uz': 'Umumiy qarz', 'uzc': 'Умумий қарз', 'ru': 'Общий долг', 'en': 'Total debt'},
  'dash.totalPenalty': {'uz': 'Jami penya', 'uzc': 'Жами пеня', 'ru': 'Всего пени', 'en': 'Total penalty'},
  'dash.avgRisk': {'uz': 'O\'rtacha risk', 'uzc': 'Ўртача риск', 'ru': 'Средний риск', 'en': 'Average risk'},
  'dash.chartCaption': {
    'uz': 'Oxirgi 9 oy · so\'nggi oylarda o\'sish',
    'uzc': 'Охирги 9 ой · сўнгги ойларда ўсиш',
    'ru': 'Последние 9 месяцев · рост в последние месяцы',
    'en': 'Last 9 months · growth in recent months'
  },

  // ── Firmalar bo'sh holat ──
  'dash.addFirm': {'uz': 'Firma qo\'shing', 'uzc': 'Фирма қўшинг', 'ru': 'Добавьте фирму', 'en': 'Add a firm'},
  'dash.startTracking': {
    'uz': 'Soliq holatini kuzatishni boshlang',
    'uzc': 'Солиқ ҳолатини кузатишни бошланг',
    'ru': 'Начните отслеживать налоговое состояние',
    'en': 'Start tracking your tax status'
  },
  'dash.debt': {'uz': 'qarz', 'uzc': 'қарз', 'ru': 'долг', 'en': 'debt'},

  // ── FINN AI kartasi ──
  'dash.finnAi': {'uz': 'FINN AI', 'uzc': 'FINN AI', 'ru': 'FINN AI', 'en': 'FINN AI'},
  'dash.aiOverdueTitle': {
    'uz': 'Kechikkan to\'lovlar penyani oshirmoqda',
    'uzc': 'Кечиккан тўловлар пеняни оширмоқда',
    'ru': 'Просроченные платежи увеличивают пеню',
    'en': 'Overdue payments are increasing the penalty'
  },
  'dash.aiStableTitle': {
    'uz': 'Moliyaviy holatingiz barqaror',
    'uzc': 'Молиявий ҳолатингиз барқарор',
    'ru': 'Ваше финансовое состояние стабильно',
    'en': 'Your financial status is stable'
  },
  'dash.aiOverdueBody': {
    'uz': 'Eng yaqin muddatni bugun yoping — o\'sish to\'xtaydi.',
    'uzc': 'Энг яқин муддатни бугун ёпинг — ўсиш тўхтайди.',
    'ru': 'Закройте ближайший срок сегодня — рост прекратится.',
    'en': 'Close the nearest deadline today — the growth will stop.'
  },
  'dash.aiStableBody': {
    'uz': 'Jiddiy risk aniqlanmadi. Savolingiz bo\'lsa — Finn AI konsultantdan so\'rang.',
    'uzc': 'Жиддий риск аниқланмади. Саволингиз бўлса — Finn AI консультантдан сўранг.',
    'ru': 'Серьёзных рисков не обнаружено. Есть вопрос — спросите у консультанта Finn AI.',
    'en': 'No serious risks detected. If you have a question — ask the Finn AI consultant.'
  },

  // ── Asosiy ekran (dashboard_screen) ──
  'dash.subtitle': {'uz': 'Umumiy holat bir ko\'rishda', 'uzc': 'Умумий ҳолат бир кўришда', 'ru': 'Общая картина с одного взгляда', 'en': 'Overview at a glance'},
  'dash.penyaLive': {'uz': 'Penya hozir hisoblanmoqda', 'uzc': 'Пеня ҳозир ҳисобланмоқда', 'ru': 'Пеня начисляется сейчас', 'en': 'Penalty is accruing now'},
  'dash.somPerDay': {'uz': 'so\'m/kun', 'uzc': 'сўм/кун', 'ru': 'сум/день', 'en': 'so\'m/day'},
  'dash.deadlines': {'uz': 'Yaqin muddatlar', 'uzc': 'Яқин муддатлар', 'ru': 'Ближайшие сроки', 'en': 'Upcoming deadlines'},
  'dash.cashflow': {'uz': 'Pul oqimi', 'uzc': 'Пул оқими', 'ru': 'Денежный поток', 'en': 'Cash flow'},
  'dash.netProfitMonth': {'uz': 'SOF FOYDA · AVGUST', 'uzc': 'СОФ ФОЙДА · АВГУСТ', 'ru': 'ЧИСТАЯ ПРИБЫЛЬ · АВГУСТ', 'en': 'NET PROFIT · AUGUST'},
  'dash.income': {'uz': 'Kirim', 'uzc': 'Кирим', 'ru': 'Приход', 'en': 'Income'},
  'dash.expense': {'uz': 'Chiqim', 'uzc': 'Чиқим', 'ru': 'Расход', 'en': 'Expense'},
  'dash.status': {'uz': 'Holat', 'uzc': 'Ҳолат', 'ru': 'Состояние', 'en': 'Status'},
  'dash.score': {'uz': 'ball', 'uzc': 'балл', 'ru': 'балл', 'en': 'pts'},
  'dash.riskLevel': {'uz': 'RISK DARAJASI', 'uzc': 'РИСК ДАРАЖАСИ', 'ru': 'УРОВЕНЬ РИСКА', 'en': 'RISK LEVEL'},
  'dash.riskHigh': {'uz': 'Yuqori', 'uzc': 'Юқори', 'ru': 'Высокий', 'en': 'High'},
  'dash.riskMid': {'uz': 'O\'rta', 'uzc': 'Ўрта', 'ru': 'Средний', 'en': 'Medium'},
  'dash.riskLow': {'uz': 'Past', 'uzc': 'Паст', 'ru': 'Низкий', 'en': 'Low'},
  'dash.todayRecommendation': {'uz': 'BUGUNGI TAVSIYA', 'uzc': 'БУГУНГИ ТАВСИЯ', 'ru': 'РЕКОМЕНДАЦИЯ ДНЯ', 'en': 'TODAY\'S ADVICE'},
  'dash.quickAccess': {'uz': 'Tez kirish', 'uzc': 'Тез кириш', 'ru': 'Быстрый доступ', 'en': 'Quick access'},
  'dash.didox': {'uz': 'Didox', 'uzc': 'Didox', 'ru': 'Didox', 'en': 'Didox'},
};
