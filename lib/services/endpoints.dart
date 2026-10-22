/// Server manzillari (ekspertiza 2.2.7 — «Xavfsiz bo'lmagan havolalar»).
///
/// Manzillar kodda ochiq matn holida yozilmaydi: ular XOR bilan kodlangan va
/// faqat ishga tushganda tiklanadi. Shu sababli ilova faylini satr bo'yicha
/// qidirib (`strings libapp.so | grep finn.uz`) endpoint'larni topib bo'lmaydi.
///
/// Eslatma: API manzilini ilovadan TO'LIQ yashirishning imkoni yo'q — u tarmoq
/// trafigida baribir ko'rinadi. Bu chora (R8/ProGuard + Dart obfuskatsiyasi
/// bilan birga) tahlil qilish xarajatini oshiradi. Asosiy himoya — SSL pinning
/// (pinned_http.dart) va RASP (security.dart).
class Ep {
  Ep._();

  static const List<int> _k = [42, 57, 92, 78, 36, 121, 218, 55, 225, 87, 182, 161, 167, 90, 62, 118];

  static String _d(List<int> b) =>
      String.fromCharCodes([for (var i = 0; i < b.length; i++) b[i] ^ _k[i % _k.length]]);

  /// https://finn.uz
  static final String origin = _d(const [66, 77, 40, 62, 87, 67, 245, 24, 135, 62, 216, 207, 137, 47, 68]);

  /// https://finn.uz/api/v1
  static final String api = origin + _d(const [5, 88, 44, 39, 11, 15, 235]);

  /// /profile/avatar
  static final String avatar = _d(const [5, 73, 46, 33, 66, 16, 182, 82, 206, 54, 192, 192, 211, 59, 76]);

  /// /auth/oneid
  static final String _oneid = _d(const [5, 88, 41, 58, 76, 86, 181, 89, 132, 62, 210]);

  /// ?app=1
  static final String _appFlag = _d(const [21, 88, 44, 62, 25, 72]);

  /// /m-token
  static final String _mtoken = _d(const [5, 84, 113, 58, 75, 18, 191, 89]);

  /// /subscription
  static final String _subscription = _d(const [5, 74, 41, 44, 87, 26, 168, 94, 145, 35, 223, 206, 201]);

  /// OneID kirish (veb-oqim).
  static String get oneid => origin + _oneid;

  /// OneID kirish — ilova uchun (deep link qaytaradi).
  static String get oneidApp => origin + _oneid + _appFlag;

  /// Veb-sessiyadan mobil token olish sahifasi.
  static String get mtoken => origin + _mtoken;

  /// Tarifni yangilash sahifasi.
  static String get subscription => origin + _subscription;
}
