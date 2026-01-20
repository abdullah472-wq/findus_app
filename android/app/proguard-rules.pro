# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Facebook
-keep class com.facebook.** { *; }
-dontwarn com.facebook.**

# Your packages
-keep class com.findus.app.** { *; }

# Keep - 응용 프로그램이 proguard দ্বারা 제거되지 않도록 합니다.
-keep class * extends android.app.Application
-keep class * extends android.app.Activity
-keep class * extends android.app.Fragment
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.content.ContentProvider