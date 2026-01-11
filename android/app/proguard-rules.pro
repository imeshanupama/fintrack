# Keep Hive classes
-keep class hive.** { *; }
-keep class * extends hive_flutter.** { *; }

# Keep all model classes with annotations
-keep @interface hive.HiveType
-keep @interface hive.HiveField
-keep @hive.HiveType class * { *; }
-keepclassmembers class * {
    @hive.HiveField *;
}

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-dontwarn com.google.android.gms.auth.**
