import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

fun localPropertyOrEnv(propertyName: String, envName: String, defaultValue: String = ""): String {
    return localProperties.getProperty(propertyName) ?: System.getenv(envName) ?: defaultValue
}

val jpushSdkVersion = "6.0.1"

android {
    namespace = "com.szk333333.course_schedule_app"
    compileSdk = flutter.compileSdkVersion
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
        applicationId = "com.szk333333.course_schedule_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["JPUSH_PKGNAME"] = "com.szk333333.course_schedule_app"
        manifestPlaceholders["JPUSH_APPKEY"] = localPropertyOrEnv("jpush.appKey", "JPUSH_APP_KEY")
        manifestPlaceholders["JPUSH_CHANNEL"] = localPropertyOrEnv("jpush.channel", "JPUSH_CHANNEL", "developer-default")
        manifestPlaceholders["XIAOMI_APPID"] = localPropertyOrEnv("jpush.xiaomi.appId", "JPUSH_XIAOMI_APP_ID")
        manifestPlaceholders["XIAOMI_APPKEY"] = localPropertyOrEnv("jpush.xiaomi.appKey", "JPUSH_XIAOMI_APP_KEY")
        manifestPlaceholders["HUAWEI_APPID"] = localPropertyOrEnv("jpush.huawei.appId", "JPUSH_HUAWEI_APP_ID")
        manifestPlaceholders["HUAWEI_CPID"] = localPropertyOrEnv("jpush.huawei.cpId", "JPUSH_HUAWEI_CP_ID")
        manifestPlaceholders["HONOR_APPID"] = localPropertyOrEnv("jpush.honor.appId", "JPUSH_HONOR_APP_ID")
        manifestPlaceholders["OPPO_APPID"] = localPropertyOrEnv("jpush.oppo.appId", "JPUSH_OPPO_APP_ID")
        manifestPlaceholders["OPPO_APPKEY"] = localPropertyOrEnv("jpush.oppo.appKey", "JPUSH_OPPO_APP_KEY")
        manifestPlaceholders["OPPO_APPSECRET"] = localPropertyOrEnv("jpush.oppo.appSecret", "JPUSH_OPPO_APP_SECRET")
        manifestPlaceholders["VIVO_APPID"] = localPropertyOrEnv("jpush.vivo.appId", "JPUSH_VIVO_APP_ID")
        manifestPlaceholders["VIVO_APPKEY"] = localPropertyOrEnv("jpush.vivo.appKey", "JPUSH_VIVO_APP_KEY")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("cn.jiguang.sdk:jpush:$jpushSdkVersion")
    implementation("cn.jiguang.sdk.plugin:xiaomi:$jpushSdkVersion")
    implementation("cn.jiguang.sdk.plugin:huawei:$jpushSdkVersion")
    implementation("cn.jiguang.sdk.plugin:honor:$jpushSdkVersion")
    implementation("cn.jiguang.sdk.plugin:oppo:$jpushSdkVersion")
    implementation("cn.jiguang.sdk.plugin:vivo:$jpushSdkVersion")
}
