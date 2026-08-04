// risk ekrani tarjimalari — statik interfeys matnlari.
// Risk elementlarining title/detail maydonlari API'dan keladi — tarjima qilinmaydi.
// Format: 'kalit': {'uz','uzc','ru','en'}.
const Map<String, Map<String, String>> tr = {
  // ── Sarlavha ──
  'risk.title': {'uz': 'Risk tahlili', 'uzc': 'Риск таҳлили', 'ru': 'Анализ рисков', 'en': 'Risk analysis'},
  'risk.subtitle': {'uz': 'Soliq tekshiruvi ehtimoli', 'uzc': 'Солиқ текшируви эҳтимоли', 'ru': 'Вероятность налоговой проверки', 'en': 'Tax inspection probability'},

  // ── Qulflangan holat (LockedFeature) ──
  'risk.locked.desc': {
    'uz': 'Tashkilotingizning soliq, moliyaviy va hujjat risklarini 100 ballik shkalada baholaydi.',
    'uzc': 'Ташкилотингизнинг солиқ, молиявий ва ҳужжат рискларини 100 балли шкалада баҳолайди.',
    'ru': 'Оценивает налоговые, финансовые и документальные риски вашей организации по 100-балльной шкале.',
    'en': 'Evaluates your organization\'s tax, financial and document risks on a 100-point scale.'
  },
  'risk.locked.perk1': {'uz': 'Umumiy risk balli va rangli zona', 'uzc': 'Умумий риск балли ва рангли зона', 'ru': 'Общий балл риска и цветовая зона', 'en': 'Overall risk score and color zone'},
  'risk.locked.perk2': {'uz': 'Soliq intizomi va qarzdorlik tahlili', 'uzc': 'Солиқ интизоми ва қарздорлик таҳлили', 'ru': 'Анализ налоговой дисциплины и задолженности', 'en': 'Tax discipline and debt analysis'},
  'risk.locked.perk3': {'uz': 'E-faktura va kontragent risklari', 'uzc': 'Э-фактура ва контрагент рисклари', 'ru': 'Риски э-фактуры и контрагентов', 'en': 'E-invoice and counterparty risks'},
  'risk.locked.perk4': {'uz': 'Hisob bloklash xavfi haqida ogohlantirish', 'uzc': 'Ҳисоб блоклаш хавфи ҳақида огоҳлантириш', 'ru': 'Предупреждение о риске блокировки счёта', 'en': 'Account blocking risk warning'},
  'risk.locked.perk5': {'uz': 'PDF hisobot yuklab olish', 'uzc': 'PDF ҳисобот юклаб олиш', 'ru': 'Скачивание PDF-отчёта', 'en': 'PDF report download'},

  // ── Risk darajasi (status pill) ──
  'risk.level.low': {'uz': 'Past risk', 'uzc': 'Паст риск', 'ru': 'Низкий риск', 'en': 'Low risk'},
  'risk.level.mid': {'uz': 'O\'rta risk', 'uzc': 'Ўрта риск', 'ru': 'Средний риск', 'en': 'Medium risk'},
  'risk.level.high': {'uz': 'Yuqori risk', 'uzc': 'Юқори риск', 'ru': 'Высокий риск', 'en': 'High risk'},

  // ── Ball halqasi ──
  'risk.outOf100': {'uz': '100 balldan', 'uzc': '100 баллдан', 'ru': 'из 100 баллов', 'en': 'out of 100'},

  // ── Statistika kartalari ──
  'risk.stat.flags': {'uz': 'Jiddiy risk', 'uzc': 'Жиддий риск', 'ru': 'Серьёзный риск', 'en': 'Serious risk'},
  'risk.stat.warns': {'uz': 'Ogohlantirish', 'uzc': 'Огоҳлантириш', 'ru': 'Предупреждение', 'en': 'Warning'},

  // ── Bo'lim sarlavhasi ──
  'risk.detected': {'uz': 'Aniqlangan risklar', 'uzc': 'Аниқланган рисклар', 'ru': 'Выявленные риски', 'en': 'Detected risks'},
  'risk.factors': {'uz': 'Ballga nima ta\'sir qildi', 'uzc': 'Баллга нима таъсир қилди', 'ru': 'Что повлияло на балл', 'en': 'What affected the score'},

  // ── Bo'sh / xato holatlar ──
  'risk.empty.noOrg': {'uz': 'Avval tashkilot qo\'shing', 'uzc': 'Аввал ташкилот қўшинг', 'ru': 'Сначала добавьте организацию', 'en': 'Add an organization first'},
  'risk.empty.noRisk': {'uz': 'Aniqlangan risk yo\'q', 'uzc': 'Аниқланган риск йўқ', 'ru': 'Рисков не выявлено', 'en': 'No risks detected'},
  'risk.noData': {'uz': 'Ma\'lumot olinmadi', 'uzc': 'Маълумот олинмади', 'ru': 'Не удалось получить данные', 'en': 'Failed to load data'},
};
