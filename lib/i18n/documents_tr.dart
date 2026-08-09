// documents ekrani tarjimalari (uz/uzc/ru/en).
// Eslatma: hujjat raqami/kontragent/sana/summa API'dan keladi — tarjima qilinmaydi.
const Map<String, Map<String, String>> tr = {
  'doc.title': {'uz': 'Hujjatlar', 'uzc': 'Ҳужжатлар', 'ru': 'Документы', 'en': 'Documents'},
  'doc.subtitle': {'uz': 'Shartnomalar, aktlar va fakturalar', 'uzc': 'Шартномалар, актлар ва фактуралар', 'ru': 'Договоры, акты и счета', 'en': 'Contracts, acts and invoices'},

  // Filtr chiplari.
  'doc.filter.all': {'uz': 'Hammasi', 'uzc': 'Ҳаммаси', 'ru': 'Все', 'en': 'All'},
  'doc.filter.contract': {'uz': 'Shartnoma', 'uzc': 'Шартнома', 'ru': 'Договор', 'en': 'Contract'},
  'doc.filter.act': {'uz': 'Akt', 'uzc': 'Акт', 'ru': 'Акт', 'en': 'Act'},
  'doc.filter.invoice': {'uz': 'Hisob-faktura', 'uzc': 'Ҳисоб-фактура', 'ru': 'Счёт-фактура', 'en': 'Invoice'},

  // Guruh sarlavhalari.
  'doc.group.pending': {'uz': 'Imzo kutmoqda', 'uzc': 'Имзо кутмоқда', 'ru': 'Ожидает подписи', 'en': 'Awaiting signature'},
  'doc.group.recent': {'uz': 'Yaqinda', 'uzc': 'Яқинда', 'ru': 'Недавние', 'en': 'Recent'},

  // Bo'sh / xato holatlari.
  'doc.empty': {'uz': 'Hujjat yo\'q', 'uzc': 'Ҳужжат йўқ', 'ru': 'Нет документов', 'en': 'No documents'},
  'doc.offline': {'uz': 'Aloqa yo\'q', 'uzc': 'Алоқа йўқ', 'ru': 'Нет связи', 'en': 'No connection'},
  'doc.retry': {'uz': 'Qayta urinish', 'uzc': 'Қайта уриниш', 'ru': 'Повторить', 'en': 'Retry'},

  // Holat pillari.
  'doc.pill.accepted': {'uz': 'Qabul', 'uzc': 'Қабул', 'ru': 'Принят', 'en': 'Accepted'},
  'doc.pill.signed': {'uz': 'Imzolangan', 'uzc': 'Имзоланган', 'ru': 'Подписан', 'en': 'Signed'},
  'doc.pill.risk': {'uz': 'Risk', 'uzc': 'Риск', 'ru': 'Риск', 'en': 'Risk'},
  'doc.pill.sign': {'uz': 'Imzo', 'uzc': 'Имзо', 'ru': 'Подпись', 'en': 'Sign'},
};
