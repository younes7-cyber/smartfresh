plugins {
    id("com.android.application")
    id("kotlin-android")
    // Ajout du plugin Google Services
    id("com.google.gms.google-services")
    // Le plugin Flutter doit être appliqué après Android, Kotlin et Google Services
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smartfresh"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
    isCoreLibraryDesugaringEnabled = true
}

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.smartfresh"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Importation de la Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // SDK Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // Vous pouvez ajouter d'autres dépendances ici sans préciser la version
    // exemple: implementation("com.google.firebase:firebase-auth")
}