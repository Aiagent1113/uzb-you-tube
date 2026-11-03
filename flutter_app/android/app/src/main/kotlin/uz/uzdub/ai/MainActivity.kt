package uz.uzdub.ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val VAULT_CHANNEL = "uz.uzdub.security/vault"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VAULT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getEncryptedHmacKey" -> {
                    result.success("UzDub_Secure_Key2026!@#$")
                }
                "getGatewayEndpoint" -> {
                    result.success("https://api.uzdub.ai/v1")
                }
                else -> result.notImplemented()
            }
        }
    }
}
