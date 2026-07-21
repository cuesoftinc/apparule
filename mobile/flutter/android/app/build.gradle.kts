plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing — keystore reaches the build via environment variables
// (CI/Doppler-provisioned; mobile-implementation.md §11 replaces the legacy
// DEBUG-key release config with this stub). No keystore or password is ever
// committed. When the variables are absent (local dev), release builds fall
// back to the debug keystore so `flutter run --release` still works.
val releaseKeystorePath: String? = System.getenv("APPARULE_ANDROID_KEYSTORE_PATH")

android {
    namespace = "io.cuesoft.apparule"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        // AGP 9 defaults resValues off; the flavors below use it for the
        // per-flavor app_name label.
        resValues = true
    }

    defaultConfig {
        applicationId = "io.cuesoft.apparule"
        // minSdk 24 per decisions.md M-4 (ratified floor, carried from legacy).
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // dev / stg / prd flavors (mobile-implementation.md §2): distinct
    // applicationIds so all three install side by side, each paired with
    // its lib/main_<flavor>.dart entrypoint (main.dart = prd). iOS
    // schemes/xcconfigs are deferred to an Xcode pass — tracked in the PR.
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Apparule Dev")
        }
        create("stg") {
            dimension = "env"
            applicationIdSuffix = ".stg"
            resValue("string", "app_name", "Apparule Stg")
        }
        create("prd") {
            dimension = "env"
            resValue("string", "app_name", "Apparule")
        }
    }

    signingConfigs {
        if (releaseKeystorePath != null) {
            create("release") {
                storeFile = file(releaseKeystorePath)
                storePassword = System.getenv("APPARULE_ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("APPARULE_ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("APPARULE_ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseKeystorePath != null) {
                signingConfigs.getByName("release")
            } else {
                // Documented local fallback — see the signing note above.
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
