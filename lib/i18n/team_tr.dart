// team ekrani (Jamoa va rollar) tarjimalari — 'team.' fazosi (uz/uzc/ru/en).
// Format: 'kalit': {'uz','uzc','ru','en'}. Sonlar interpolatsiya kalitdan tashqarida.
const Map<String, Map<String, String>> tr = {
  // ── Sarlavha ──
  'team.title': {'uz': 'Jamoa va rollar', 'uzc': 'Жамоа ва роллар', 'ru': 'Команда и роли', 'en': 'Team & roles'},
  'team.subtitle': {'uz': 'Foydalanuvchilar va ruxsatlar', 'uzc': 'Фойдаланувчилар ва рухсатлар', 'ru': 'Пользователи и права', 'en': 'Users and permissions'},

  // ── Subtitle sonli qism: "N foydalanuvchi · M rol" ──
  'team.usersWord': {'uz': 'foydalanuvchi', 'uzc': 'фойдаланувчи', 'ru': 'пользователей', 'en': 'users'},
  'team.rolesWord': {'uz': 'rol', 'uzc': 'рол', 'ru': 'ролей', 'en': 'roles'},

  // ── Rol nomlari (pil / avatar) ──
  'team.role.owner': {'uz': 'Egasi', 'uzc': 'Эгаси', 'ru': 'Владелец', 'en': 'Owner'},
  'team.role.admin': {'uz': 'Administrator', 'uzc': 'Администратор', 'ru': 'Администратор', 'en': 'Administrator'},
  'team.role.accountant': {'uz': 'Buxgalter', 'uzc': 'Бухгалтер', 'ru': 'Бухгалтер', 'en': 'Accountant'},
  'team.role.observer': {'uz': 'Kuzatuvchi', 'uzc': 'Кузатувчи', 'ru': 'Наблюдатель', 'en': 'Observer'},
  'team.role.member': {'uz': 'A\'zo', 'uzc': 'Аъзо', 'ru': 'Участник', 'en': 'Member'},

  // ── Bo'lim sarlavhalari (eyebrow) ──
  'team.usersSection': {'uz': 'Foydalanuvchilar', 'uzc': 'Фойдаланувчилар', 'ru': 'Пользователи', 'en': 'Users'},
  'team.rolesSection': {'uz': 'Rollar', 'uzc': 'Роллар', 'ru': 'Роли', 'en': 'Roles'},

  // ── Holatlar ──
  'team.unknown': {'uz': 'Noma\'lum', 'uzc': 'Номаълум', 'ru': 'Неизвестно', 'en': 'Unknown'},
  'team.emptyMembers': {'uz': 'Jamoa a\'zolari yo\'q', 'uzc': 'Жамоа аъзолари йўқ', 'ru': 'Нет участников команды', 'en': 'No team members'},
  'team.noConnection': {'uz': 'Aloqa yo\'q', 'uzc': 'Алоқа йўқ', 'ru': 'Нет связи', 'en': 'No connection'},
  'team.retry': {'uz': 'Qayta urinish', 'uzc': 'Қайта уриниш', 'ru': 'Повторить', 'en': 'Retry'},

  // ── Taklif qilish qatori ──
  'team.invite': {'uz': 'Foydalanuvchi taklif qilish', 'uzc': 'Фойдаланувчи таклиф қилиш', 'ru': 'Пригласить пользователя', 'en': 'Invite user'},
  'team.inviteSub': {'uz': 'SMS orqali havola yuboriladi', 'uzc': 'СМС орқали ҳавола юборилади', 'ru': 'Ссылка будет отправлена по SMS', 'en': 'A link will be sent via SMS'},

  // ── Rollar kartasi (ta'riflar) ──
  'team.roleDef.ownerDesc': {
    'uz': 'Barcha huquqlar · to\'lov va o\'chirish',
    'uzc': 'Барча ҳуқуқлар · тўлов ва ўчириш',
    'ru': 'Все права · оплата и удаление',
    'en': 'All permissions · billing and deletion'
  },
  'team.roleDef.accountantDesc': {
    'uz': 'Hujjat, hisobot, faktura · to\'lovsiz',
    'uzc': 'Ҳужжат, ҳисобот, фактура · тўловсиз',
    'ru': 'Документы, отчёты, счета · без оплаты',
    'en': 'Documents, reports, invoices · no billing'
  },
  'team.roleDef.observerDesc': {
    'uz': 'Faqat ko\'rish · o\'zgartira olmaydi',
    'uzc': 'Фақат кўриш · ўзгартира олмайди',
    'ru': 'Только просмотр · без изменений',
    'en': 'View only · cannot modify'
  },

  // ── Audit izohi ──
  'team.auditNote': {
    'uz': 'Har bir foydalanuvchining harakati audit jurnalida saqlanadi.',
    'uzc': 'Ҳар бир фойдаланувчининг ҳаракати аудит журналида сақланади.',
    'ru': 'Действия каждого пользователя сохраняются в журнале аудита.',
    'en': 'Every user\'s actions are recorded in the audit log.'
  },
};
