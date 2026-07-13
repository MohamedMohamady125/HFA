# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep Gson / JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
