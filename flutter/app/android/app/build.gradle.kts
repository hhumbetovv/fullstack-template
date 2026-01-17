import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use(::load)
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()

android {
    namespace = "az.theternal.template"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "az.theternal.template"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                val storeFilePath = keystoreProperties["storeFile"] as? String
                val storePasswordValue = keystoreProperties["storePassword"] as? String
                val keyAliasValue = keystoreProperties["keyAlias"] as? String
                val keyPasswordValue = keystoreProperties["keyPassword"] as? String

                require(!storeFilePath.isNullOrBlank()) {
                    "Missing 'storeFile' entry in key.properties"
                }
                require(!storePasswordValue.isNullOrBlank()) {
                    "Missing 'storePassword' entry in key.properties"
                }
                require(!keyAliasValue.isNullOrBlank()) {
                    "Missing 'keyAlias' entry in key.properties"
                }
                require(!keyPasswordValue.isNullOrBlank()) {
                    "Missing 'keyPassword' entry in key.properties"
                }

                storeFile = file(storeFilePath)
                storePassword = storePasswordValue
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
            } else {
                initWith(getByName("debug"))
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    flavorDimensions += "default"

    productFlavors {
        create("dev") {
            dimension = "default"
            applicationIdSuffix = ".dev"
        }
        create("beta") {
            dimension = "default"
        }
        create("prod") {
            dimension = "default"
        }
    }
}

flutter {
    source = "../.."
}
