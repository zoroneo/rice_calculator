plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "one.zoro.rice_calculator"
    compileSdkVersion(flutter.compileSdkVersion)
    ndkVersion = "27.0.12077973"  // Updated to higher version as required by path_provider_android

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main") {
            manifest.srcFile("src/main/AndroidManifest.xml")
        }
    }

    defaultConfig {
        applicationId = "one.zoro.rice_calculator"
        // Defaults are api 21 for MIN_SDK and api 33 for TARGET_SDK
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0"
    }

    signingConfigs {
        create("release") {
            storeFile = file("keystore.jks")
            storePassword = "android"
            keyAlias = "upload"
            keyPassword = "android"
        }
    }

    buildTypes {
        debug {
            // You can configure other aspects, but the default is fine.
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.play:core:1.10.3")
}
