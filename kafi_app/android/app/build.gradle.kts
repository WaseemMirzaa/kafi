import java.util.Properties
import java.io.FileInputStream

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
    val props = Properties()
    localFile.inputStream().use { stream -> props.load(stream) }
    val key = props.getProperty("MAPS_API_KEY")
    return if (key != null && key.isNotBlank()) key else "YOUR_GOOGLE_MAPS_API_KEY"
}

// Release signing (Play Store / AAB). key.properties + *.jks are git-ignored.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.kafi.kafi_app"
    compileSdk = flutter.compileSdkVersion
    // NDK 28 breaks CMake configure on this machine; pin a known-good 27.x.
    ndkVersion = "27.1.12297006"

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

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Fallback for local/CI without a release keystore (sideload only).
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Play Billing Library latest. RevenueCat still declares 8.3.0; force 9.1.0
    // so the AAB meets Play Console billing-library requirements.
    implementation("com.android.billingclient:billing:9.1.0")
}

// Ensure every configuration (incl. RevenueCat transitive) resolves Billing 9.1.0.
configurations.configureEach {
    resolutionStrategy {
        force("com.android.billingclient:billing:9.1.0")
        force("com.android.billingclient:billing-ktx:9.1.0")
    }
}
