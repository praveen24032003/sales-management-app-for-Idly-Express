import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val releaseStoreType = keystoreProperties.getProperty("storeType")?.ifBlank { null } ?: "PKCS12"
val hasReleaseSigning = listOf("keyAlias", "keyPassword", "storeFile", "storePassword").all {
    !keystoreProperties.getProperty(it).isNullOrBlank()
}
val requireReleaseSigning = providers.gradleProperty("idlyRequireReleaseSigning")
    .orNull
    ?.equals("true", ignoreCase = true) == true

if (requireReleaseSigning && !hasReleaseSigning) {
    throw GradleException(
        "Release signing is required, but android/key.properties is missing or incomplete. " +
            "Provide a valid keystore configuration or build without -PidlyRequireReleaseSigning=true for internal validation.",
    )
}

android {
    namespace = "com.idlyexpress.salesmanager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                storeType = releaseStoreType
            }
        }
    }

    defaultConfig {
        applicationId = "com.idlyexpress.salesmanager"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
