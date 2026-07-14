import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ilova mavzusi (qorong'i / yorug') — foydalanuvchi tanlovi qurilmada saqlanadi.
/// Singleton: butun ilova bo'ylab bitta holat, `notifyListeners` bilan qayta quriladi.
class ThemeState extends ChangeNotifier {
  static final ThemeState i = ThemeState._();
  ThemeState._();

  static const _key = 'finn_theme';
  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  /// Saqlangan tanlovni ilova ochilishida yuklaydi.
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_key);
    _mode = switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, m == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> toggle() =>
      setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
