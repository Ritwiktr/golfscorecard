plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.app.golfscorecard"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Enable 16KB page size support (Google Play requirement - Nov 2025)
    buildFeatures {
        buildConfig = true
    }
    
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }

    defaultConfig {
        applicationId = "com.app.golfscorecard"
        // minSdk 21 = Android 5.0 (Lollipop)
        minSdk = flutter.minSdkVersion
        // targetSdk 34+ = Android 14+ (supports 16KB page sizes)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // NDK configuration for 16KB page size support
        // Flutter uses NDK r28+ which supports 16KB pages automatically
        ndk {
            // Support all architectures including devices with 16KB pages
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64"))
        }
    }

    buildTypes {
        release {
            // Unsigned AAB - no signing config specified
            // Note: AABs must be signed before Play Store submission
            // signingConfig = null
        }
    }
}

flutter {
    source = "../.."
}
