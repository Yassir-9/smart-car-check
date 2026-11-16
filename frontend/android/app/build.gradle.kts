import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingFile = rootProject.file("key.properties")
if (signingFile.exists()) {
    signingFile.inputStream().use { stream ->
        signingProperties.load(stream)
    }
}

android {
    namespace = "com.smartcarcheck.app"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.smartcarcheck.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (signingFile.exists()) {
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
                storePassword = signingProperties.getProperty("storePassword")
                signingProperties.getProperty("storeFile")?.let { storeFile = file(it) }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Release builds must never be produced unsigned or signed with debug keys.
gradle.taskGraph.whenReady {
    val releaseTaskPattern = Regex("(assemble|bundle|package|sign).*Release.*", RegexOption.IGNORE_CASE)
    val buildingRelease = allTasks.any { it.project == project && releaseTaskPattern.matches(it.name) }
    if (buildingRelease) {
        if (!signingFile.exists()) {
            throw GradleException(
                "Release signing is not configured: android/key.properties was not found. " +
                    "Create it with storeFile, storePassword, keyAlias and keyPassword before building a release."
            )
        }
        val missing = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
            .filter { signingProperties.getProperty(it).isNullOrBlank() }
        if (missing.isNotEmpty()) {
            throw GradleException(
                "Release signing is incomplete: key.properties is missing " + missing.joinToString(", ") + "."
            )
        }
        val keystore = file(signingProperties.getProperty("storeFile"))
        if (!keystore.exists()) {
            throw GradleException(
                "Release signing keystore not found at: " + keystore.path +
                    ". Check storeFile in android/key.properties."
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
