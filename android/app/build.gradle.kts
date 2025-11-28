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

    // Enable 16KB page size support
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
        // targetSdk 34 = Android 14 (supports 16KB page sizes)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // NDK configuration for 16KB page size support
        ndk {
            // Support all architectures including devices with 16KB pages
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64"))
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
