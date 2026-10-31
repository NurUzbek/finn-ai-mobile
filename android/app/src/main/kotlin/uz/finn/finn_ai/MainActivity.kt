package uz.finn.finn_ai

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// local_auth (barmoq izi / Face ID) FlutterFragmentActivity TALAB QILADI —
// FlutterActivity bilan biometrika "no_fragment_activity" bilan jim ishlamaydi.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Server-side attestatsiya (Play Integrity) — lib/services/attestation.dart
        flutterEngine.plugins.add(PlayIntegrityPlugin())
    }
}
