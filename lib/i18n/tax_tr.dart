// tax ekrani tarjimalari — 4 til (uz, uzc, ru, en).
// tax_type qiymatlari API'dan keladi — tarjima qilinmaydi.
const Map<String, Map<String, String>> tr = {
  // ── Header ──
  'tax.header': {'uz': 'Soliq qarzi', 'uzc': 'Солиқ қарзи', 'ru': 'Налоговая задолженность', 'en': 'Tax debt'},
  'tax.subtitle': {'uz': 'Penya real vaqtda hisoblanadi', 'uzc': 'Пеня реал вақтда ҳисобланади', 'ru': 'Пеня рассчитывается в реальном времени', 'en': 'Penalty is calculated in real time'},

  // ── Umumiy sarhisob ──
  'tax.totalDebt': {'uz': 'Umumiy qarz', 'uzc': 'Умумий қарз', 'ru': 'Общий долг', 'en': 'Total debt'},
  'tax.totalPenalty': {'uz': 'Jami penya', 'uzc': 'Жами пеня', 'ru': 'Итого пеня', 'en': 'Total penalty'},
  'tax.dailyAdd': {'uz': 'Har kuni qo\'shilmoqda', 'uzc': 'Ҳар куни қўшилмоқда', 'ru': 'Добавляется ежедневно', 'en': 'Added daily'},

  // ── Eyebrow / saralash ──
  'tax.eyebrow': {'uz': 'MUDDAT BO\'YICHA', 'uzc': 'МУДДАТ БЎЙИЧА', 'ru': 'ПО СРОКУ', 'en': 'BY DEADLINE'},
  'tax.sort': {'uz': 'Saralash', 'uzc': 'Саралаш', 'ru': 'Сортировка', 'en': 'Sort'},

  // ── Karta: tri-label ──
  'tax.debt': {'uz': 'Qarz', 'uzc': 'Қарз', 'ru': 'Долг', 'en': 'Debt'},
  'tax.penalty': {'uz': 'Penya', 'uzc': 'Пеня', 'ru': 'Пеня', 'en': 'Penalty'},
  'tax.daily': {'uz': 'Kuniga', 'uzc': 'Кунига', 'ru': 'В день', 'en': 'Per day'},

  // ── Karta: pill / muddat (faqat so'z tarjima qilinadi, raqam/sana Dart'da) ──
  'tax.daysWord': {'uz': 'kun', 'uzc': 'кун', 'ru': 'дн.', 'en': 'days'},
  'tax.dueLabel': {'uz': 'Muddat', 'uzc': 'Муддат', 'ru': 'Срок', 'en': 'Due'},

  // ── Bo'sh holat ──
  'tax.emptyState': {'uz': 'Soliq qarzi yo\'q — hammasi toza', 'uzc': 'Солиқ қарзи йўқ — ҳаммаси тоза', 'ru': 'Нет налоговой задолженности — всё чисто', 'en': 'No tax debt — all clear'},
};
