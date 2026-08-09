// Umumiy (butun ilova bo'ylab) tarjimalar — nav, tugmalar, holatlar, salomlar.
// Format: 'kalit': {'uz','uzc','ru','en'}.
const Map<String, Map<String, String>> tr = {
  // ── Navigatsiya ──
  'nav.home': {'uz': 'Asosiy', 'uzc': 'Асосий', 'ru': 'Главная', 'en': 'Home'},
  'nav.orgs': {'uz': 'Firmalar', 'uzc': 'Фирмалар', 'ru': 'Фирмы', 'en': 'Firms'},
  'nav.monitoring': {'uz': 'Monitoring', 'uzc': 'Мониторинг', 'ru': 'Мониторинг', 'en': 'Monitoring'},
  'nav.data': {'uz': 'Ma\'lumotlar', 'uzc': 'Маълумотлар', 'ru': 'Данные', 'en': 'Data'},
  'nav.risk': {'uz': 'Risk', 'uzc': 'Риск', 'ru': 'Риск', 'en': 'Risk'},
  'nav.tax': {'uz': 'Soliq', 'uzc': 'Солиқ', 'ru': 'Налог', 'en': 'Tax'},
  'nav.notif': {'uz': 'Xabar', 'uzc': 'Хабар', 'ru': 'Сообщ.', 'en': 'Alerts'},
  'nav.profile': {'uz': 'Profil', 'uzc': 'Профил', 'ru': 'Профиль', 'en': 'Profile'},

  // ── Umumiy tugma / harakatlar ──
  'common.details': {'uz': 'Batafsil', 'uzc': 'Батафсил', 'ru': 'Подробнее', 'en': 'Details'},
  'common.all': {'uz': 'Barchasi', 'uzc': 'Барчаси', 'ru': 'Все', 'en': 'All'},
  'common.retry': {'uz': 'Qayta urinish', 'uzc': 'Қайта уриниш', 'ru': 'Повторить', 'en': 'Retry'},
  'common.cancel': {'uz': 'Bekor qilish', 'uzc': 'Бекор қилиш', 'ru': 'Отмена', 'en': 'Cancel'},
  'common.save': {'uz': 'Saqlash', 'uzc': 'Сақлаш', 'ru': 'Сохранить', 'en': 'Save'},
  'common.select': {'uz': 'Tanlash', 'uzc': 'Танлаш', 'ru': 'Выбрать', 'en': 'Choose'},
  'common.review': {'uz': 'Ko\'rib chiqish', 'uzc': 'Кўриб чиқиш', 'ru': 'Просмотреть', 'en': 'Review'},
  'common.comingSoon': {'uz': 'Tez kunda', 'uzc': 'Тез кунда', 'ru': 'Скоро', 'en': 'Coming soon'},
  'common.som': {'uz': 'so\'m', 'uzc': 'сўм', 'ru': 'сум', 'en': 'so\'m'},
  'common.search': {'uz': 'Qidirish', 'uzc': 'Қидириш', 'ru': 'Поиск', 'en': 'Search'},
  'common.expand': {'uz': 'Kengaytirish', 'uzc': 'Кенгайтириш', 'ru': 'Расширить', 'en': 'Upgrade'},

  // ── Holatlar (bo'sh / xato / yuklanish) ──
  'state.noConnection': {'uz': 'Server bilan aloqa yo\'q', 'uzc': 'Сервер билан алоқа йўқ', 'ru': 'Нет связи с сервером', 'en': 'No server connection'},
  'state.loading': {'uz': 'Yuklanmoqda…', 'uzc': 'Юкланмоқда…', 'ru': 'Загрузка…', 'en': 'Loading…'},
  'state.error': {'uz': 'Xatolik yuz berdi', 'uzc': 'Хатолик юз берди', 'ru': 'Произошла ошибка', 'en': 'An error occurred'},

  // ── Salomlashish ──
  'greet.morning': {'uz': 'Xayrli tong', 'uzc': 'Хайрли тонг', 'ru': 'Доброе утро', 'en': 'Good morning'},
  'greet.day': {'uz': 'Xayrli kun', 'uzc': 'Хайрли кун', 'ru': 'Добрый день', 'en': 'Good afternoon'},
  'greet.evening': {'uz': 'Xayrli kech', 'uzc': 'Хайрли кеч', 'ru': 'Добрый вечер', 'en': 'Good evening'},

  // ── Barcha modullar oynasi (modules_sheet) ──
  'mods.all': {'uz': 'Barcha modullar', 'uzc': 'Барча модуллар', 'ru': 'Все модули', 'en': 'All modules'},
  // Bo'lim sarlavhalari (to'g'ridan-to'g'ri chiqadi — katta harf)
  'mods.secFinance': {'uz': 'MOLIYA', 'uzc': 'МОЛИЯ', 'ru': 'ФИНАНСЫ', 'en': 'FINANCE'},
  'mods.secDocuments': {'uz': 'HUJJATLAR', 'uzc': 'ҲУЖЖАТЛАР', 'ru': 'ДОКУМЕНТЫ', 'en': 'DOCUMENTS'},
  'mods.secBusiness': {'uz': 'BIZNES', 'uzc': 'БИЗНЕС', 'ru': 'БИЗНЕС', 'en': 'BUSINESS'},
  'mods.secControl': {'uz': 'NAZORAT', 'uzc': 'НАЗОРАТ', 'ru': 'КОНТРОЛЬ', 'en': 'CONTROL'},
  'mods.secAccount': {'uz': 'HISOB', 'uzc': 'ҲИСОБ', 'ru': 'АККАУНТ', 'en': 'ACCOUNT'},
  // TZ mobil modullari — bo'lim sarlavhalari
  'mods.secOrgs': {'uz': 'MENING TASHKILOTLARIM', 'uzc': 'МЕНИНГ ТАШКИЛОТЛАРИМ', 'ru': 'МОИ ОРГАНИЗАЦИИ', 'en': 'MY ORGANIZATIONS'},
  'mods.secMonitoring': {'uz': 'MONITORING', 'uzc': 'МОНИТОРИНГ', 'ru': 'МОНИТОРИНГ', 'en': 'MONITORING'},
  'mods.secData': {'uz': 'MA\'LUMOTLAR', 'uzc': 'МАЪЛУМОТЛАР', 'ru': 'ДАННЫЕ', 'en': 'DATA'},
  'mods.orgs': {'uz': 'Tashkilotlar', 'uzc': 'Ташкилотлар', 'ru': 'Организации', 'en': 'Organizations'},
  'mods.taxDebt': {'uz': 'Soliq va qarzdorlik', 'uzc': 'Солиқ ва қарздорлик', 'ru': 'Налог и задолженность', 'en': 'Tax & debt'},
  'mods.riskAnalysis': {'uz': 'Risk tahlili', 'uzc': 'Риск таҳлили', 'ru': 'Риск-анализ', 'en': 'Risk analysis'},
  // Modul yorliqlari
  'mods.income': {'uz': 'Kirim va chiqim', 'uzc': 'Кирим ва чиқим', 'ru': 'Приход и расход', 'en': 'Income & expense'},
  'mods.wallet': {'uz': 'Hamyon', 'uzc': 'Ҳамён', 'ru': 'Кошелёк', 'en': 'Wallet'},
  'mods.currencyRates': {'uz': 'Valyuta kurslari', 'uzc': 'Валюта курслари', 'ru': 'Курсы валют', 'en': 'Exchange rates'},
  'mods.documents': {'uz': 'Hujjatlar', 'uzc': 'Ҳужжатлар', 'ru': 'Документы', 'en': 'Documents'},
  'mods.didox': {'uz': 'E-hujjat (Didox)', 'uzc': 'Э-ҳужжат (Didox)', 'ru': 'Э-документ (Didox)', 'en': 'E-invoice (Didox)'},
  'mods.reports': {'uz': 'Hisobotlar', 'uzc': 'Ҳисоботлар', 'ru': 'Отчёты', 'en': 'Reports'},
  'mods.workCalendar': {'uz': 'Ish kalendari', 'uzc': 'Иш календари', 'ru': 'Рабочий календарь', 'en': 'Work calendar'},
  'mods.employees': {'uz': 'Xodimlar', 'uzc': 'Ходимлар', 'ru': 'Сотрудники', 'en': 'Employees'},
  'mods.team': {'uz': 'Jamoa va rollar', 'uzc': 'Жамоа ва роллар', 'ru': 'Команда и роли', 'en': 'Team & roles'},
  'mods.counterparties': {'uz': 'Kontragentlar', 'uzc': 'Контрагентлар', 'ru': 'Контрагенты', 'en': 'Counterparties'},
  'mods.audit': {'uz': 'Audit hisoboti', 'uzc': 'Аудит ҳисоботи', 'ru': 'Аудиторский отчёт', 'en': 'Audit report'},
  'mods.enforcement': {'uz': 'Ijro hujjatlari', 'uzc': 'Ижро ҳужжатлари', 'ru': 'Исполнительные документы', 'en': 'Enforcement documents'},
  'mods.subscription': {'uz': 'Obuna / Tarif', 'uzc': 'Обуна / Тариф', 'ru': 'Подписка / Тариф', 'en': 'Subscription / Plan'},

  // ── Umumiy holatlar (status) ──
  'status.active': {'uz': 'Faol', 'uzc': 'Фаол', 'ru': 'Активен', 'en': 'Active'},
  'status.closed': {'uz': 'Yopilgan', 'uzc': 'Ёпилган', 'ru': 'Закрыт', 'en': 'Closed'},
  'status.open': {'uz': 'Ochiq', 'uzc': 'Очиқ', 'ru': 'Открыт', 'en': 'Open'},
  'status.completed': {'uz': 'Yakunlangan', 'uzc': 'Якунланган', 'ru': 'Завершён', 'en': 'Completed'},
  'status.paid': {'uz': 'To\'langan', 'uzc': 'Тўланган', 'ru': 'Оплачен', 'en': 'Paid'},

  // ── Qo'shish formalari ──
  'add.finTitle': {'uz': 'Yangi operatsiya', 'uzc': 'Янги операция', 'ru': 'Новая операция', 'en': 'New operation'},
  'add.empTitle': {'uz': 'Yangi xodim', 'uzc': 'Янги ходим', 'ru': 'Новый сотрудник', 'en': 'New employee'},
  'add.orgTitle': {'uz': 'Yangi tashkilot', 'uzc': 'Янги ташкилот', 'ru': 'Новая организация', 'en': 'New organization'},
  'add.amount': {'uz': 'Summa', 'uzc': 'Сумма', 'ru': 'Сумма', 'en': 'Amount'},
  'add.category': {'uz': 'Kategoriya', 'uzc': 'Категория', 'ru': 'Категория', 'en': 'Category'},
  'add.note': {'uz': 'Izoh (ixtiyoriy)', 'uzc': 'Изоҳ (ихтиёрий)', 'ru': 'Примечание (необязательно)', 'en': 'Note (optional)'},
  'add.fullName': {'uz': 'To\'liq ism', 'uzc': 'Тўлиқ исм', 'ru': 'Полное имя', 'en': 'Full name'},
  'add.position': {'uz': 'Lavozim', 'uzc': 'Лавозим', 'ru': 'Должность', 'en': 'Position'},
  'add.orgName': {'uz': 'Tashkilot nomi', 'uzc': 'Ташкилот номи', 'ru': 'Название организации', 'en': 'Organization name'},
  'add.stir': {'uz': 'STIR (9 raqam)', 'uzc': 'СТИР (9 рақам)', 'ru': 'ИНН (9 цифр)', 'en': 'TIN (9 digits)'},
  'add.saved': {'uz': 'Qo\'shildi', 'uzc': 'Қўшилди', 'ru': 'Добавлено', 'en': 'Added'},
  'add.error': {'uz': 'Qo\'shishda xato', 'uzc': 'Қўшишда хато', 'ru': 'Ошибка добавления', 'en': 'Add error'},
  'add.required': {'uz': 'Maydonlarni to\'ldiring', 'uzc': 'Майдонларни тўлдиринг', 'ru': 'Заполните поля', 'en': 'Fill in the fields'},
};
