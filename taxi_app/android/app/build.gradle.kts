plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.yousu.taxi_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Production-ready application ID
        applicationId = "com.yousu.taxiapp"
        
        // Minimum SDK for location services and maps
        minSdk = 24
        
        // Target SDK for latest features
        targetSdk = 36
        
        // Version configuration
        versionCode = 1
        versionName = "1.0.0"
        
        // Multi-dex support for large apps
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Disable problematic features for successful build
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Use debug signing for now
            signingConfig = signingConfigs.getByName("debug")
        }
        
        debug {
            isDebuggable = true
            applicationIdSuffix = ".debug"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
