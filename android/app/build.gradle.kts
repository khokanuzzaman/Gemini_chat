import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Google Sign-In setup:
// 1. Add both debug and release SHA-1 fingerprints in Google Cloud Console/Firebase.
// 2. Download `google-services.json` for package `com.troubleshootbangla.pocketpilotai`.
// 3. Place the file at `android/app/google-services.json`.
// 4. If you prefer not to use `google-services.json`, provide `GOOGLE_WEB_CLIENT_ID`
//    via `.env` or `--dart-define` instead.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// Release signing. `android/key.properties` is git-ignored and holds the upload
// key's location + passwords (see CONTRIBUTING.md -> Release signing):
//   storeFile=/absolute/path/outside/repo/upload-keystore.jks
//   storePassword=...
//   keyAlias=upload
//   keyPassword=...
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasReleaseKey) keystorePropertiesFile.inputStream().use { load(it) }
}

android {
    namespace = "com.troubleshootbangla.pocketpilotai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.troubleshootbangla.pocketpilotai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Real upload key when key.properties exists. Without it we fall back
            // to the debug key ONLY so local `flutter run --release` / APK smoke
            // builds work; the bundle task below refuses to run in that state, so
            // a debug-signed AAB can never be produced by accident.
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8: shrink + obfuscate code, drop unused resources. Keep rules for
            // reflection/JNI users live in proguard-rules.pro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

// Guard: never produce a Play bundle signed with the debug key. Escape hatch for
// build-verification only: ORG_GRADLE_PROJECT_allowDebugSignedBundle=true.
gradle.taskGraph.whenReady {
    val buildsBundle = allTasks.any { it.name.endsWith("bundleRelease") }
    val allowed = project.findProperty("allowDebugSignedBundle") == "true"
    if (buildsBundle && !hasReleaseKey && !allowed) {
        throw GradleException(
            "Refusing to build a release AAB without android/key.properties " +
                "(it would be signed with the debug key). See CONTRIBUTING.md -> Release signing.",
        )
    }
}
