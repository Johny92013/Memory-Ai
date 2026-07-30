# Patches unmaintained video_thumbnail Android build for AGP 9 / Gradle without jcenter.
# Run after `flutter pub get` if release APK build fails on jcenter or compileSdk 33.
$path = Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev\video_thumbnail-0.5.6\android\build.gradle"
if (-not (Test-Path $path)) {
  Write-Error "video_thumbnail build.gradle not found at $path"
  exit 1
}
$text = @'
group 'xyz.justsoft.video_thumbnail'
version '1.0-SNAPSHOT'

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.7.3'
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'

android {
    compileSdkVersion 36
    namespace 'xyz.justsoft.video_thumbnail'

    defaultConfig {
        minSdkVersion 16
        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }
    lintOptions {
        disable 'InvalidPackage'
    }
}
'@
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Resolve-Path $path), $text, $utf8NoBom)
Write-Host "Patched $path (UTF-8 without BOM)"
