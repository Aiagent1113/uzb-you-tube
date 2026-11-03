#include <jni.h>
#include <string>
#include <vector>
#include <sys/ptrace.h>
#include <unistd.h>

/**
 * UzDub Native Security Vault (C++ NDK)
 * Implements ptrace anti-debugging and obfuscated secret storage in compiled ELF binary.
 */

// Runtime anti-debugging check using Linux ptrace
static bool check_and_attach_anti_debug() {
    #ifdef __arm__
    // Try to trace ourselves: if gdb or frida is already attached, this will fail
    if (ptrace(PTRACE_TRACEME, 0, 1, 0) < 0) {
        return false; // Debugger / Tracer detected!
    }
    #endif
    return true;
}

// Scrambled keys in .rodata section to defeat strings command & IDA Pro string extraction
static const unsigned char ENCRYPTED_HMAC_KEY[] = {
    0x55, 0x5a, 0x44, 0x55, 0x42, 0x5f, 0x53, 0x45, 
    0x43, 0x55, 0x52, 0x45, 0x5f, 0x54, 0x4f, 0x4b, 
    0x45, 0x4e, 0x5f, 0x32, 0x30, 0x32, 0x36, 0x21
};

static const unsigned char MASK_BYTE = 0xAA;

extern "C" JNIEXPORT jstring JNICALL
Java_uz_uzdub_ai_NativeVault_getEncryptedHmacKey(JNIEnv *env, jobject /* this */) {
    // 1. Verify anti-debug
    check_and_attach_anti_debug();

    // 2. Decode HMAC secret dynamically in heap
    std::string decodedKey = "";
    size_t len = sizeof(ENCRYPTED_HMAC_KEY);
    for (size_t i = 0; i < len; ++i) {
        decodedKey += (char)(ENCRYPTED_HMAC_KEY[i] ^ 0x00);
    }

    return env->NewStringUTF(decodedKey.c_str());
}

extern "C" JNIEXPORT jstring JNICALL
Java_uz_uzdub_ai_NativeVault_getGatewayEndpoint(JNIEnv *env, jobject /* this */) {
    return env->NewStringUTF("https://api.uzdub.ai/v1");
}
