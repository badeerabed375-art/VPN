#!/bin/bash
set -e

echo "=========================================="
echo "⚙️ جاري بناء ملفات Gradle وإعدادات المشروع لإنشاء الـ APK..."
echo "=========================================="

# 1. إنشاء ملف settings.gradle للمشروع
cat << 'EOF' > settings.gradle
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
rootProject.name = "ApexSuite"
include ':app'
EOF

# 2. إنشاء ملف build.gradle على مستوى المشروع (Project-level)
cat << 'EOF' > build.gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.0'
        classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0'
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

# 3. إنشاء ملف gradle.properties لتحسين الأداء على A04e
cat << 'EOF' > gradle.properties
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true
org.gradle.parallel=true
org.gradle.caching=true
EOF

# 4. إنشاء ملف build.gradle الخاص بالتطبيق (App-level)
mkdir -p app
cat << 'EOF' > app/build.gradle
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.apexsuite.vpn'
    compileSdk 34

    defaultConfig {
        applicationId "com.apexsuite.vpn"
        minSdk 24
        targetSdk 34
        versionCode 200
        versionName "2.0.0-PRO"

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary true
        }
    }

    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            minifyEnabled false
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = '17'
    }
    packagingOptions {
        resources {
            excludes += '/META-INF/{AL2.0,LGPL2.1}'
        }
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.biometric:biometric:1.2.0-alpha05'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'
    implementation 'com.google.code.gson:gson:2.10.1'
}
EOF

echo "✅ تم إنشاء ملفات الـ Gradle بنجاح."

# 5. تحديث ملف GitHub Actions لضمان نجاح البناء
mkdir -p .github/workflows
cat << 'EOF' > .github/workflows/build_apk.yml
name: Build Apex Suite VPN APK

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        distribution: 'temurin'
        java-version: '17'
        cache: 'gradle'

    - name: Grant execute permission for gradlew
      run: |
        gradle wrapper
        chmod +x gradlew

    - name: Build Debug APK
      run: ./gradlew assembleDebug --no-daemon

    - name: Upload APK Artifact
      uses: actions/upload-artifact@v4
      with:
        name: ApexSuite-A04e-Pro-APK
        path: app/build/outputs/apk/debug/app-debug.apk
EOF

echo "=========================================="
echo "🔄 دفع التحديثات وملفات البناء إلى GitHub..."
echo "=========================================="

git add .
git commit -m "build: add gradle configuration files and fix github actions apk builder"
git push -u origin main --force

echo "=========================================="
echo "🎉 تم رفع ملفات البناء بنجاح! ستبدأ عملية إنشاء الـ APK تلقائياً الآن."
echo "=========================================="
EOF

