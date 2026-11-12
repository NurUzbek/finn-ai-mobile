// Davlat ma'lumotlari manbalari + "davlat organi emas" ogohlantirishi.
// Google Play Misleading Claims (2026-08-03) talabi: rasmiy manbaga havola va
// ilova davlat nomidan ish ko'rmasligi aniq ko'rinsin.
// Format: 'kalit': {'uz','uzc','ru','en'}.
const Map<String, Map<String, String>> tr = {
  'src.disclaimerTitle': {'uz': 'Davlat organi emas', 'uzc': 'Давлат органи эмас', 'ru': 'Не является госорганом', 'en': 'Not a government app'},
  'src.disclaimer': {
    'uz': "FINN AI — «ONEDESK GROUP» MChJ'ning mustaqil xususiy ilovasi. Davlat organi emas, davlat muassasalari nomidan ish ko'rmaydi va davlat xizmatlarini ko'rsatmaydi. Ma'lumotlar ma'lumot uchun beriladi — rasmiy ma'lumotni manbalarda tekshiring.",
    'uzc': "FINN AI — «ONEDESK GROUP» МЧЖнинг мустақил хусусий иловаси. Давлат органи эмас, давлат муассасалари номидан иш кўрмайди ва давлат хизматларини кўрсатмайди. Маълумотлар маълумот учун берилади — расмий маълумотни манбаларда текширинг.",
    'ru': 'FINN AI — независимое частное приложение «ONEDESK GROUP» MChJ. Не является госорганом, не представляет государственные учреждения и не оказывает госуслуги. Данные носят справочный характер — официальную информацию проверяйте в первоисточниках.',
    'en': 'FINN AI is an independent private app by ONEDESK GROUP LLC. It is not a government entity, does not represent government agencies and does not provide government services. Data is for reference only — verify official information at the original sources.',
  },
  'src.title': {'uz': "Ma'lumot manbalari", 'uzc': 'Маълумот манбалари', 'ru': 'Источники информации', 'en': 'Information sources'},
  'src.rowSub': {'uz': "Rasmiy saytlar va ogohlantirish", 'uzc': 'Расмий сайтлар ва огоҳлантириш', 'ru': 'Официальные сайты и дисклеймер', 'en': 'Official websites and disclaimer'},
  'src.sheetIntro': {
    'uz': "Soliq qo'mitasi va MIB bilan integratsiya ulanish bosqichida. Hozircha muddatlar va hisob-kitoblar Soliq kodeksi (lex.uz) asosida beriladi. Rasmiy ma'lumotni my.soliq.uz va mib.uz da tekshiring. Yuridik ahamiyatga ega ma'lumot — quyidagi rasmiy saytlarda.",
    'uzc': "Солиқ қўмитаси ва МИБ билан интеграция уланиш босқичида. Ҳозирча муддатлар ва ҳисоб-китоблар Солиқ кодекси (lex.uz) асосида берилади. Расмий маълумотни my.soliq.uz ва mib.uz да текширинг. Юридик аҳамиятга эга маълумот — қуйидаги расмий сайтларда.",
    'ru': 'Интеграция с налоговым комитетом и Бюро принудительного исполнения находится на этапе подключения. Пока сроки и расчёты приводятся на основе Налогового кодекса (lex.uz). Официальные сведения проверяйте на my.soliq.uz и mib.uz. Юридически значимая информация — на официальных сайтах ниже.',
    'en': 'Integration with the Tax Committee and the Enforcement Bureau is being connected. For now, deadlines and calculations are based on the Tax Code (lex.uz). Verify official information at my.soliq.uz and mib.uz. Legally binding information is on the official websites below.',
  },
  'src.more': {'uz': 'Manbalar', 'uzc': 'Манбалар', 'ru': 'Источники', 'en': 'Sources'},
  'src.footer': {'uz': 'Manba: rasmiy davlat saytlari · FINN davlat organi emas', 'uzc': 'Манба: расмий давлат сайтлари · FINN давлат органи эмас', 'ru': 'Источник: официальные госсайты · FINN не является госорганом', 'en': 'Source: official government websites · FINN is not a government app'},

  // Manbalar ro'yxati
  'src.soliq': {'uz': "Davlat soliq qo'mitasi", 'uzc': 'Давлат солиқ қўмитаси', 'ru': 'Государственный налоговый комитет', 'en': 'State Tax Committee'},
  'src.mysoliq': {'uz': "Soliq to'lovchining shaxsiy kabineti", 'uzc': 'Солиқ тўловчининг шахсий кабинети', 'ru': 'Персональный кабинет налогоплательщика', 'en': 'Taxpayer personal account'},
  'src.oneid': {'uz': 'OneID identifikatsiya tizimi', 'uzc': 'OneID идентификация тизими', 'ru': 'Система идентификации OneID', 'en': 'OneID identification system'},
  'src.mib': {'uz': 'Majburiy ijro byurosi', 'uzc': 'Мажбурий ижро бюроси', 'ru': 'Бюро принудительного исполнения', 'en': 'Bureau of Compulsory Enforcement'},
  'src.cbu': {'uz': 'Markaziy bank (valyuta kurslari)', 'uzc': 'Марказий банк (валюта курслари)', 'ru': 'Центральный банк (курсы валют)', 'en': 'Central Bank (exchange rates)'},
  'src.lex': {'uz': "Qonunchilik ma'lumotlari milliy bazasi", 'uzc': 'Қонунчилик маълумотлари миллий базаси', 'ru': 'Национальная база законодательства', 'en': 'National Database of Legislation'},
  // "Ilova haqida va manbalar" ekrani
  'src.aboutTitle': {'uz': 'Ilova haqida va manbalar', 'uzc': 'Илова ҳақида ва манбалар', 'ru': 'О приложении и источники', 'en': 'About the app and sources'},
  'src.developer': {'uz': "Ishlab chiquvchi: «ONEDESK GROUP» MChJ (xususiy kompaniya)", 'uzc': 'Ишлаб чиқувчи: «ONEDESK GROUP» МЧЖ (хусусий компания)', 'ru': 'Разработчик: «ONEDESK GROUP» MChJ (частная компания)', 'en': 'Developer: ONEDESK GROUP LLC (private company)'},
  'src.einvoice': {
    'uz': "Elektron hisob-fakturalar sizning akkauntingiz orqali litsenziyalangan xususiy EDO operatori Didox (didox.uz) dan olinadi. Didox ham davlat organi emas.",
    'uzc': "Электрон ҳисоб-фактуралар сизнинг аккаунтингиз орқали лицензияланган хусусий ЭДО оператори Didox (didox.uz) дан олинади. Didox ҳам давлат органи эмас.",
    'ru': 'Электронные счета-фактуры загружаются через ваш аккаунт у лицензированного частного оператора ЭДО Didox (didox.uz). Didox также не является госорганом.',
    'en': 'E-invoices are loaded through your own account with Didox (didox.uz), a licensed private e-document operator. Didox is not a government entity either.',
  },
  'src.webPage': {'uz': "Batafsil sayt sahifasida", 'uzc': 'Батафсил сайт саҳифасида', 'ru': 'Подробнее на сайте', 'en': 'More on our website'},
  'src.innNote': {
    'uz': "STIR bo'yicha ma'lumot ma'lumot uchun beriladi. FINN davlat organi emas — rasmiy ma'lumotni soliq.uz da tekshiring.",
    'uzc': "СТИР бўйича маълумот маълумот учун берилади. FINN давлат органи эмас — расмий маълумотни soliq.uz да текширинг.",
    'ru': 'Данные по ИНН носят справочный характер. FINN не является госорганом — официальные сведения проверяйте на soliq.uz.',
    'en': 'Data by TIN is for reference only. FINN is not a government app — verify official data at soliq.uz.',
  },
  // Demo integratsiya belgisi
  'demo.title': {'uz': "Namunaviy ma'lumot", 'uzc': 'Намунавий маълумот', 'ru': 'Демонстрационные данные', 'en': 'Sample data'},
  'demo.soliq': {
    'uz': "Soliq qo'mitasi bilan integratsiya ulanmoqda. Bu yerdagi soliq ma'lumotlari namunaviy — rasmiy ma'lumotni my.soliq.uz da tekshiring.",
    'uzc': "Солиқ қўмитаси билан интеграция уланмоқда. Бу ердаги солиқ маълумотлари намунавий — расмий маълумотни my.soliq.uz да текширинг.",
    'ru': 'Интеграция с налоговым комитетом подключается. Налоговые данные здесь демонстрационные — официальные сведения проверяйте на my.soliq.uz.',
    'en': 'Integration with the Tax Committee is being connected. Tax data here is sample data — verify official information at my.soliq.uz.',
  },
  'demo.mib': {
    'uz': "MIB bilan integratsiya ulanmoqda. Bu yerdagi ijro ma'lumotlari namunaviy — rasmiy ma'lumotni mib.uz da tekshiring.",
    'uzc': "МИБ билан интеграция уланмоқда. Бу ердаги ижро маълумотлари намунавий — расмий маълумотни mib.uz да текширинг.",
    'ru': 'Интеграция с Бюро принудительного исполнения подключается. Данные об исполнении здесь демонстрационные — официальные сведения проверяйте на mib.uz.',
    'en': 'Integration with the Enforcement Bureau is being connected. Enforcement data here is sample data — verify official information at mib.uz.',
  },
  'demo.both': {
    'uz': "Soliq qo'mitasi va MIB bilan integratsiya ulanmoqda. Bu yerdagi soliq va ijro ma'lumotlari namunaviy — rasmiy ma'lumotni my.soliq.uz va mib.uz da tekshiring.",
    'uzc': "Солиқ қўмитаси ва МИБ билан интеграция уланмоқда. Бу ердаги солиқ ва ижро маълумотлари намунавий — расмий маълумотни my.soliq.uz ва mib.uz да текширинг.",
    'ru': 'Интеграция с налоговым комитетом и Бюро принудительного исполнения подключается. Налоговые данные и данные об исполнении здесь демонстрационные — официальные сведения проверяйте на my.soliq.uz и mib.uz.',
    'en': 'Integration with the Tax Committee and the Enforcement Bureau is being connected. Tax and enforcement data here is sample data — verify official information at my.soliq.uz and mib.uz.',
  },
};
