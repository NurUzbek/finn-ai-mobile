import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Har bir ekran o'z tarjima katalogini shu papkada beradi (konfliktsiz parallel ishlash).
import '../i18n/common_tr.dart' as common;
import '../i18n/dashboard_tr.dart' as dashboard;
import '../i18n/organizations_tr.dart' as organizations;
import '../i18n/risk_tr.dart' as risk;
import '../i18n/tax_tr.dart' as tax;
import '../i18n/notifications_tr.dart' as notifications;
import '../i18n/profile_tr.dart' as profile;
import '../i18n/subscription_tr.dart' as subscription;
import '../i18n/login_tr.dart' as login;
import '../i18n/identity_tr.dart' as identity;
import '../i18n/currency_tr.dart' as currency;
import '../i18n/financial_tr.dart' as financial;
import '../i18n/wallet_tr.dart' as wallet;
import '../i18n/documents_tr.dart' as documents;
import '../i18n/didox_tr.dart' as didox;
import '../i18n/reports_tr.dart' as reports;
import '../i18n/calendar_tr.dart' as calendar;
import '../i18n/employees_tr.dart' as employees;
import '../i18n/team_tr.dart' as team;
import '../i18n/counterparty_tr.dart' as counterparty;
import '../i18n/audit_tr.dart' as audit;
import '../i18n/chat_tr.dart' as chat;
import '../i18n/enforcement_tr.dart' as enforcement;
import '../i18n/sources_tr.dart' as sources;

/// Ilova tili — foydalanuvchi tanlovi qurilmada saqlanadi.
/// Singleton (ThemeState kabi): notifyListeners bilan butun ilova qayta quriladi.
///
/// Tillar: uz (lotin), uzc (kirill), ru (rus), en (ingliz).
/// Rasmiy hujjat/soliq atamalari tarjima qilinmaydi — faqat interfeys.
class I18n extends ChangeNotifier {
  static final I18n i = I18n._();
  I18n._();

  static const _key = 'finn_lang';
  static const langs = ['uz', 'uzc', 'ru', 'en'];
  static const langNames = {
    'uz': 'O\'zbekcha',
    'uzc': 'Ўзбекча',
    'ru': 'Русский',
    'en': 'English',
  };
  static const langSub = {
    'uz': 'Lotin alifbosi',
    'uzc': 'Кирилл алифбоси',
    'ru': 'Russian',
    'en': 'Inglizcha',
  };

  String _lang = 'uz';
  String get lang => _lang;
  Locale get locale => Locale(_lang == 'uzc' ? 'uz' : _lang);

  // Barcha ekran kataloglari birlashtiriladi.
  static final Map<String, Map<String, String>> _catalog = {
    ...common.tr,
    ...dashboard.tr,
    ...organizations.tr,
    ...risk.tr,
    ...tax.tr,
    ...notifications.tr,
    ...profile.tr,
    ...subscription.tr,
    ...login.tr,
    ...identity.tr,
    ...currency.tr,
    ...financial.tr,
    ...wallet.tr,
    ...documents.tr,
    ...didox.tr,
    ...reports.tr,
    ...calendar.tr,
    ...employees.tr,
    ...team.tr,
    ...counterparty.tr,
    ...audit.tr,
    ...chat.tr,
    ...enforcement.tr,
    ...sources.tr,
  };

  /// Kalitni joriy tilga tarjima qiladi. Topilmasa — uz, u ham bo'lmasa — kalit.
  String t(String key) {
    final row = _catalog[key];
    if (row == null) return key;
    return row[_lang] ?? row['uz'] ?? key;
  }

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_key);
    if (v != null && langs.contains(v)) _lang = v;
    notifyListeners();
  }

  Future<void> setLang(String l) async {
    if (l == _lang || !langs.contains(l)) return;
    _lang = l;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, l);
  }
}

/// Global tarjima yordamchisi — `tr('key')`.
String tr(String key) => I18n.i.t(key);

/// API'dan keladigan hisobot turi nomini (DB'da o'zbekcha) joriy tilga o'giradi.
/// Apostrof/registr farqiga bardoshli. Topilmasa — asl matnni qaytaradi.
const Map<String, String> _reportTypeKeys = {
  'qqs deklaratsiyasi': 'rtype.vat',
  'qqs': 'rtype.vat',
  'foyda soligi': 'rtype.profit',
  'inps hisobot': 'rtype.inps',
  'inps': 'rtype.inps',
  'aylanma soliq': 'rtype.turnover',
  'hisobotlar': 'rtype.reports',
};

String trReport(String raw) {
  final norm = raw.trim().toLowerCase().replaceAll(RegExp("['ʻʼ`’]"), '');
  final k = _reportTypeKeys[norm];
  return k != null ? tr(k) : raw;
}

/// API'dan keladigan hisobot holatini (accepted/pending/…) joriy tilga o'giradi.
const Map<String, String> _reportStatusKeys = {
  'accepted': 'rep.pillAccepted',
  'pending': 'rep.pillPending',
  'submitted': 'rep.pillSubmitted',
  'rejected': 'rep.pillRejected',
  'overdue': 'rep.pillOverdue',
  'draft': 'rep.pillDraft',
  // Ijro/umumiy holatlar
  'active': 'status.active',
  'closed': 'status.closed',
  'open': 'status.open',
  'completed': 'status.completed',
  'paid': 'status.paid',
};

String trStatus(String raw) {
  final k = _reportStatusKeys[raw.trim().toLowerCase()];
  return k != null ? tr(k) : raw;
}

/// Xodim lavozimini (API'dan o'zbekcha) joriy tilga o'giradi.
const Map<String, String> _positionKeys = {
  'direktor': 'pos.director',
  'bosh buxgalter': 'pos.chiefAcc',
  'buxgalter': 'pos.accountant',
  'menejer': 'pos.manager',
  'mutaxassis': 'pos.specialist',
  'operator': 'pos.operator',
  'kassir': 'pos.cashier',
  'kadr': 'pos.hr',
};

String trPosition(String raw) {
  final k = _positionKeys[raw.trim().toLowerCase()];
  return k != null ? tr(k) : raw;
}

/// Moliyaviy operatsiya kategoriyasini joriy tilga o'giradi.
const Map<String, String> _txnCatKeys = {
  'soliq': 'cat.tax',
  'maosh': 'cat.salary',
  'transport': 'cat.transport',
  'ijara': 'cat.rent',
  'tovar': 'cat.goods',
  'mahsulot': 'cat.goods',
  'xizmat': 'cat.service',
  'kommunal': 'cat.utilities',
  'boshqa': 'cat.other',
};

String trTxnCat(String raw) {
  final k = _txnCatKeys[raw.trim().toLowerCase()];
  return k != null ? tr(k) : raw;
}
