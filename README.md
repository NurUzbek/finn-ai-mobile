# FINN AI — mobil ilova

**FINN AI** — O'zbekiston tadbirkorlari uchun soliq va hisobot muddatlarini
nazorat qiluvchi aqlli yordamchi. Qarzdorlik, penya, risk balli va hisobot
muddatlari — barchasi bitta ilovada.

> iOS va Android · yorug' va tungi rejim · 4 til

## Imkoniyatlar

- **Soliq qarzlari va penya** — real vaqtda hisoblanadigan qarz va jarima
- **Risk tahlili** — tashkilotning soliq riski balli va unga ta'sir etuvchi omillar
- **Hisobot muddatlari** — yaqinlashayotgan topshiriq muddatlari va kalendar
- **Ko'p tashkilot** — bir akkauntdan bir nechta firmani boshqarish
- **AI konsultant** — soliq va buxgalteriya bo'yicha yordamchi
- **OneID** orqali davlat autentifikatsiyasi va E-imzo bilan imzolash
- **Push bildirishnomalar** — muhim muddat va o'zgarishlar haqida

## Texnologiyalar

- **Flutter** (Dart) — iOS va Android uchun yagona kod bazasi
- **REST API** (`/api/v1`) — token asosidagi autentifikatsiya
- **Firebase Cloud Messaging** — push bildirishnomalar
- Yorug'/tungi rejim, mobil dizayn tizimi

## Platformalar

| Platforma | Holat |
|---|---|
| Android | APK / Google Play (sinov) |
| iOS | TestFlight / App Store (sinov) |

- Bundle ID: `uz.finn.app`
- Joriy talqin: **v1.2.1**

## Qurish

```bash
flutter pub get
flutter build apk --release      # Android
flutter build ios --release      # iOS
```

Batafsil: [`BUILD.md`](BUILD.md)

## Havolalar

- Veb-platforma: [finn.uz](https://finn.uz)
- Ilovani yuklab olish: [finn.uz/app](https://finn.uz/app)

---

© ONE DESK GROUP MChJ. Barcha huquqlar himoyalangan.
