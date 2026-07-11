# Flutter ProGuard Rules
# These rules ensure that the Flutter framework and its plugins are not incorrectly obfuscated or stripped.

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# JNI
-keepattributes Exceptions,InnerClasses,Signature,Deprecated,SourceFile,LineNumberTable,*Annotation*,EnclosingMethod
-keep class androidx.annotation.Keep

# Hive ProGuard Rules (if applicable)
-keep class com.mongodb.client.model.** { *; }

# Prevent shrinking of resources that might be used by plugins
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.android.gms.** { *; }
