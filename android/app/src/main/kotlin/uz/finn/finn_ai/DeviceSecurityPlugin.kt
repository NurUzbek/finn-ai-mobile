package uz.finn.finn_ai

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Debug
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

/**
 * freeRASP'dan MUSTAQIL ikkinchi himoya qatlami (defense in depth).
 *
 * Maqsad: himoya bitta kutubxonaga (Talsec) bog'lanib qolmasin — bitta hook
 * bilan hammasini o'chirib bo'lmasin. Bu modul native Kotlin darajada o'zi
 * tekshiradi:
 *   • root            — su binarlari, Magisk, test-keys, yoziladigan tizim
 *   • debugger        — Debug API + /proc/self/status TracerPid
 *   • dinamik tahlil  — hook/instrumentatsiya izlari (/proc/self/maps)
 *   • yaxlitlik       — ishga tushgandagi imzo sertifikati kutilgan bilan mos
 *
 * Natija Dart'ga qaytadi (lib/services/security.dart). Hech narsa serverga
 * yuborilmaydi — bu faqat qurilmada ishlaydigan himoya tekshiruvi.
 */
class DeviceSecurityPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    // Kutilgan imzo sertifikatlari SHA-256 (base64). Ilova qayta imzolansa
    // (repackaging), hech biriga mos kelmaydi → yaxlitlik buzilgan.
    //   1) finn.uz upload kaliti — sideload (finn.uz/app) foydalanuvchilarida
    //   2) Play App Signing kaliti — Google Play'dan o'rnatilganlarda
    private val expectedSigs = setOf(
        "j7mLhbvRfbzqX6c2akR9l1g3l6lPT8sbCsdPT9TY4xk=",
        "bZCeu8rBIOqfWyQyQnHCPB/GMtEU+PZuUPaJ23+Qwdo="
    )

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "uz.finn.app/devsec")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "check") {
            result.notImplemented()
            return
        }
        // Birorta tekshiruv xato bersa ham ilova qulab tushmasin
        val flags = mutableListOf<String>()
        runCatching { if (isRooted()) flags.add("root") }
        runCatching { if (isDebugged()) flags.add("debug") }
        runCatching { if (isInstrumented()) flags.add("hook") }
        runCatching { if (!signatureValid()) flags.add("integrity") }
        result.success(flags)
    }

    // ───────────────────────── root ─────────────────────────
    private fun isRooted(): Boolean {
        val paths = listOf(
            "/system/bin/su", "/system/xbin/su", "/sbin/su", "/system/sd/xbin/su",
            "/system/bin/failsafe/su", "/data/local/su", "/data/local/xbin/su",
            "/su/bin/su", "/magisk/.core/bin/su"
        )
        if (paths.any { File(it).exists() }) return true

        // test-keys bilan yig'ilgan (rasmiy bo'lmagan) proshivka
        if ((Build.TAGS ?: "").contains("test-keys")) return true

        // Root/Magisk boshqaruv ilovalari
        val apps = listOf(
            "com.topjohnwu.magisk", "eu.chainfire.supersu", "com.koushikdutta.superuser",
            "com.noshufou.android.su", "com.thirdparty.superuser", "com.yellowes.su"
        )
        val pm = context.packageManager
        for (p in apps) {
            runCatching { pm.getPackageInfo(p, 0); return true }
        }

        // Tizim bo'limiga yozish mumkinligi (odatda faqat root'da)
        val sysDirs = listOf("/system", "/system/bin", "/system/xbin", "/vendor/bin", "/sbin")
        if (sysDirs.any { File(it).canWrite() }) return true

        // which su
        runCatching {
            val p = ProcessBuilder("which", "su").redirectErrorStream(true).start()
            val out = p.inputStream.bufferedReader().readText()
            p.destroy()
            if (out.trim().isNotEmpty()) return true
        }
        return false
    }

    // ───────────────────────── debugger ─────────────────────────
    private fun isDebugged(): Boolean {
        if (Debug.isDebuggerConnected() || Debug.waitingForDebugger()) return true
        // /proc/self/status → TracerPid != 0 (biror jarayon ilovaga ulangan)
        runCatching {
            File("/proc/self/status").readLines().forEach { line ->
                if (line.startsWith("TracerPid:")) {
                    val pid = line.substringAfter(":").trim().toIntOrNull() ?: 0
                    if (pid != 0) return true
                }
            }
        }
        return false
    }

    // ─────────────── dinamik tahlil / hook izlari ───────────────
    private fun isInstrumented(): Boolean {
        // Jarayon xotira xaritasida instrumentatsiya ramkalari izlari
        val needles = listOf("frida", "gum-js-loop", "gmain", "linjector", "xposed", "substrate")
        runCatching {
            val maps = File("/proc/self/maps").readText().lowercase()
            if (needles.any { maps.contains(it) }) return true
        }
        // Yuklangan kutubxonalar orasida hook ramkalari
        runCatching {
            val libs = File("/proc/self/task").listFiles()?.size ?: 0
            // juda ko'p ip (thread) — gadget belgisidan biri bo'lishi mumkin, lekin
            // o'zi yetarli dalil emas, shuning uchun faqat maps ishonchli hisoblanadi
            if (libs < 0) return false
        }
        return false
    }

    // ───────────────────────── yaxlitlik ─────────────────────────
    private fun signatureValid(): Boolean {
        return runCatching {
            val sigs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val info = context.packageManager.getPackageInfo(
                    context.packageName, PackageManager.GET_SIGNING_CERTIFICATES
                )
                info.signingInfo?.apkContentsSigners ?: emptyArray()
            } else {
                @Suppress("DEPRECATION", "PackageManagerGetSignatures")
                val info = context.packageManager.getPackageInfo(
                    context.packageName, PackageManager.GET_SIGNATURES
                )
                @Suppress("DEPRECATION")
                info.signatures ?: emptyArray()
            }
            val md = MessageDigest.getInstance("SHA-256")
            sigs.any {
                val b64 = android.util.Base64.encodeToString(md.digest(it.toByteArray()), android.util.Base64.NO_WRAP)
                expectedSigs.contains(b64)
            }
        }.getOrDefault(false)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
