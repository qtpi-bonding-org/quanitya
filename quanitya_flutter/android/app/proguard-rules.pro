# SQLCipher — keep JNI bridge classes that R8 would otherwise strip
-keep class net.sqlcipher.** { *; }

# Flutter standard rules (Flutter's Gradle plugin adds these automatically in
# recent versions, but we include them here as an explicit safety net)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Google ML Kit — keep all text recognition script variants
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**
