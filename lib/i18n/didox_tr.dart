// didox ekrani (E-hujjat) tarjimalari (uz/uzc/ru/en).
// Format: 'kalit': {'uz','uzc','ru','en'}.
// {party}/{n} — dinamik qiymatlar (replaceAll bilan).
const Map<String, Map<String, String>> tr = {
  // ── Sarlavha ──
  'didox.title': {'uz': 'E-hujjat', 'uzc': 'Э-ҳужжат', 'ru': 'Э-документ', 'en': 'E-document'},
  'didox.subtitle': {
    'uz': 'Didox integratsiyasi · ulangan',
    'uzc': 'Didox интеграцияси · уланган',
    'ru': 'Интеграция Didox · подключено',
    'en': 'Didox integration · connected'
  },

  // ── Filtr chiplari ──
  'didox.tab.kiruvchi': {'uz': 'Kiruvchi', 'uzc': 'Кирувчи', 'ru': 'Входящие', 'en': 'Incoming'},
  'didox.tab.chiquvchi': {'uz': 'Chiquvchi', 'uzc': 'Чиқувчи', 'ru': 'Исходящие', 'en': 'Outgoing'},
  'didox.tab.rad': {'uz': 'Rad etilgan', 'uzc': 'Рад этилган', 'ru': 'Отклонённые', 'en': 'Rejected'},

  // ── Eyebrow ──
  'didox.eyebrow.kiruvchi': {
    'uz': 'Kiruvchi fakturalar',
    'uzc': 'Кирувчи фактуралар',
    'ru': 'Входящие фактуры',
    'en': 'Incoming invoices'
  },
  'didox.eyebrow.chiquvchi': {
    'uz': 'Chiquvchi fakturalar',
    'uzc': 'Чиқувчи фактуралар',
    'ru': 'Исходящие фактуры',
    'en': 'Outgoing invoices'
  },
  'didox.eyebrow.rad': {
    'uz': 'Rad etilgan fakturalar',
    'uzc': 'Рад этилган фактуралар',
    'ru': 'Отклонённые фактуры',
    'en': 'Rejected invoices'
  },

  // ── QQS zanjiri ogohlantirishi ──
  'didox.alert.title': {
    'uz': 'QQS zanjiri uzilgan',
    'uzc': 'ҚҚС занжири узилган',
    'ru': 'Цепочка НДС разорвана',
    'en': 'VAT chain broken'
  },
  'didox.alert.body': {
    'uz': '{party} hisobot topshirmagan. Undan olingan {n} ta faktura bo\'yicha chegirma rad etilishi mumkin.',
    'uzc': '{party} ҳисобот топширмаган. Ундан олинган {n} та фактура бўйича чегирма рад этилиши мумкин.',
    'ru': '{party} не сдал отчётность. По {n} полученным от него фактурам зачёт может быть отклонён.',
    'en': '{party} has not filed reports. The credit on {n} invoices received from them may be rejected.'
  },
  'didox.counterparty': {'uz': 'Kontragent', 'uzc': 'Контрагент', 'ru': 'Контрагент', 'en': 'Counterparty'},

  // ── Holat pillari ──
  'didox.status.accepted': {'uz': 'Qabul', 'uzc': 'Қабул', 'ru': 'Принято', 'en': 'Accepted'},
  'didox.status.sign': {'uz': 'Imzo', 'uzc': 'Имзо', 'ru': 'Подпись', 'en': 'Sign'},
  'didox.status.risk': {'uz': 'Risk', 'uzc': 'Риск', 'ru': 'Риск', 'en': 'Risk'},

  // ── Bo'sh / xato holatlar ──
  'didox.emptyConnect': {
    'uz': 'E-hujjat yo\'q — Didox ulanmagan boʻlishi mumkin',
    'uzc': 'Э-ҳужжат йўқ — Didox уланмаган бўлиши мумкин',
    'ru': 'Нет э-документов — возможно, Didox не подключён',
    'en': 'No e-documents — Didox may not be connected'
  },
  'didox.emptyFilter': {
    'uz': 'Ushbu holatda hujjat topilmadi',
    'uzc': 'Ушбу ҳолатда ҳужжат топилмади',
    'ru': 'Документы в этом статусе не найдены',
    'en': 'No documents found for this status'
  },
  'didox.offline': {'uz': 'Aloqa yo\'q', 'uzc': 'Алоқа йўқ', 'ru': 'Нет связи', 'en': 'No connection'},
  'didox.retry': {'uz': 'Qayta urinish', 'uzc': 'Қайта уриниш', 'ru': 'Повторить', 'en': 'Retry'},
};
