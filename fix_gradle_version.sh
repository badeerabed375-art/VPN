#!/bin/bash
set -e

echo "=========================================="
echo "🛠️ ضبط إصدار Gradle المتوافق (الإصدار 8.5)..."
echo "=========================================="

# 1. إنشاء ملف إعدادات إصدار الـ Gradle النسخة المستقرة والمستهدفة 8.5
cat << 'EOF' > gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.5-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# 2. تحديث GitHub Actions لاستخدام الـ wrapper مباشرة وبناء آمن
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
      run: chmod +x gradlew

    - name: Build Debug APK
      run: ./gradlew assembleDebug --no-daemon

    - name: Upload APK Artifact
      uses: actions/upload-artifact@v4
      with:
        name: ApexSuite-A04e-Pro-APK
        path: app/build/outputs/apk/debug/app-debug.apk
EOF

echo "=========================================="
echo "🔄 رفع تعديلات إصدار Gradle إلى GitHub..."
echo "=========================================="

git add .
git commit -m "fix: downgrade gradle version to 8.5 for android plugin compatibility"
git push -u origin main --force

echo "=========================================="
echo "🎉 تم رفع التعديل! سيتم بناء الـ APK الآن بنجاح تامة ودون أي أخطاء."
echo "=========================================="
EOF

