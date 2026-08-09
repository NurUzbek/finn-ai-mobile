// counterparty ekrani tarjimalari (uz/uzc/ru/en).
// Format: 'kalit': {'uz','uzc','ru','en'}. Raqam/API qiymatlari tarjima qilinmaydi.
const Map<String, Map<String, String>> tr = {
  // ── Sarlavha ──
  'cp.title': {'uz': 'Kontragentlar', 'uzc': 'Контрагентлар', 'ru': 'Контрагенты', 'en': 'Counterparties'},
  'cp.subtitle': {'uz': 'STIR bo\'yicha risk tekshiruvlari', 'uzc': 'СТИР бўйича риск текширувлари', 'ru': 'Проверки рисков по ИНН', 'en': 'Risk checks by TIN'},

  // ── Sarlavha ostidagi hisob: "N ta · M tasi risk ro'yxatida" ──
  'cp.count': {'uz': 'ta', 'uzc': 'та', 'ru': 'шт.', 'en': 'total'},
  'cp.inRiskList': {'uz': 'tasi risk ro\'yxatida', 'uzc': 'таси риск рўйхатида', 'ru': 'в списке рисков', 'en': 'in risk list'},

  // ── Qidiruv ──
  'cp.search.hint': {'uz': 'STIR yoki nom bo\'yicha qidirish', 'uzc': 'СТИР ёки ном бўйича қидириш', 'ru': 'Поиск по ИНН или названию', 'en': 'Search by TIN or name'},

  // ── Chiplar ──
  'cp.chip.all': {'uz': 'Hammasi', 'uzc': 'Ҳаммаси', 'ru': 'Все', 'en': 'All'},
  'cp.chip.risky': {'uz': 'Riskli', 'uzc': 'Рискли', 'ru': 'Рискованные', 'en': 'Risky'},
  'cp.chip.supplier': {'uz': 'Yetkazuvchi', 'uzc': 'Етказувчи', 'ru': 'Поставщик', 'en': 'Supplier'},
  'cp.chip.buyer': {'uz': 'Xaridor', 'uzc': 'Харидор', 'ru': 'Покупатель', 'en': 'Buyer'},

  // ── Guruh sarlavhalari (eyebrow) ──
  'cp.group.attention': {'uz': 'Diqqat talab qiladi', 'uzc': 'Диққат талаб қилади', 'ru': 'Требуют внимания', 'en': 'Needs attention'},
  'cp.group.trusted': {'uz': 'Ishonchli', 'uzc': 'Ишончли', 'ru': 'Надёжные', 'en': 'Trusted'},

  // ── Risk yorlig'i (pill) ──
  'cp.risk.high': {'uz': 'Yuqori risk', 'uzc': 'Юқори риск', 'ru': 'Высокий риск', 'en': 'High risk'},
  'cp.risk.attention': {'uz': 'E\'tibor', 'uzc': 'Эътибор', 'ru': 'Внимание', 'en': 'Attention'},
  'cp.risk.clean': {'uz': 'Toza', 'uzc': 'Тоза', 'ru': 'Чистый', 'en': 'Clean'},
  'cp.risk.unknown': {'uz': 'Noma\'lum', 'uzc': 'Номаълум', 'ru': 'Неизвестно', 'en': 'Unknown'},

  // ── Bo'sh holat ──
  'cp.empty.notFound': {'uz': 'Mos kontragent topilmadi', 'uzc': 'Мос контрагент топилмади', 'ru': 'Подходящий контрагент не найден', 'en': 'No matching counterparty found'},
  'cp.empty.none': {'uz': 'Hozircha tekshiruv yo\'q', 'uzc': 'Ҳозирча текширув йўқ', 'ru': 'Пока нет проверок', 'en': 'No checks yet'},

  // ── Xato holati ──
  'cp.err.offline': {'uz': 'Aloqa yo\'q', 'uzc': 'Алоқа йўқ', 'ru': 'Нет связи', 'en': 'No connection'},
  'cp.err.retry': {'uz': 'Qayta urinish', 'uzc': 'Қайта уриниш', 'ru': 'Повторить', 'en': 'Retry'},

  // ── STIR prefiksi (qatorda) ──
  'cp.stir': {'uz': 'STIR', 'uzc': 'СТИР', 'ru': 'ИНН', 'en': 'TIN'},
};
