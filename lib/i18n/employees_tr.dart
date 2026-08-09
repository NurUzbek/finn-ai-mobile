// employees ekrani tarjimalari (uz/uzc/ru/en).
// Format: 'kalit': {'uz','uzc','ru','en'}.
// Eslatma: ism, lavozim (API), pul qiymatlari — dinamik, tarjima qilinmaydi.
const Map<String, Map<String, String>> tr = {
  // ── Sarlavha ──
  'emp.title': {'uz': 'Xodimlar', 'uzc': 'Ходимлар', 'ru': 'Сотрудники', 'en': 'Employees'},
  'emp.subtitle': {'uz': 'Jamoa a\'zolari', 'uzc': 'Жамоа аъзолари', 'ru': 'Члены команды', 'en': 'Team members'},
  // Subtitle: "$n xodim" — son Dart'da, so'z shu yerda.
  'emp.countWord': {'uz': 'xodim', 'uzc': 'ходим', 'ru': 'сотрудников', 'en': 'employees'},

  // ── Yig'indi kartalari ──
  'emp.fund': {'uz': 'Oylik fond', 'uzc': 'Ойлик фонд', 'ru': 'Месячный фонд', 'en': 'Monthly payroll'},
  'emp.yait': {'uz': 'YaIT bo\'yicha', 'uzc': 'ЯИТ бўйича', 'ru': 'По ЯИТ', 'en': 'By YaIT'},
  'emp.somMonth': {'uz': 'so\'m/oy', 'uzc': 'сўм/ой', 'ru': 'сум/мес', 'en': 'soum/mo'},
  'emp.mln': {'uz': 'mln', 'uzc': 'млн', 'ru': 'млн', 'en': 'M'},

  // ── Ro'yxat ──
  'emp.list': {'uz': 'Ro\'yxat', 'uzc': 'Рўйхат', 'ru': 'Список', 'en': 'List'},
  'emp.filter': {'uz': 'Filtr', 'uzc': 'Фильтр', 'ru': 'Фильтр', 'en': 'Filter'},

  // ── Bo'sh / xato holatlar ──
  'emp.empty': {'uz': 'Xodim yo\'q', 'uzc': 'Ходим йўқ', 'ru': 'Нет сотрудников', 'en': 'No employees'},
  'emp.noConnection': {'uz': 'Aloqa yo\'q', 'uzc': 'Алоқа йўқ', 'ru': 'Нет связи', 'en': 'No connection'},
  'emp.retry': {'uz': 'Qayta urinish', 'uzc': 'Қайта уриниш', 'ru': 'Повторить', 'en': 'Retry'},

  // ── Lavozimlar (API'dan o'zbekcha keladi) ──
  'pos.director': {'uz': 'Direktor', 'uzc': 'Директор', 'ru': 'Директор', 'en': 'Director'},
  'pos.chiefAcc': {'uz': 'Bosh buxgalter', 'uzc': 'Бош бухгалтер', 'ru': 'Главный бухгалтер', 'en': 'Chief accountant'},
  'pos.accountant': {'uz': 'Buxgalter', 'uzc': 'Бухгалтер', 'ru': 'Бухгалтер', 'en': 'Accountant'},
  'pos.manager': {'uz': 'Menejer', 'uzc': 'Менежер', 'ru': 'Менеджер', 'en': 'Manager'},
  'pos.specialist': {'uz': 'Mutaxassis', 'uzc': 'Мутахассис', 'ru': 'Специалист', 'en': 'Specialist'},
  'pos.operator': {'uz': 'Operator', 'uzc': 'Оператор', 'ru': 'Оператор', 'en': 'Operator'},
  'pos.cashier': {'uz': 'Kassir', 'uzc': 'Кассир', 'ru': 'Кассир', 'en': 'Cashier'},
  'pos.hr': {'uz': 'Kadrlar', 'uzc': 'Кадрлар', 'ru': 'Кадры', 'en': 'HR'},
};
