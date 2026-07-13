# FINN AI — mobil ilovani chiqarish (build) qo'llanmasi

App ID (ikkala platforma): **`uz.finn.app`** · Nomi: **FINN AI** · Versiya: `1.0.0+1`

---

## Android (tayyor)

APK shu serverda yig'iladi va yuklab olish sahifasida turadi:

- Yuklab olish: **https://finn.uz/app** (foydalanuvchi uchun)
- To'g'ridan APK: **https://finn.uz/app/finn.apk**

Qayta yig'ish:
```bash
cd mobile
flutter build apk --release          # APK (test/yon-yuklash)
flutter build appbundle --release    # AAB (Google Play uchun)
```

**Google Play'ga qo'yish uchun kerak:** Google Play Console akkaunti ($25, bir martalik)
+ release keystore (hozir debug-imzo). Keystore yaratilsa, `android/key.properties`
va `build.gradle.kts` signingConfig ulanadi.

---

## iOS (bulutli build — Mac KERAKMAS)

iOS `.ipa` ni faqat macOS'da yig'ish mumkin (Apple cheklovi). Shu server Linux
bo'lgani uchun **bulutli CI** ishlatamiz. Loyiha to'liq tayyor (bundle id, ikonka,
Face ID ruxsati, Info.plist).

### Variant A — Codemagic (tavsiya, eng oson)
1. `mobile/` papkani alohida Git repo qiling (GitHub/GitLab/Bitbucket).
2. https://codemagic.io — repo'ni ulang (bepul: oyiga 500 daqiqa macOS).
3. Ilova ichida `codemagic.yaml` bor — 3 workflow:
   - **android-release** — APK + AAB
   - **ios-release** — App Store .ipa (Apple akkaunt kerak)
   - **ios-unsigned** — imzosiz iOS build (Apple akkauntsiz ko'rish uchun)
4. Imzosiz iOS'ni ko'rish uchun **ios-unsigned** ni ishga tushiring — Apple akkauntsiz.

### Variant B — GitHub Actions (bepul muqobil)
`.github/workflows/build.yml` bor — push qilinganda Android + imzosiz iOS yig'iladi.

### App Store'ga rasman chiqarish uchun kerak
| Nima | Narx | Kim |
|------|------|-----|
| Apple Developer Program | $99/yil | Tashkilot nomidan ro'yxatdan o'tish |
| App Store Connect API key | bepul | Codemagic UI'ga ulanadi → avtomatik imzo |
| Ilova ikonasi 1024px | bor ✅ | `ios/Runner/Assets.xcassets` |

Apple akkaunt bo'lgach: Codemagic'da **ios-release** → avtomatik imzolab TestFlight'ga
yuklaydi → keyin App Store'ga "Submit for Review".

---

## Backend
Ikkala ilova ham `https://finn.uz/api/v1` (Sanctum Bearer token) bilan ishlaydi.
Alohida sozlash shart emas — ishlab turgan finn.uz'ga ulanadi.
