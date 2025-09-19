plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ramanas_waiter"
    compileSdkVersion 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.ramanas_waiter"
        minSdkVersion 28
        targetSdkVersion 34
        versionCode 5
        versionName "1.0.1"
        multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.release
            minifyEnabled false
            shrinkResources false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
