# =======================================================================
# UzDub YouTube AI - Hardened ProGuard & DexGuard Security Rules
# Maximum Obfuscation, Anti-Decompilation, and Anti-Tampering
# =======================================================================

# 1. Strip all debugging and reflection metadata
-renamesourcefileattribute SourceFile
-keepattributes !SourceFile,!LineNumberTable,!LocalVariableTable,!LocalVariableTypeTable,!MethodParameters

# 2. Maximum aggressive renaming dictionary (unreadable single-character/unicode)
-useuniqueclassmembernames
-dontusemixedcaseclassnames
-overloadaggressively
-repackageclasses 'uz.uzdub.a'

# 3. Strip all Android logging calls in release builds (Log.d, Log.v, Log.i, Log.w, Log.e)
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
}

# 4. Preserve Flutter Engine & JNI Entry Points
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# 5. Preserve Flutter InAppWebView JavaScript Handlers
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# 6. Native C++ Vault JNI entry points
-keepclasseswithmembernames class * {
    native <methods>;
}
-keep class uz.uzdub.ai.NativeVault { *; }

# 7. Prevent serialization tampering
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
