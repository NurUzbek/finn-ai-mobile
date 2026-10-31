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

  // ── Til tanlash (bottom sheet) ──
  'profile.langSheetTitle': {'uz': 'Ilova tili', 'uzc': 'Илова тили', 'ru': 'Язык приложения', 'en': 'App language'},

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

  // ── Shaxsiy ma'lumotlar (tahrirlash) ekrani ──
  'profile.editTitle': {'uz': "Shaxsiy ma'lumotlar", 'uzc': 'Шахсий маълумотлар', 'ru': 'Личные данные', 'en': 'Personal details'},
  'profile.editSub': {'uz': 'Hisob maʼlumotlarini tahrirlash', 'uzc': 'Ҳисоб маълумотларини таҳрирлаш', 'ru': 'Редактирование данных аккаунта', 'en': 'Edit your account details'},
  'profile.changePhoto': {'uz': "Rasmni o'zgartirish", 'uzc': 'Расмни ўзгартириш', 'ru': 'Изменить фото', 'en': 'Change photo'},
  'profile.photoSoon': {'uz': 'Rasm yuklash tez orada', 'uzc': 'Расм юклаш тез орада', 'ru': 'Загрузка фото скоро', 'en': 'Photo upload coming soon'},
  'profile.photoFormat': {'uz': 'Faqat PNG, JPG yoki HEIC rasm', 'uzc': 'Фақат PNG, JPG ёки HEIC расм', 'ru': 'Только PNG, JPG или HEIC', 'en': 'Only PNG, JPG or HEIC image'},
  'profile.photoUpdated': {'uz': 'Rasm yangilandi', 'uzc': 'Расм янгиланди', 'ru': 'Фото обновлено', 'en': 'Photo updated'},
  'profile.photoError': {'uz': 'Rasm yuklashda xato', 'uzc': 'Расм юклашда хато', 'ru': 'Ошибка загрузки', 'en': 'Upload error'},
  'profile.photoSource': {'uz': 'Rasm manbasi', 'uzc': 'Расм манбаси', 'ru': 'Источник фото', 'en': 'Photo source'},
  'profile.photoCamera': {'uz': 'Rasmga tushish', 'uzc': 'Расмга тушиш', 'ru': 'Сделать фото', 'en': 'Take a photo'},
  'profile.photoGallery': {'uz': 'Galereyadan tanlash', 'uzc': 'Галереядан танлаш', 'ru': 'Выбрать из галереи', 'en': 'Choose from gallery'},
  'profile.permCamera': {'uz': 'Kamera ruxsati berilmadi', 'uzc': 'Камера рухсати берилмади', 'ru': 'Нет доступа к камере', 'en': 'Camera permission denied'},
  'profile.permPhotos': {'uz': 'Galereya ruxsati berilmadi', 'uzc': 'Галерея рухсати берилмади', 'ru': 'Нет доступа к галерее', 'en': 'Gallery permission denied'},
  'profile.fieldName': {'uz': 'Ism va familiya', 'uzc': 'Исм ва фамилия', 'ru': 'Имя и фамилия', 'en': 'Name and surname'},
  'profile.fieldPhone': {'uz': 'Telefon raqam', 'uzc': 'Телефон рақам', 'ru': 'Номер телефона', 'en': 'Phone number'},
  'profile.fieldEmail': {'uz': 'Email', 'uzc': 'Email', 'ru': 'Email', 'en': 'Email'},
  'profile.fieldJshshir': {'uz': 'JSHSHIR', 'uzc': 'ЖШШИР', 'ru': 'ПИНФЛ', 'en': 'PINFL'},
  'profile.phoneLockHint': {'uz': "OneID orqali tasdiqlangan — bu yerda o'zgartirib bo'lmaydi", 'uzc': 'OneID орқали тасдиқланган — бу ерда ўзгартириб бўлмайди', 'ru': 'Подтверждено через OneID — изменить нельзя', 'en': 'Verified via OneID — cannot be changed here'},
  'profile.emailHint': {'uz': "To'lov muddati haqidagi xabarlar shu manzilga ham yuboriladi", 'uzc': 'Тўлов муддати ҳақидаги хабарлар шу манзилга ҳам юборилади', 'ru': 'Уведомления о сроках оплаты придут и на этот адрес', 'en': 'Payment reminders are also sent to this address'},
  'profile.save': {'uz': 'Saqlash', 'uzc': 'Сақлаш', 'ru': 'Сохранить', 'en': 'Save'},
  'profile.saved': {'uz': "Ma'lumotlar saqlandi", 'uzc': 'Маълумотлар сақланди', 'ru': 'Данные сохранены', 'en': 'Details saved'},
  'profile.nameRequired': {'uz': 'Ism va familiyani kiriting', 'uzc': 'Исм ва фамилияни киритинг', 'ru': 'Введите имя и фамилию', 'en': 'Enter name and surname'},
  'profile.saveError': {'uz': "Saqlashda xatolik. Qayta urinib ko'ring", 'uzc': 'Сақлашда хатолик. Қайта уриниб кўринг', 'ru': 'Ошибка сохранения. Попробуйте снова', 'en': 'Could not save. Try again'},

  // ── Aktiv qurilmalar ekrani ──
  'profile.thisDevice': {'uz': 'Bu qurilma', 'uzc': 'Бу қурилма', 'ru': 'Это устройство', 'en': 'This device'},
  'profile.devicesSub': {'uz': 'Hisobingizga kirgan qurilmalar', 'uzc': 'Ҳисобингизга кирган қурилмалар', 'ru': 'Устройства, вошедшие в аккаунт', 'en': 'Devices signed into your account'},
  'profile.deviceRevoke': {'uz': 'Chiqarish', 'uzc': 'Чиқариш', 'ru': 'Выйти', 'en': 'Sign out'},
  'profile.deviceRevoked': {'uz': 'Qurilma chiqarildi', 'uzc': 'Қурилма чиқарилди', 'ru': 'Устройство отключено', 'en': 'Device signed out'},
  'profile.deviceRevokeErr': {'uz': 'Chiqarib bo\'lmadi', 'uzc': 'Чиқариб бўлмади', 'ru': 'Не удалось', 'en': 'Could not sign out'},
  'profile.noDevices': {'uz': 'Faol qurilma yo\'q', 'uzc': 'Фаол қурилма йўқ', 'ru': 'Нет активных устройств', 'en': 'No active devices'},
  'profile.thisDeviceSub': {'uz': 'Hozir faol · joriy sessiya', 'uzc': 'Ҳозир фаол · жорий сессия', 'ru': 'Сейчас активно · текущая сессия', 'en': 'Active now · current session'},
  'profile.active': {'uz': 'Faol', 'uzc': 'Фаол', 'ru': 'Активно', 'en': 'Active'},
  'profile.devicesSoon': {'uz': "Boshqa qurilmalar ro'yxati tez orada", 'uzc': 'Бошқа қурилмалар рўйхати тез орада', 'ru': 'Список других устройств скоро', 'en': 'Other devices list coming soon'},

  // ── Versiya matni (footer) ──
  'profile.version': {'uz': 'FINN AI v1.3.1 · ONEDESK GROUP MChJ', 'uzc': 'FINN AI v1.3.1 · ONEDESK GROUP МЧЖ', 'ru': 'FINN AI v1.3.1 · ONEDESK GROUP ООО', 'en': 'FINN AI v1.3.1 · ONEDESK GROUP LLC'},
};
