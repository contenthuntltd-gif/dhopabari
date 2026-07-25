import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing — reads from android/key.properties (never committed).
// Create that file after generating your keystore; until then the release
// build falls back to debug signing so `flutter run` still works.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.dhopabari.customer_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.dhopabari.customer_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Three shippable apps from one codebase. Each flavor gets its own
    // applicationId (so all three can be installed side by side) and its own
    // launcher name. Pair every build with the matching Dart entry point, e.g.
    //   flutter build apk --release --flavor admin --dart-define=APP_FLAVOR=admin
    flavorDimensions += "role"
    productFlavors {
        create("customer") {
            dimension = "role"
            manifestPlaceholders["appLabel"] = "ধোপা বাড়ি"
        }
        create("admin") {
            dimension = "role"
            applicationIdSuffix = ".admin"
            manifestPlaceholders["appLabel"] = "ধোপা বাড়ি Admin"
        }
        create("rider") {
            dimension = "role"
            applicationIdSuffix = ".rider"
            manifestPlaceholders["appLabel"] = "ধোপা বাড়ি Rider"
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Use the real release key when key.properties exists; otherwise
            // fall back to debug signing so day-to-day builds still work.
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
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
