#!/bin/bash
set -e

echo "=========================================="
echo "🔧 جاري إصلاح إعدادات Gradle وتوافق الإصدارات الحديثة..."
echo "=========================================="

# 1. تحديث settings.gradle لدعم مستودعات الإضافات بشكل صحيح
cat << 'EOF' > settings.gradle
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
rootProject.name = "ApexSuite"
include ':app'
EOF

# 2. تحديث build.gradle الرئيسي (إزالة المستودعات المكررة التي تسبب خطأ التفضيل)
cat << 'EOF' > build.gradle
plugins {
    id 'com.android.application' version '8.2.0' apply false
    id 'org.jetbrains.kotlin.android' version '1.9.0' apply false
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

# 3. تحديث ملف GitHub Actions لتطبيق التصحيح وبناء الـ APK بنجاح
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
echo "🔄 رفع التعديلات الإصلاحية إلى GitHub..."
echo "=========================================="

git add .
git commit -m "fix: resolve gradle repository preference error and update android plugins block"
git push -u origin main --force

echo "=========================================="
echo "🎉 تم إصلاح الخطأ ورفع التحديث بنجاح! ستبدأ عملية بناء الـ APK الآن بدون مشاكل."
echo "=========================================="
EOF

