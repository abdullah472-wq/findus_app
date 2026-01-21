plugins {
    id("com.android.application")
    // এই লাইনটি অত্যন্ত জরুরি, এটি ছাড়া Firebase কাজ করবে না
    id("com.google.gms.google-services") version "4.4.2"
    id("com.google.firebase.crashlytics") version "3.0.2"
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.findus.app"
    // 36 অনেক সময় স্টেবল না হতে পারে, তাই 34 বা 35 ব্যবহার করা নিরাপদ
    compileSdk = 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.findus.app"
        minSdk = 23
        targetSdk = 34 // compileSdk এর সাথে মিল রাখা ভালো
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}