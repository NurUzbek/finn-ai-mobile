import CryptoKit
import DeviceCheck
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FinnAppAttest") {
      AppAttestChannel.register(messenger: registrar.messenger())
    }
  }
}

/// Server-side attestatsiya (Apple App Attest) — lib/services/attestation.dart.
/// Secure Enclave'da ilovaga bog'langan kalit yaratiladi; attestatsiya Apple
/// ildiz sertifikatiga ulanadi va finn.uz tomonidan tekshiriladi. Qayta
/// paketlangan ilova yaroqli attestatsiya yarata olmaydi.
enum AppAttestChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "uz.finn.app/attest", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard #available(iOS 14.0, *) else {
        // App Attest iOS 14+ — eski qurilmada qo'llab-quvvatlanmaydi
        if call.method == "appAttestSupported" {
          result(false)
        } else {
          result(FlutterMethodNotImplemented)
        }
        return
      }
      let service = DCAppAttestService.shared
      let args = call.arguments as? [String: Any]
      let challenge = args?["challenge"] as? String ?? ""
      // clientDataHash = SHA-256(nonce) — server xuddi shunday hisoblaydi
      let clientDataHash = Data(SHA256.hash(data: Data(challenge.utf8)))

      switch call.method {
      case "appAttestSupported":
        result(service.isSupported)

      case "appAttestKey":
        service.generateKey { keyId, error in
          guard let keyId = keyId, error == nil else {
            return reply(result, FlutterError(code: "KEYGEN", message: error?.localizedDescription, details: nil))
          }
          service.attestKey(keyId, clientDataHash: clientDataHash) { attestation, error in
            guard let attestation = attestation, error == nil else {
              return reply(result, FlutterError(code: "ATTEST", message: error?.localizedDescription, details: nil))
            }
            reply(result, ["keyId": keyId, "attestation": attestation.base64EncodedString()])
          }
        }

      case "appAttestAssert":
        let keyId = args?["keyId"] as? String ?? ""
        service.generateAssertion(keyId, clientDataHash: clientDataHash) { assertion, error in
          guard let assertion = assertion, error == nil else {
            return reply(result, FlutterError(code: "ASSERT", message: error?.localizedDescription, details: nil))
          }
          reply(result, ["assertion": assertion.base64EncodedString()])
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// DeviceCheck callback'lari fon oqimida keladi — Flutter javobi asosiy oqimda.
  private static func reply(_ result: @escaping FlutterResult, _ value: Any?) {
    DispatchQueue.main.async { result(value) }
  }
}
