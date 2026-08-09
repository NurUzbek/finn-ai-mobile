// financial ekrani tarjimalari — 'fin.' fazosi. Umumiy kalitlar common_tr.dart'da.
// Format: 'kalit': {'uz','uzc','ru','en'}.
const Map<String, Map<String, String>> tr = {
  // ── Sarlavha ──
  'fin.title': {'uz': 'Kirim va chiqim', 'uzc': 'Кирим ва чиқим', 'ru': 'Приход и расход', 'en': 'Income & expense'},

  // ── Filtr segmentlari ──
  'fin.month': {'uz': 'Oy', 'uzc': 'Ой', 'ru': 'Месяц', 'en': 'Month'},
  'fin.quarter': {'uz': 'Chorak', 'uzc': 'Чорак', 'ru': 'Квартал', 'en': 'Quarter'},
  'fin.year': {'uz': 'Yil', 'uzc': 'Йил', 'ru': 'Год', 'en': 'Year'},

  // ── Xulosa kartasi ──
  'fin.income': {'uz': 'Kirim', 'uzc': 'Кирим', 'ru': 'Приход', 'en': 'Income'},
  'fin.expense': {'uz': 'Chiqim', 'uzc': 'Чиқим', 'ru': 'Расход', 'en': 'Expense'},
  'fin.netProfit': {'uz': 'Sof foyda', 'uzc': 'Соф фойда', 'ru': 'Чистая прибыль', 'en': 'Net profit'},

  // ── Operatsiyalar bo'limi ──
  'fin.recentOps': {'uz': 'Oxirgi operatsiyalar', 'uzc': 'Охирги операциялар', 'ru': 'Последние операции', 'en': 'Recent operations'},
  'fin.all': {'uz': 'Hammasi', 'uzc': 'Ҳаммаси', 'ru': 'Все', 'en': 'All'},
  'fin.empty': {'uz': 'Hali operatsiya yo\'q', 'uzc': 'Ҳали операция йўқ', 'ru': 'Пока нет операций', 'en': 'No operations yet'},
  'fin.operation': {'uz': 'Operatsiya', 'uzc': 'Операция', 'ru': 'Операция', 'en': 'Operation'},

  // ── Xatolik holati ──
  'fin.noConnection': {'uz': 'Aloqa yo\'q', 'uzc': 'Алоқа йўқ', 'ru': 'Нет связи', 'en': 'No connection'},

  // ── To'liq oy nomlari (subtitle) ──
  'fin.mon.1': {'uz': 'Yanvar', 'uzc': 'Январ', 'ru': 'Январь', 'en': 'January'},
  'fin.mon.2': {'uz': 'Fevral', 'uzc': 'Феврал', 'ru': 'Февраль', 'en': 'February'},
  'fin.mon.3': {'uz': 'Mart', 'uzc': 'Март', 'ru': 'Март', 'en': 'March'},
  'fin.mon.4': {'uz': 'Aprel', 'uzc': 'Апрел', 'ru': 'Апрель', 'en': 'April'},
  'fin.mon.5': {'uz': 'May', 'uzc': 'Май', 'ru': 'Май', 'en': 'May'},
  'fin.mon.6': {'uz': 'Iyun', 'uzc': 'Июн', 'ru': 'Июнь', 'en': 'June'},
  'fin.mon.7': {'uz': 'Iyul', 'uzc': 'Июл', 'ru': 'Июль', 'en': 'July'},
  'fin.mon.8': {'uz': 'Avgust', 'uzc': 'Август', 'ru': 'Август', 'en': 'August'},
  'fin.mon.9': {'uz': 'Sentabr', 'uzc': 'Сентабр', 'ru': 'Сентябрь', 'en': 'September'},
  'fin.mon.10': {'uz': 'Oktabr', 'uzc': 'Октабр', 'ru': 'Октябрь', 'en': 'October'},
  'fin.mon.11': {'uz': 'Noyabr', 'uzc': 'Ноябр', 'ru': 'Ноябрь', 'en': 'November'},
  'fin.mon.12': {'uz': 'Dekabr', 'uzc': 'Декабр', 'ru': 'Декабрь', 'en': 'December'},

  // ── Diagramma ustunlari (qisqa oy) ──
  'fin.bar.3': {'uz': 'Mar', 'uzc': 'Мар', 'ru': 'Мар', 'en': 'Mar'},
  'fin.bar.4': {'uz': 'Apr', 'uzc': 'Апр', 'ru': 'Апр', 'en': 'Apr'},
  'fin.bar.5': {'uz': 'May', 'uzc': 'Май', 'ru': 'Май', 'en': 'May'},
  'fin.bar.6': {'uz': 'Iyn', 'uzc': 'Июн', 'ru': 'Июн', 'en': 'Jun'},
  'fin.bar.7': {'uz': 'Iyl', 'uzc': 'Июл', 'ru': 'Июл', 'en': 'Jul'},
  'fin.bar.8': {'uz': 'Avg', 'uzc': 'Авг', 'ru': 'Авг', 'en': 'Aug'},

  // ── Operatsiya kategoriyalari (API'dan) ──
  'cat.tax': {'uz': 'Soliq', 'uzc': 'Солиқ', 'ru': 'Налог', 'en': 'Tax'},
  'cat.salary': {'uz': 'Maosh', 'uzc': 'Маош', 'ru': 'Зарплата', 'en': 'Salary'},
  'cat.transport': {'uz': 'Transport', 'uzc': 'Транспорт', 'ru': 'Транспорт', 'en': 'Transport'},
  'cat.rent': {'uz': 'Ijara', 'uzc': 'Ижара', 'ru': 'Аренда', 'en': 'Rent'},
  'cat.goods': {'uz': 'Tovar', 'uzc': 'Товар', 'ru': 'Товар', 'en': 'Goods'},
  'cat.service': {'uz': 'Xizmat', 'uzc': 'Хизмат', 'ru': 'Услуга', 'en': 'Service'},
  'cat.utilities': {'uz': 'Kommunal', 'uzc': 'Коммунал', 'ru': 'Коммунальные', 'en': 'Utilities'},
  'cat.other': {'uz': 'Boshqa', 'uzc': 'Бошқа', 'ru': 'Прочее', 'en': 'Other'},
};
