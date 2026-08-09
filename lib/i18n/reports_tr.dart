// reports ekrani tarjimalari — 4 til (uz, uzc, ru, en).
// status/type qiymatlari API'dan keladi — tarjima qilinmaydi.
// {year}/{q}/{total}/{done}/{date} — Dart'da replaceFirst bilan almashtiriladi.
const Map<String, Map<String, String>> tr = {
  // ── Header ──
  'rep.title': {'uz': 'Hisobotlar', 'uzc': 'Ҳисоботлар', 'ru': 'Отчёты', 'en': 'Reports'},
  'rep.subtitle': {'uz': '{year}-yil · {q}-chorak', 'uzc': '{year}-йил · {q}-чорак', 'ru': '{year} · {q}-й квартал', 'en': '{year} · Q{q}'},

  // ── Umumiy karta ──
  'rep.quarterEndsIn': {'uz': 'CHORAK YAKUNLANISHIGA', 'uzc': 'ЧОРАК ЯКУНЛАНИШИГА', 'ru': 'ДО КОНЦА КВАРТАЛА', 'en': 'UNTIL QUARTER ENDS'},
  'rep.days': {'uz': 'kun', 'uzc': 'кун', 'ru': 'дн.', 'en': 'days'},
  'rep.summaryCount': {'uz': '{total} tadan {done} tasi topshirilgan', 'uzc': '{total} тадан {done} таси топширилган', 'ru': 'Сдано {done} из {total}', 'en': '{done} of {total} submitted'},

  // ── Bo'lim sarlavhalari (eyebrow) ──
  'rep.eyebrowPending': {'uz': 'Topshirilishi kerak', 'uzc': 'Топширилиши керак', 'ru': 'К сдаче', 'en': 'To submit'},
  'rep.eyebrowSubmitted': {'uz': 'Topshirilgan', 'uzc': 'Топширилган', 'ru': 'Сдано', 'en': 'Submitted'},

  // ── Qator: sub-matn ──
  'rep.submittedOn': {'uz': '{date} da topshirilgan', 'uzc': '{date} да топширилган', 'ru': 'Сдано {date}', 'en': 'Submitted on {date}'},
  'rep.submittedShort': {'uz': 'Topshirilgan', 'uzc': 'Топширилган', 'ru': 'Сдано', 'en': 'Submitted'},
  'rep.deadline': {'uz': 'Muddat: {date}', 'uzc': 'Муддат: {date}', 'ru': 'Срок: {date}', 'en': 'Due: {date}'},
  'rep.noDeadline': {'uz': 'Muddat belgilanmagan', 'uzc': 'Муддат белгиланмаган', 'ru': 'Срок не указан', 'en': 'No deadline set'},
  'rep.reportFallback': {'uz': 'Hisobot', 'uzc': 'Ҳисобот', 'ru': 'Отчёт', 'en': 'Report'},

  // ── Holat pillari ──
  'rep.pillAccepted': {'uz': 'Qabul', 'uzc': 'Қабул', 'ru': 'Принят', 'en': 'Accepted'},
  'rep.pillOverdue': {'uz': 'Muddati o\'tgan', 'uzc': 'Муддати ўтган', 'ru': 'Просрочен', 'en': 'Overdue'},
  'rep.pillPending': {'uz': 'Jarayonda', 'uzc': 'Жараёнда', 'ru': 'В процессе', 'en': 'In progress'},
  'rep.pillSubmitted': {'uz': 'Topshirildi', 'uzc': 'Топширилди', 'ru': 'Отправлен', 'en': 'Submitted'},
  'rep.pillRejected': {'uz': 'Rad etildi', 'uzc': 'Рад этилди', 'ru': 'Отклонён', 'en': 'Rejected'},
  'rep.pillDraft': {'uz': 'Qoralama', 'uzc': 'Қоралама', 'ru': 'Черновик', 'en': 'Draft'},

  // ── Bo'sh / xato holatlar ──
  'rep.empty': {'uz': 'Hozircha hisobot yo\'q', 'uzc': 'Ҳозирча ҳисобот йўқ', 'ru': 'Пока нет отчётов', 'en': 'No reports yet'},
  'rep.noConnection': {'uz': 'Aloqa yo\'q', 'uzc': 'Алоқа йўқ', 'ru': 'Нет связи', 'en': 'No connection'},
  'rep.retry': {'uz': 'Qayta urinish', 'uzc': 'Қайта уриниш', 'ru': 'Повторить', 'en': 'Retry'},

  // ── Hisobot turlari (API'dan keladigan `type`/`title` — DB'da o'zbekcha) ──
  'rtype.vat': {'uz': 'QQS deklaratsiyasi', 'uzc': 'ҚҚС декларацияси', 'ru': 'Декларация НДС', 'en': 'VAT declaration'},
  'rtype.profit': {'uz': 'Foyda solig\'i', 'uzc': 'Фойда солиғи', 'ru': 'Налог на прибыль', 'en': 'Profit tax'},
  'rtype.inps': {'uz': 'INPS hisobot', 'uzc': 'ИНПС ҳисобот', 'ru': 'Отчёт ИНПС', 'en': 'INPS report'},
  'rtype.turnover': {'uz': 'Aylanma soliq', 'uzc': 'Айланма солиқ', 'ru': 'Налог с оборота', 'en': 'Turnover tax'},
  'rtype.reports': {'uz': 'Hisobotlar', 'uzc': 'Ҳисоботлар', 'ru': 'Отчётность', 'en': 'Reports'},
};
