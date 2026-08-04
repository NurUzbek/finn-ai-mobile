// profile ekrani tarjimalari — nav.profile, common.cancel/save/expand qayta ishlatiladi.
// Format: 'kalit': {'uz','uzc','ru','en'}. {n}/{limit} — dinamik son (replaceAll bilan).
const Map<String, Map<String, String>> tr = {
  // ── Sarlavha ──
  'profile.headerSub': {'uz': 'Hisob va sozlamalar', 'uzc': 'Ҳисоб ва созламалар', 'ru': 'Аккаунт и настройки', 'en': 'Account & settings'},
  'profile.userFallback': {'uz': 'Foydalanuvchi', 'uzc': 'Фойдаланувчи', 'ru': 'Пользователь', 'en': 'User'},

  // ── Tarif kartasi ──
  'profile.planTrial': {'uz': 'Sinov rejimi', 'uzc': 'Синов режими', 'ru': 'Пробный режим', 'en': 'Trial mode'},
  'profile.planFree': {'uz': 'Bepul rejim', 'uzc': 'Бепул режим', 'ru': 'Бесплатный режим', 'en': 'Free mode'},
  'profile.planCurrent': {'uz': 'Joriy reja', 'uzc': 'Жорий режа', 'ru': 'Текущий план', 'en': 'Current plan'},
  'profile.orgsWatched': {'uz': '{n} ta firma kuzatilmoqda', 'uzc': '{n} та фирма кузатилмоқда', 'ru': 'отслеживается {n} фирм', 'en': '{n} firms monitored'},
  'profile.orgsWatchedLimit': {'uz': '{limit} tadan {n} ta firma kuzatilmoqda', 'uzc': '{limit} тадан {n} та фирма кузатилмоқда', 'ru': 'отслеживается {n} из {limit} фирм', 'en': '{n} of {limit} firms monitored'},

  // ── Bo'lim sarlavhalari ──
  'profile.secSettings': {'uz': 'Sozlamalar', 'uzc': 'Созламалар', 'ru': 'Настройки', 'en': 'Settings'},
  'profile.secSecurity': {'uz': 'Xavfsizlik', 'uzc': 'Хавфсизлик', 'ru': 'Безопасность', 'en': 'Security'},
  'profile.secAccount': {'uz': 'Hisob', 'uzc': 'Ҳисоб', 'ru': 'Аккаунт', 'en': 'Account'},

  // ── Sozlamalar satrlari ──
  'profile.theme': {'uz': 'Mavzu', 'uzc': 'Мавзу', 'ru': 'Тема', 'en': 'Theme'},
  'profile.themeLight': {'uz': "Yorug' rejim", 'uzc': 'Ёруғ режим', 'ru': 'Светлый режим', 'en': 'Light mode'},
  'profile.themeDark': {'uz': "Qorong'i rejim", 'uzc': 'Қоронғи режим', 'ru': 'Тёмный режим', 'en': 'Dark mode'},
  'profile.language': {'uz': 'Til', 'uzc': 'Тил', 'ru': 'Язык', 'en': 'Language'},
  'profile.push': {'uz': 'Push bildirishnoma', 'uzc': 'Push билдиришнома', 'ru': 'Push-уведомления', 'en': 'Push notifications'},
  'profile.pushSub': {'uz': "To'lov va risk haqida", 'uzc': 'Тўлов ва риск ҳақида', 'ru': 'О платежах и рисках', 'en': 'About payments & risk'},
  'profile.allModules': {'uz': 'Barcha modullar', 'uzc': 'Барча модуллар', 'ru': 'Все модули', 'en': 'All modules'},
  'profile.modulesSub': {'uz': "12 ta bo'lim", 'uzc': '12 та бўлим', 'ru': '12 разделов', 'en': '12 sections'},

  // ── Xavfsizlik satrlari ──
  'profile.faceId': {'uz': 'Face ID', 'uzc': 'Face ID', 'ru': 'Face ID', 'en': 'Face ID'},
  'profile.faceIdSub': {'uz': 'Ilovani ochishda', 'uzc': 'Иловани очишда', 'ru': 'При открытии приложения', 'en': 'On app open'},
  'profile.changePin': {'uz': "Parol kodini o'zgartirish", 'uzc': 'Парол кодини ўзгартириш', 'ru': 'Изменить код-пароль', 'en': 'Change passcode'},
  'profile.changePinSub': {'uz': '4 xonali kod', 'uzc': '4 хонали код', 'ru': '4-значный код', 'en': '4-digit code'},
  'profile.devices': {'uz': 'Aktiv qurilmalar', 'uzc': 'Актив қурилмалар', 'ru': 'Активные устройства', 'en': 'Active devices'},
  'profile.sessions': {'uz': '{n} ta faol sessiya', 'uzc': '{n} та фаол сессия', 'ru': '{n} активных сессий', 'en': '{n} active sessions'},
  'profile.sessionTimeout': {'uz': 'Sessiya muddati', 'uzc': 'Сессия муддати', 'ru': 'Время сессии', 'en': 'Session timeout'},
  'profile.sessionTimeoutSub': {'uz': '3 daqiqa harakatsizlik', 'uzc': '3 дақиқа ҳаракатсизлик', 'ru': '3 минуты бездействия', 'en': '3 min inactivity'},

  // ── Hisob satrlari ──
  'profile.email': {'uz': 'Email', 'uzc': 'Email', 'ru': 'Email', 'en': 'Email'},
  'profile.logout': {'uz': 'Chiqish', 'uzc': 'Чиқиш', 'ru': 'Выйти', 'en': 'Log out'},
  'profile.logoutConfirm': {'uz': 'Hisobingizdan chiqmoqchimisiz?', 'uzc': 'Ҳисобингиздан чиқмоқчимисиз?', 'ru': 'Выйти из аккаунта?', 'en': 'Log out of your account?'},

  // ── Snackbar / boshqa ──
  'profile.sessionToast': {'uz': 'Sessiya 3 daqiqa harakatsizlikda yopiladi', 'uzc': 'Сессия 3 дақиқа ҳаракатсизликда ёпилади', 'ru': 'Сессия закроется после 3 минут бездействия', 'en': 'Session closes after 3 min of inactivity'},
  'profile.bioUnavailable': {'uz': 'Qurilmada biometrika mavjud emas', 'uzc': 'Қурилмада биометрика мавжуд эмас', 'ru': 'Биометрия недоступна на устройстве', 'en': 'Biometrics not available on device'},

  // ── Aktiv qurilmalar ekrani ──
  'profile.thisDevice': {'uz': 'Bu qurilma', 'uzc': 'Бу қурилма', 'ru': 'Это устройство', 'en': 'This device'},
  'profile.thisDeviceSub': {'uz': 'Hozir faol · joriy sessiya', 'uzc': 'Ҳозир фаол · жорий сессия', 'ru': 'Сейчас активно · текущая сессия', 'en': 'Active now · current session'},
  'profile.active': {'uz': 'Faol', 'uzc': 'Фаол', 'ru': 'Активно', 'en': 'Active'},
  'profile.devicesSoon': {'uz': "Boshqa qurilmalar ro'yxati tez orada", 'uzc': 'Бошқа қурилмалар рўйхати тез орада', 'ru': 'Список других устройств скоро', 'en': 'Other devices list coming soon'},
};
