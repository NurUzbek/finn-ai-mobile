import 'package:flutter/foundation.dart';
import 'api.dart';

/// Joriy tarif va uning imkoniyatlari. Ilova ochilganda bir marta yuklanadi,
/// bo'limlar shunga qarab ochiq yoki qulflangan ko'rinadi.
class PlanState extends ChangeNotifier {
  static final PlanState i = PlanState._();
  PlanState._();

  String slug = 'free';
  String name = '—';
  bool isTrial = false;
  int? daysLeft;
  String? endsAt;
  String upgradeUrl = 'https://finn.uz/subscription';
  Map<String, dynamic> features = {};
  bool loaded = false;

  bool has(String key) => features[key] == true;

  Future<void> load() async {
    final r = await Api.plan();
    if (r['ok'] == true && r['plan'] != null) {
      final p = r['plan'] as Map<String, dynamic>;
      slug = p['slug'] ?? 'free';
      name = p['name'] ?? '—';
      isTrial = p['is_trial'] == true;
      daysLeft = p['days_left'];
      endsAt = p['ends_at'];
      upgradeUrl = p['upgrade_url'] ?? upgradeUrl;
      features = Map<String, dynamic>.from(p['features'] ?? {});
    }
    loaded = true;
    notifyListeners();
  }

  void clear() {
    slug = 'free'; name = '—'; isTrial = false; daysLeft = null;
    features = {}; loaded = false;
    notifyListeners();
  }
}
