plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after Android & Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    // id("com.google.gms.google-services") // Removed: Not needed for Google Sign-In/Calendar only
}

android {
    namespace = "com.example.app_mr_plannter" // Πρέπει να ταιριάζει με το OAuth client
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.app_mr_plannter" // Πρέπει να ταιριάζει με το OAuth
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Αν θέλεις, εδώ μπορείς να βάλεις release signing config
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring για νεότερα Java features
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Google APIs για Sign-In & Calendar
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}
