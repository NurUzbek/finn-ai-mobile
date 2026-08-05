import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Interfeys ovozlari — menyu/tab bosilganda "pop" (suv pufakchasi) ovozi.
/// Web Audio sintezidan olingan namuna (assets/nav_pop.wav). Foydalanuvchi o'chira oladi.
/// Balandlik tabga qarab o'zgarmaydi — kuy chiqmaydi, faqat yumshoq tegish tovushi.
class Sfx {
  static final Sfx i = Sfx._();
  Sfx._();

  final AudioPlayer _player = AudioPlayer(playerId: 'finn_sfx')
    ..setReleaseMode(ReleaseMode.stop)
    ..setPlayerMode(PlayerMode.lowLatency);

  bool _enabled = true;
  bool get enabled => _enabled;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _enabled = sp.getBool('finn_sfx') ?? true;
    try {
      await _player.setSource(AssetSource('nav_pop.wav'));
    } catch (_) {}
  }

  Future<void> setEnabled(bool v) async {
    _enabled = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('finn_sfx', v);
  }

  /// Menyu bosilganda chalinadi (fire-and-forget).
  void pop() {
    if (!_enabled) return;
    () async {
      try {
        await _player.stop();
        await _player.play(AssetSource('nav_pop.wav'), volume: .55);
      } catch (_) {}
    }();
  }
}
