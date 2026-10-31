import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release imzo — android/key.properties (git'ga kirmaydi, CI'da secret'dan yoziladi).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "uz.finn.finn_ai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"  // plaginlar (webview, local_auth, ...) talab qiladigan eng yuqori NDK

    compileOptions {
        // flutter_local_notifications uchun majburiy (Java 8+ API'lar eski Android'da)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "uz.finn.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26   // TZ: Android 8.0+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Faqat haqiqiy telefon arxitekturalari. x86_64 faqat emulyatorlar
        // uchun kerak — emulyatorlar esa RASP bilan bloklanadi (ekspertiza
        // 2.2.6). Plagin native kutubxonalariga ham (freeRASP libts.so ~20 MB)
        // qo'llanadi — `--target-platform` faqat Flutter'nikiga ta'sir qiladi.
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
            // Barcha imzo sxemalari — MIUI/Xiaomi va eski OEM o'rnatuvchilari
            // ba'zan v1 (JAR) imzoni talab qiladi, aks holda "o'rnatishga ruxsat berilmadi".
            enableV1Signing = true
            enableV2Signing = true
            enableV3Signing = true
        }
    }

    buildTypes {
        release {
            // Play Store uchun upload-keystore bilan imzolanadi (key.properties bo'lsa),
            // aks holda debug kalit (mahalliy `flutter run --release` uchun).
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")

            // Ekspertiza 2.2.7: R8 obfuskatsiyasi — sinf/metod nomlari
            // o'zgartiriladi, ishlatilmagan kod va resurslar olib tashlanadi.
            // Dart kodi esa `flutter build --obfuscate` bilan obfuskatsiya qilinadi.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Server-side attestatsiya (PlayIntegrityPlugin.kt)
    implementation("com.google.android.play:integrity:1.4.0")
}
