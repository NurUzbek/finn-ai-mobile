package uz.finn.finn_ai

import android.content.Context
import com.google.android.gms.tasks.Task
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityException
import com.google.android.play.core.integrity.StandardIntegrityManager
import com.google.android.play.core.integrity.StandardIntegrityManager.PrepareIntegrityTokenRequest
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenProvider
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest
import com.google.android.play.core.integrity.model.StandardIntegrityErrorCode
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

/**
 * Play Integrity API (Standard request) — server-side attestatsiya uchun token.
 * Token Google kaliti bilan imzolangan; finn.uz uni Google orqali dekodlab,
 * paket nomi, imzo sertifikati, qurilma yaxlitligi (root/emulyator) va nonce'ni
 * tekshiradi. Klientni Frida bilan ochish tokenni soxtalashtira olmaydi.
 */
class PlayIntegrityPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var manager: StandardIntegrityManager
    private var provider: StandardIntegrityTokenProvider? = null

    // Google Cloud "Finn Ai" (finn-ai-513307) — Play Console'da FINN AI'ga bog'langan
    private val cloudProjectNumber = 324004022280L

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "uz.finn.app/attest")
        channel.setMethodCallHandler(this)
        manager = IntegrityManagerFactory.createStandard(binding.applicationContext)
        prepare() // oldindan isitib qo'yamiz — birinchi so'rov tezroq bo'ladi
    }

    private fun prepare(): Task<StandardIntegrityTokenProvider> =
        manager.prepareIntegrityToken(
            PrepareIntegrityTokenRequest.builder().setCloudProjectNumber(cloudProjectNumber).build()
        ).addOnSuccessListener { provider = it }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "playIntegrityToken") {
            result.notImplemented()
            return
        }
        // requestHash = SHA-256(nonce) hex — server xuddi shunday hisoblaydi
        val hash = sha256Hex(call.argument<String>("requestHash") ?: "")
        val ready = provider
        if (ready != null) {
            request(ready, hash, result, retry = true)
        } else {
            prepare()
                .addOnSuccessListener { request(it, hash, result, retry = false) }
                .addOnFailureListener { result.error("PREPARE_FAILED", it.message, null) }
        }
    }

    private fun request(p: StandardIntegrityTokenProvider, hash: String, result: MethodChannel.Result, retry: Boolean) {
        p.request(StandardIntegrityTokenRequest.builder().setRequestHash(hash).build())
            .addOnSuccessListener { result.success(it.token()) }
            .addOnFailureListener { e ->
                // Provayder eskirgan — bir marta qayta tayyorlab urinamiz
                val expired = e is StandardIntegrityException &&
                    e.errorCode == StandardIntegrityErrorCode.INTEGRITY_TOKEN_PROVIDER_INVALID
                if (expired && retry) {
                    provider = null
                    prepare()
                        .addOnSuccessListener { request(it, hash, result, retry = false) }
                        .addOnFailureListener { result.error("PREPARE_FAILED", it.message, null) }
                } else {
                    result.error("REQUEST_FAILED", e.message, null)
                }
            }
    }

    private fun sha256Hex(s: String): String =
        MessageDigest.getInstance("SHA-256").digest(s.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
