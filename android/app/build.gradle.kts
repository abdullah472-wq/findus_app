import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")  // ✅ যোগ করুন
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.findus.app"
    compileSdk = 34  // ✅ সরাসরি 34 সেট করুন (সর্বশেষ)
    ndkVersion = "26.1.10909125"  // ✅ সরাসরি NDK ভার্সন সেট করুন

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.findus.app"
        minSdk = 23  // ✅ Android 6.0+ (API 23) সেট করুন
        targetSdk = 34  // ✅ সরাসরি 34 সেট করুন
        versionCode = 1  // ✅ সরাসরি 1 সেট করুন
        versionName = "1.0.0"  // ✅ সরাসরি 1.0.0 সেট করুন

        // ✅ MultiDex enable করুন
        multiDexEnabled = true

        // ✅ Test runner
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
            val storeFileProp = keystoreProperties.getProperty("storeFile")
            if (storeFileProp != null) {
                storeFile = rootProject.file(storeFileProp)
            }
            storePassword = keystoreProperties.getProperty("storePassword") ?: ""
        }
        // ✅ Debug signing config (optional)
        getByName("debug") {
            storeFile = file("debug.keystore")
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
            // ✅ Debug features
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-DEBUG"
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }

        release {
            // ✅ Signing config
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")  // Fallback
            }

            // ✅ Production optimization
            isMinifyEnabled = true
            isShrinkResources = true

            // ✅ Proguard rules
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // ✅ Disable debug
            isDebuggable = false
            isJniDebuggable = false
            isRenderscriptDebuggable = false

            // ✅ Optimize PNG
            crunchPngs = true
        }
    }

    // ✅ Build features
    buildFeatures {
        buildConfig = true
    }

    // ✅ Packaging options
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "META-INF/LICENSE.md"
            excludes += "META-INF/LICENSE-notice.md"
        }
    }

    // ✅ Lint options (production এর জন্য)
    lint {
        abortOnError = true
        warningsAsErrors = true
        checkReleaseBuilds = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ MultiDex dependency (যদি app বড় হয়)
    implementation("androidx.multidex:multidex:2.0.1")

    // ✅ Test dependencies
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}