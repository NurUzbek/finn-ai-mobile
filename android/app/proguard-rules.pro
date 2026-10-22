# ═══════════════════════════════════════════════════════════════════
#  FINN AI — R8 / ProGuard qoidalari
#  Ekspertiza 2.2.7: kod obfuskatsiya qilinadi (sinf/metod nomlari
#  o'zgartiriladi, ishlatilmagan kod olib tashlanadi). Quyida faqat
#  reflection/JNI orqali chaqiriladigan, nomi O'ZGARMASLIGI shart bo'lgan
#  sinflar saqlanadi.
# ═══════════════════════════════════════════════════════════════════

# ── Flutter dvigateli va plagin ro'yxatdan o'tkazgichi ──
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Flutter deferred components (Play Core) — ilovada ishlatilmaydi.
-dontwarn com.google.android.play.core.**

# ── freeRASP (Talsec) — Flutter ↔ native ko'prik ──
# Plagin o'z qoidalarini consumerProguardFiles orqali bermaydi, shuning
# uchun MethodChannel ko'prigi bu yerda aniq saqlanadi. Talsec native
# kutubxonasi esa o'z obfuskatsiyasi va qoidalari bilan keladi.
-keep class com.aheaditec.freerasp.** { *; }
-dontwarn com.aheaditec.talsec.**

# ── Firebase Cloud Messaging ──
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.**

# ── flutter_secure_storage (EncryptedSharedPreferences / Tink) ──
-keep class androidx.security.crypto.** { *; }
-dontwarn com.google.crypto.tink.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

# ── Kotlin metama'lumotlari (reflection uchun) ──
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Stack trace'larda fayl/qator raqami — xatolarni tahlil qilish uchun
# (mapping.txt bilan qayta tiklanadi), lekin manba fayl nomi yashiriladi.
-keepattributes LineNumberTable
-renamesourcefileattribute SourceFile
