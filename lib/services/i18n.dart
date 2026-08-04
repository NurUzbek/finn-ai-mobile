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
