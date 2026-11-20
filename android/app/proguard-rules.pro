# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Suppress Play Core warnings from Flutter embedding
-dontwarn com.google.android.play.core.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# WorkManager / Room (firebase_messaging / local notifications)
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class * extends androidx.room.RoomDatabase$* { *; }
-keepnames class * extends androidx.room.RoomDatabase
-keep class androidx.room.** { *; }
-keepclassmembers class * extends androidx.work.Worker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}
-keepclassmembers class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class **_Impl {
    <init>();
    *;
}
-dontwarn androidx.work.**
-dontwarn androidx.room.**

# AndroidX Startup
-keep class androidx.startup.** { *; }
-keep class * extends androidx.startup.Initializer { *; }

# Google Play Services & AdMob
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Gson / reflective models used by plugins
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# FFmpeg Kit
-keep class com.arthenica.** { *; }
-dontwarn com.arthenica.**

# UCrop (Image Cropper)
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# Razorpay
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
