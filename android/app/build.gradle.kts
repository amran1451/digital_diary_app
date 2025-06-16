// android/app/build.gradle.kts

import com.android.build.gradle.api.ApkVariantOutput

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") 
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.digital_diary_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.digital_diary_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        getByName("debug") {
            // можно оставить as-is или задать особые опции
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Переименование APK
    applicationVariants.forEach { variant ->
    // берём только те outputs, которые APK
    variant.outputs
      .filterIsInstance<ApkVariantOutput>()
      .forEach { output ->
        val appName = "МойДневник"
        // variant.versionName берётся из defaultConfig.versionName = flutter.versionName
        val version = variant.versionName ?: "1.0.0"
        val newName = if (variant.buildType.name == "release") {
          "$appName-v$version.apk"
        } else {
          "$appName-debug.apk"
        }
        // Устанавливаем имя выходного файла
        output.outputFileName = newName
      }
    }
}

flutter {
    source = "../.."
}
