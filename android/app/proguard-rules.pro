## Gson rules required by flutter_local_notifications.
# Gson uses generic type information stored in class-file signatures. R8 can
# strip that metadata in release builds, which breaks TypeToken deserialization
# for scheduled notification data.
-keepattributes Signature
-keepattributes *Annotation*

-dontwarn sun.misc.**

-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# ---- R8 keep rules (slice h) -------------------------------------------------
# Firebase, Play services and ML Kit ship their own consumer rules, so we do NOT
# blanket-keep them (that defeated shrinking and made the APK bigger than the
# unminified build). We keep only what is name-/reflection-bound in OUR plugins,
# and silence warnings for optional classes R8 cannot see.

# Isar (isar_community): Dart<->native via FFI; keep the Android shim.
-keep class dev.isar.** { *; }
-keep class io.isar.** { *; }

# RevenueCat (purchases_flutter + purchases-hybrid-common): bridge + models are
# serialised by name across the platform channel.
-keep class com.revenuecat.purchases.hybridcommon.** { *; }
-keep class com.revenuecat.purchases_flutter.** { *; }
-dontwarn com.revenuecat.purchases.**

# Google ML Kit text recognition glue. OCR is off in Phase 1, but the plugin and
# the optional script modules (Chinese/Devanagari/Japanese/Korean, see
# app/build.gradle.kts) are still compiled in, so their classes must resolve.
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-dontwarn com.google.mlkit.**

# Firebase / Play services optional references.
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Flutter engine's deferred-components hooks reference Play Core, which we don't ship.
-dontwarn com.google.android.play.core.**
