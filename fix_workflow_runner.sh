#!/bin/bash
set -e

echo "=========================================="
echo "🛠️ تعديل سير العمل لإزالة الاعتماد على gradlew..."
echo "=========================================="

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

    - name: Build Debug APK using Gradle
      run: gradle assembleDebug --no-daemon

    - name: Upload APK Artifact
      uses: actions/upload-artifact@v4
      with:
        name: ApexSuite-A04e-Pro-APK
        path: app/build/outputs/apk/debug/app-debug.apk
EOF

echo "=========================================="
echo "🔄 دفع التعديل إلى GitHub..."
echo "=========================================="

git add .
git commit -m "fix: use direct gradle command in github actions workflow instead of gradlew"
git push -u origin main --force

echo "=========================================="
echo "🎉 تم رفع التعديل بنجاح! ستبدأ عملية البناء الآن بدون أخطاء."
echo "=========================================="
EOF

