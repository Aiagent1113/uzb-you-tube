package uz.uzdub.ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val VAULT_CHANNEL = "uz.uzdub.security/vault"

    companion object {
        init {
            try {
                System.loadLibrary("native-vault")
            } catch (e: UnsatisfiedLinkError) {
                // Fallback handled in Dart
            }
        }
    }

    // External native C++ methods declared in native-vault.cpp
    private external fun getEncryptedHmacKey(): String?
    private external fun getGatewayEndpoint(): String?

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VAULT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getEncryptedHmacKey" -> {
                    try {
                        val key = getEncryptedHmacKey() ?: "UzDub_Secure_Key2026!@#$"
                        result.success(key)
                    } catch (e: Exception) {
                        result.success("UzDub_Secure_Key2026!@#$")
                    }
                }
                "getGatewayEndpoint" -> {
                    try {
                        val endpoint = getGatewayEndpoint() ?: "https://api.uzdub.ai/v1"
                        result.success(endpoint)
                    } catch (e: Exception) {
                        result.success("https://api.uzdub.ai/v1")
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
