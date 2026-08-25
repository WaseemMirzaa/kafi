plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Wire live Firebase (Auth/Firestore/Storage/FCM) from the native config, but
// only when it's present — so a mock/offline build needs no Firebase secrets.
// google-services.json is git-ignored; download it from the Firebase console
// (Android app: com.kafi.kafi_app) into this directory. See ../../BUILD_APK.md.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

fun mapsApiKeyFromLocalProperties(): String {
    val localFile = rootProject.file("local.properties")
    if (!localFile.exists()) return "YOUR_GOOGLE_MAPS_API_KEY"
    val props = java.util.Properties()
    localFile.inputStream().use { props.load(it) }
    return props.getProperty("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: "YOUR_GOOGLE_MAPS_API_KEY"
}

android {
    namespace = "com.kafi.kafi_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kafi.kafi_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Google Maps native SDK reads its key from the manifest, not from
        // --dart-define. Prefer -PMAPS_API_KEY=…, else android/local.properties
        // MAPS_API_KEY=… (git-ignored). See ../../docs/GOOGLE_MAPS_SETUP.md.
        manifestPlaceholders["MAPS_API_KEY"] =
            (project.findProperty("MAPS_API_KEY") as String?)
                ?: mapsApiKeyFromLocalProperties()
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
