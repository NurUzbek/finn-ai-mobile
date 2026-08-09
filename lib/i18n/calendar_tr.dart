// calendar ekrani (Ish kalendari) tarjimalari — 'cal.' fazosi.
// Format: 'kalit': {'uz','uzc','ru','en'}.
const Map<String, Map<String, String>> tr = {
  // ── Sarlavha / holatlar ──
  'cal.title': {'uz': 'Ish kalendari', 'uzc': 'Иш календари', 'ru': 'Рабочий календарь', 'en': 'Work calendar'},
  'cal.errLoad': {'uz': 'Ma\'lumot olinmadi', 'uzc': 'Маълумот олинмади', 'ru': 'Не удалось загрузить', 'en': 'Failed to load'},
  'cal.retry': {'uz': 'Qayta urinish', 'uzc': 'Қайта уриниш', 'ru': 'Повторить', 'en': 'Retry'},
  'cal.noData': {'uz': 'Ma\'lumot yo\'q', 'uzc': 'Маълумот йўқ', 'ru': 'Нет данных', 'en': 'No data'},
  'cal.upcoming': {'uz': 'Yaqin muddatlar', 'uzc': 'Яқин муддатлар', 'ru': 'Ближайшие сроки', 'en': 'Upcoming deadlines'},
  'cal.noDeadlines': {'uz': 'Bu oyda muddat yo\'q', 'uzc': 'Бу ойда муддат йўқ', 'ru': 'В этом месяце сроков нет', 'en': 'No deadlines this month'},

  // ── Izoh (legend) ──
  'cal.legendTax': {'uz': 'Soliq', 'uzc': 'Солиқ', 'ru': 'Налог', 'en': 'Tax'},
  'cal.legendReport': {'uz': 'Hisobot', 'uzc': 'Ҳисобот', 'ru': 'Отчёт', 'en': 'Report'},
  'cal.legendInternal': {'uz': 'Ichki', 'uzc': 'Ички', 'ru': 'Внутр.', 'en': 'Internal'},

  // ── Muddat qatorlari (pill) ──
  'cal.today': {'uz': 'Bugun', 'uzc': 'Бугун', 'ru': 'Сегодня', 'en': 'Today'},
  // "$diff kun" — son interpolatsiya kalitdan tashqarida.
  'cal.days': {'uz': 'kun', 'uzc': 'кун', 'ru': 'дн.', 'en': 'days'},
  'cal.overdue': {'uz': 'O\'tdi', 'uzc': 'Ўтди', 'ru': 'Прошло', 'en': 'Passed'},

  // ── Oy nomlari (1-12) ──
  'cal.mon.1': {'uz': 'Yanvar', 'uzc': 'Январ', 'ru': 'Январь', 'en': 'January'},
  'cal.mon.2': {'uz': 'Fevral', 'uzc': 'Феврал', 'ru': 'Февраль', 'en': 'February'},
  'cal.mon.3': {'uz': 'Mart', 'uzc': 'Март', 'ru': 'Март', 'en': 'March'},
  'cal.mon.4': {'uz': 'Aprel', 'uzc': 'Апрел', 'ru': 'Апрель', 'en': 'April'},
  'cal.mon.5': {'uz': 'May', 'uzc': 'Май', 'ru': 'Май', 'en': 'May'},
  'cal.mon.6': {'uz': 'Iyun', 'uzc': 'Июн', 'ru': 'Июнь', 'en': 'June'},
  'cal.mon.7': {'uz': 'Iyul', 'uzc': 'Июл', 'ru': 'Июль', 'en': 'July'},
  'cal.mon.8': {'uz': 'Avgust', 'uzc': 'Август', 'ru': 'Август', 'en': 'August'},
  'cal.mon.9': {'uz': 'Sentabr', 'uzc': 'Сентябр', 'ru': 'Сентябрь', 'en': 'September'},
  'cal.mon.10': {'uz': 'Oktabr', 'uzc': 'Октябр', 'ru': 'Октябрь', 'en': 'October'},
  'cal.mon.11': {'uz': 'Noyabr', 'uzc': 'Ноябр', 'ru': 'Ноябрь', 'en': 'November'},
  'cal.mon.12': {'uz': 'Dekabr', 'uzc': 'Декабр', 'ru': 'Декабрь', 'en': 'December'},

  // ── Hafta kunlari (1=Du .. 7=Ya) ──
  'cal.dow.1': {'uz': 'Du', 'uzc': 'Ду', 'ru': 'Пн', 'en': 'Mon'},
  'cal.dow.2': {'uz': 'Se', 'uzc': 'Се', 'ru': 'Вт', 'en': 'Tue'},
  'cal.dow.3': {'uz': 'Ch', 'uzc': 'Чо', 'ru': 'Ср', 'en': 'Wed'},
  'cal.dow.4': {'uz': 'Pa', 'uzc': 'Па', 'ru': 'Чт', 'en': 'Thu'},
  'cal.dow.5': {'uz': 'Ju', 'uzc': 'Жу', 'ru': 'Пт', 'en': 'Fri'},
  'cal.dow.6': {'uz': 'Sh', 'uzc': 'Ша', 'ru': 'Сб', 'en': 'Sat'},
  'cal.dow.7': {'uz': 'Ya', 'uzc': 'Як', 'ru': 'Вс', 'en': 'Sun'},
};
