// login ekrani tarjimalari — telefon/SMS kirish + OneID oqimi.
// Format: 'kalit': {'uz','uzc','ru','en'}.
// Tarjima qilinmaydi: 'FINN', 'OneID', '+998', 'id.egov.uz', raqam formatlari.
const Map<String, Map<String, String>> tr = {
  // ── Telefon (kirish) ekrani ──
  'login.eyebrow': {'uz': 'FINN · SOLIQ MONITORING', 'uzc': 'FINN · СОЛИҚ МОНИТОРИНГ', 'ru': 'FINN · НАЛОГОВЫЙ МОНИТОРИНГ', 'en': 'FINN · TAX MONITORING'},
  'login.welcome': {'uz': 'Xush kelibsiz', 'uzc': 'Хуш келибсиз', 'ru': 'Добро пожаловать', 'en': 'Welcome'},
  'login.subtitle': {'uz': 'Telefon raqamingizni kiriting — SMS orqali tasdiqlash kodi yuboramiz.', 'uzc': 'Телефон рақамингизни киритинг — SMS орқали тасдиқлаш коди юборамиз.', 'ru': 'Введите номер телефона — мы отправим код подтверждения по SMS.', 'en': 'Enter your phone number — we\'ll send a verification code via SMS.'},
  'login.expired': {'uz': 'Harakatsizlik tufayli chiqarildingiz. Qaytadan kiring.', 'uzc': 'Ҳаракатсизлик туфайли чиқарилдингиз. Қайтадан киринг.', 'ru': 'Вы вышли из-за бездействия. Войдите снова.', 'en': 'You were logged out due to inactivity. Please sign in again.'},
  'login.phoneLabel': {'uz': 'Telefon raqam', 'uzc': 'Телефон рақам', 'ru': 'Номер телефона', 'en': 'Phone number'},
  'login.sendCode': {'uz': 'Kodni yuborish', 'uzc': 'Кодни юбориш', 'ru': 'Отправить код', 'en': 'Send code'},
  'login.or': {'uz': 'YOKI', 'uzc': 'ЁКИ', 'ru': 'ИЛИ', 'en': 'OR'},
  'login.oneidLogin': {'uz': 'OneID bilan kirish', 'uzc': 'OneID билан кириш', 'ru': 'Войти через OneID', 'en': 'Sign in with OneID'},
  'login.orgsAutoDetect': {'uz': 'Tashkilotlaringiz avtomatik aniqlanadi', 'uzc': 'Ташкилотларингиз автоматик аниқланади', 'ru': 'Ваши организации определятся автоматически', 'en': 'Your organizations will be detected automatically'},

  // ── Huquqiy matn (uch qism: matn / tagchiziqli havola / yakun) ──
  'login.legal1': {'uz': 'Davom etish orqali foydalanish shartlari va\n', 'uzc': 'Давом этиш орқали фойдаланиш шартлари ва\n', 'ru': 'Продолжая, вы принимаете условия использования и\n', 'en': 'By continuing, you accept the terms of use and\n'},
  'login.legalPrivacy': {'uz': 'maxfiylik siyosati', 'uzc': 'махфийлик сиёсати', 'ru': 'политику конфиденциальности', 'en': 'privacy policy'},
  'login.legal2': {'uz': 'ga rozilik bildirasiz.', 'uzc': 'га розилик билдирасиз.', 'ru': '.', 'en': '.'},

  // ── SMS (kod) ekrani ──
  'login.enterCode': {'uz': 'Kodni kiriting', 'uzc': 'Кодни киритинг', 'ru': 'Введите код', 'en': 'Enter the code'},
  'login.smsSentPrefix': {'uz': 'SMS ', 'uzc': 'SMS ', 'ru': 'SMS отправлен на номер ', 'en': 'SMS sent to '},
  'login.smsSentSuffix': {'uz': ' raqamiga yuborildi.', 'uzc': ' рақамига юборилди.', 'ru': '.', 'en': '.'},
  'login.verify': {'uz': 'Tasdiqlash', 'uzc': 'Тасдиқлаш', 'ru': 'Подтвердить', 'en': 'Verify'},
  'login.resend': {'uz': 'Qayta yuborish', 'uzc': 'Қайта юбориш', 'ru': 'Повторить', 'en': 'Resend'},
  'login.resendCode': {'uz': 'Kodni qayta yuborish', 'uzc': 'Кодни қайта юбориш', 'ru': 'Отправить код повторно', 'en': 'Resend code'},
  'login.otherNumber': {'uz': 'Boshqa raqam kiritish', 'uzc': 'Бошқа рақам киритиш', 'ru': 'Ввести другой номер', 'en': 'Enter a different number'},

  // ── Xatoliklar ──
  'login.errPhoneIncomplete': {'uz': 'Telefon raqamini to\'liq kiriting', 'uzc': 'Телефон рақамини тўлиқ киритинг', 'ru': 'Введите номер телефона полностью', 'en': 'Enter the full phone number'},
  'login.errWrongCode': {'uz': 'Kod noto\'g\'ri', 'uzc': 'Код нотўғри', 'ru': 'Неверный код', 'en': 'Incorrect code'},

  // ── OneID webview overlay ──
  'login.oneidSecure': {'uz': 'OneID orqali xavfsiz kirish', 'uzc': 'OneID орқали хавфсиз кириш', 'ru': 'Безопасный вход через OneID', 'en': 'Secure sign-in with OneID'},
  'login.oneidConnecting': {'uz': 'Davlat identifikatsiya tizimiga ulanmoqda', 'uzc': 'Давлат идентификация тизимига уланмоқда', 'ru': 'Подключение к государственной системе идентификации', 'en': 'Connecting to the state identification system'},
  'login.oneidLoggingIn': {'uz': 'Kirilmoqda…', 'uzc': 'Кирилмоқда…', 'ru': 'Выполняется вход…', 'en': 'Signing in…'},
  'login.oneidDetectingOrgs': {'uz': 'Tashkilotlaringiz aniqlanmoqda', 'uzc': 'Ташкилотларингиз аниқланмоқда', 'ru': 'Определяются ваши организации', 'en': 'Detecting your organizations'},
  'login.oneidPasswordNote': {'uz': 'Parol faqat id.egov.uz\'ga yuboriladi', 'uzc': 'Парол фақат id.egov.uz\'га юборилади', 'ru': 'Пароль отправляется только на id.egov.uz', 'en': 'Password is sent only to id.egov.uz'},
  'login.oneidFailed': {'uz': 'Ulanmadi', 'uzc': 'Уланмади', 'ru': 'Не удалось подключиться', 'en': 'Connection failed'},
  'login.errSlow': {'uz': 'Ulanish sekin — internetni tekshiring', 'uzc': 'Уланиш секин — интернетни текширинг', 'ru': 'Медленное соединение — проверьте интернет', 'en': 'Slow connection — check your internet'},
  'login.errPageFailed': {'uz': 'Sahifa ochilmadi — qayta urining', 'uzc': 'Саҳифа очилмади — қайта уриниб кўринг', 'ru': 'Страница не открылась — попробуйте снова', 'en': 'Page failed to load — please try again'},
  'login.errAuthIncomplete': {'uz': 'Kirish yakunlanmadi — qayta urining', 'uzc': 'Кириш якунланмади — қайта уриниб кўринг', 'ru': 'Вход не завершён — попробуйте снова', 'en': 'Sign-in not completed — please try again'},
};
