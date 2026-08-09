// wallet (Hamyon) ekrani tarjimalari — 4 til (uz, uzc, ru, en).
// Raqam/summa/karta raqamlari tarjima qilinmaydi — faqat interfeys matni.
const Map<String, Map<String, String>> tr = {
  // ── Header ──
  'wal.title': {'uz': 'Hamyon', 'uzc': 'Ҳамён', 'ru': 'Кошелёк', 'en': 'Wallet'},
  'wal.subtitle': {'uz': 'Hisob raqamlar va balans', 'uzc': 'Ҳисоб рақамлар ва баланс', 'ru': 'Счета и баланс', 'en': 'Accounts and balance'},

  // ── Balans kartasi ──
  'wal.totalFunds': {'uz': 'JAMI MABLAG\'', 'uzc': 'ЖАМИ МАБЛАҒ', 'ru': 'ОБЩИЙ БАЛАНС', 'en': 'TOTAL FUNDS'},
  'wal.acctsWord': {'uz': 'ta hisob raqam', 'uzc': 'та ҳисоб рақам', 'ru': 'счетов', 'en': 'accounts'},
  'wal.orgsWord': {'uz': 'ta tashkilot', 'uzc': 'та ташкилот', 'ru': 'организаций', 'en': 'organizations'},

  // ── Hisob raqamlar bo'limi ──
  'wal.accounts': {'uz': 'Hisob raqamlar', 'uzc': 'Ҳисоб рақамлар', 'ru': 'Счета', 'en': 'Accounts'},
  'wal.add': {'uz': 'Qo\'shish', 'uzc': 'Қўшиш', 'ru': 'Добавить', 'en': 'Add'},

  // ── Bank / hisob nomlari (demo) ──
  'wal.bankIpoteka': {'uz': 'Ipoteka Bank', 'uzc': 'Ипотека Банк', 'ru': 'Ипотека Банк', 'en': 'Ipoteka Bank'},
  'wal.bankKapital': {'uz': 'Kapital Bank', 'uzc': 'Капитал Банк', 'ru': 'Капитал Банк', 'en': 'Kapital Bank'},
  'wal.acctUsd': {'uz': 'Valyuta hisobi · USD', 'uzc': 'Валюта ҳисоби · USD', 'ru': 'Валютный счёт · USD', 'en': 'Currency account · USD'},

  // ── Kutilayotgan to'lovlar ──
  'wal.pending': {'uz': 'Kutilayotgan to\'lovlar', 'uzc': 'Кутилаётган тўловлар', 'ru': 'Ожидаемые платежи', 'en': 'Pending payments'},
  'wal.taxPayments': {'uz': 'Soliq to\'lovlari', 'uzc': 'Солиқ тўловлари', 'ru': 'Налоговые платежи', 'en': 'Tax payments'},
  'wal.coversText': {'uz': 'Mavjud mablag\'ning 43% ini qoplaydi', 'uzc': 'Мавжуд маблағнинг 43% ини қоплайди', 'ru': 'Покрывает 43% доступных средств', 'en': 'Covers 43% of available funds'},

  // ── Xato holati ──
  'wal.noConnection': {'uz': 'Aloqa yo\'q', 'uzc': 'Алоқа йўқ', 'ru': 'Нет связи', 'en': 'No connection'},
  'wal.retry': {'uz': 'Qayta urinish', 'uzc': 'Қайта уриниш', 'ru': 'Повторить', 'en': 'Retry'},
};
