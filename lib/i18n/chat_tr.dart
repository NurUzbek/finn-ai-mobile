// chat ekrani (Finn AI suhbat) tarjimalari (uz/uzc/ru/en).
// Format: 'kalit': {'uz','uzc','ru','en'}.
// Eslatma: AI javobi va RAG manbalari API'dan keladi — tarjima qilinmaydi.
const Map<String, Map<String, String>> tr = {
  // Sarlavha — 'Finn AI' brend nomi barcha tillarda bir xil.
  'chat.title': {'uz': 'Finn AI', 'uzc': 'Finn AI', 'ru': 'Finn AI', 'en': 'Finn AI'},
  'chat.status': {
    'uz': 'On-premise · maxfiy',
    'uzc': 'On-premise · махфий',
    'ru': 'On-premise · конфиденциально',
    'en': 'On-premise · private',
  },

  // Welcome hero
  'chat.welcomeTitle': {
    'uz': 'Nima bilan boshlaymiz?',
    'uzc': 'Нима билан бошлаймиз?',
    'ru': 'С чего начнём?',
    'en': 'Where shall we start?',
  },
  'chat.welcomeDesc': {
    'uz': 'Firmalaringiz ma\'lumotiga qarab javob beraman. Umumiy maslahat emas — aniq raqam bilan.',
    'uzc': 'Фирмаларингиз маълумотига қараб жавоб бераман. Умумий маслаҳат эмас — аниқ рақам билан.',
    'ru': 'Отвечаю на основе данных ваших компаний. Не общий совет — с конкретными цифрами.',
    'en': 'I answer based on your companies\' data. Not general advice — with exact numbers.',
  },

  // Taklif chiplari (proto data-q) — 4 ta savol
  'chat.sugg1': {
    'uz': 'Qaysi to\'lovni birinchi yopay?',
    'uzc': 'Қайси тўловни биринчи ёпай?',
    'ru': 'Какой платёж закрыть первым?',
    'en': 'Which payment should I pay first?',
  },
  'chat.sugg2': {
    'uz': 'Risk ballim nega 22?',
    'uzc': 'Риск баллим нега 22?',
    'ru': 'Почему мой риск-балл 22?',
    'en': 'Why is my risk score 22?',
  },
  'chat.sugg3': {
    'uz': 'Bu oy qancha penya qo\'shildi?',
    'uzc': 'Бу ой қанча пеня қўшилди?',
    'ru': 'Сколько пени добавилось в этом месяце?',
    'en': 'How much penalty was added this month?',
  },
  'chat.sugg4': {
    'uz': 'Keyingi muddat qachon?',
    'uzc': 'Кейинги муддат қачон?',
    'ru': 'Когда следующий срок?',
    'en': 'When is the next deadline?',
  },

  // Kiritish paneli
  'chat.hint': {
    'uz': 'Savolingizni yozing',
    'uzc': 'Саволингизни ёзинг',
    'ru': 'Напишите ваш вопрос',
    'en': 'Type your question',
  },
  'chat.waiting': {
    'uz': 'Javob kutilyapti…',
    'uzc': 'Жавоб кутиляпти…',
    'ru': 'Ожидание ответа…',
    'en': 'Waiting for a reply…',
  },

  // Xato / qayta urinish
  'chat.error': {
    'uz': 'Javob olishda xatolik yuz berdi. Qayta urinib ko\'ring.',
    'uzc': 'Жавоб олишда хатолик юз берди. Қайта уриниб кўринг.',
    'ru': 'Произошла ошибка при получении ответа. Попробуйте ещё раз.',
    'en': 'An error occurred while getting a response. Please try again.',
  },
  'chat.retry': {
    'uz': 'Qayta urinish',
    'uzc': 'Қайта уриниш',
    'ru': 'Повторить',
    'en': 'Retry',
  },

  // RAG manba chip prefiksi
  'chat.source': {'uz': 'Manba:', 'uzc': 'Манба:', 'ru': 'Источник:', 'en': 'Source:'},
};
