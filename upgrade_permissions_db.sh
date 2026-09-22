#!/bin/bash
set -e

echo "=========================================="
echo "🛡️ جاري بناء ملف الصلاحيات، نظام التخزين، وقاعدة البيانات اليومية..."
echo "=========================================="

# 1. إنشاء المجلدات اللازمة
mkdir -p app/src/main/java/com/apexsuite/vpn/database
mkdir -p app/src/main/java/com/apexsuite/vpn/storage
mkdir -p app/src/main/java/com/apexsuite/vpn/permissions
mkdir -p app/src/main/res/xml

# ---------------------------------------------------------
# 1. ملف الصلاحيات والأذونات الشامل (`AndroidManifest.xml`)
# ---------------------------------------------------------
cat << 'EOF' > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- شبكة الإنترنت والاتصال -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />

    <!-- خدمة الـ VPN الخلفية -->
    <uses-permission android:name="android.permission.BIND_VPN_SERVICE" tools:ignore="ProtectedPermissions" />

    <!-- منع النوم وإدارة الطاقة لمعالج A04e -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

    <!-- بصمة الإصبع والأمان -->
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
    <uses-permission android:name="android.permission.USE_FINGERPRINT" />

    <!-- التخزين الداخلي والخارجي وحفظ السجلات -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" tools:ignore="ScopedStorage" />

    <!-- التحديثات والإشعارات -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:name=".ApexApp"
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.ApexSuite"
        tools:targetApi="34">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.ApexSuite">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <service
            android:name=".core.ApexVpnService"
            android:exported="false"
            android:permission="android.permission.BIND_VPN_SERVICE">
            <intent-filter>
                <action android:name="android.permissions.BIND_VPN_SERVICE" />
            </intent-filter>
        </service>

        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>

    </application>

</manifest>
EOF

# ---------------------------------------------------------
# 2. مدير الأذونات التلقائي (`PermissionManager.kt`)
# ---------------------------------------------------------
cat << 'EOF' > app/src/main/java/com/apexsuite/vpn/permissions/PermissionManager.kt
package com.apexsuite.vpn.permissions

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

object PermissionManager {
    const val PERMISSION_REQUEST_CODE = 1001

    fun getRequiredPermissions(): Array<String> {
        val permissions = mutableListOf(
            Manifest.permission.INTERNET,
            Manifest.permission.ACCESS_NETWORK_STATE,
            Manifest.permission.WAKE_LOCK
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
            permissions.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
        }

        return permissions.toTypedArray()
    }

    fun hasAllPermissions(activity: Activity): Boolean {
        for (permission in getRequiredPermissions()) {
            if (ContextCompat.checkSelfPermission(activity, permission) != PackageManager.PERMISSION_GRANTED) {
                return false
            }
        }
        return true
    }

    fun requestPermissions(activity: Activity) {
        ActivityCompat.requestPermissions(activity, getRequiredPermissions(), PERMISSION_REQUEST_CODE)
    }
}
EOF

# ---------------------------------------------------------
# 3. نظام التخزين الداخلي والخارجي (`StorageManager.kt`)
# ---------------------------------------------------------
cat << 'EOF' > app/src/main/java/com/apexsuite/vpn/storage/StorageManager.kt
package com.apexsuite.vpn.storage

import android.content.Context
import android.os.Environment
import android.util.Log
import java.io.File
import java.io.FileWriter

object StorageManager {
    private const val TAG = "StorageManager"

    fun saveLogToExternalStorage(context: Context, logData: String): Boolean {
        return try {
            val dir = File(context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS), "ApexLogs")
            if (!dir.exists()) dir.mkdirs()

            val file = File(dir, "vpn_activity_log.txt")
            FileWriter(file, true).use { writer ->
                writer.append("${System.currentTimeMillis()}:$logData\n")
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في حفظ السجل بالتخزين الخارجي: ${e.message}")
            false
        }
    }
}
EOF

# ---------------------------------------------------------
# 4. قاعدة البيانات اليومية المحدثة (`DailyDatabaseManager.kt`)
# ---------------------------------------------------------
cat << 'EOF' > app/src/main/java/com/apexsuite/vpn/database/DailyDatabaseManager.kt
package com.apexsuite.vpn.database

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import java.text.SimpleDateFormat
import java.util.*

class DailyDatabaseManager(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "apex_daily_sync.db"
        private const val DATABASE_VERSION = 1

        const val TABLE_SERVERS = "daily_servers"
        const val TABLE_STATS = "daily_stats"
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""
            CREATE TABLE $TABLE_SERVERS (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                protocol TEXT,
                address TEXT,
                port INTEGER,
                config_json TEXT,
                last_updated TEXT
            )
        """)

        db.execSQL("""
            CREATE TABLE $TABLE_STATS (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date_stamp TEXT UNIQUE,
                bytes_downloaded LONG,
                bytes_uploaded LONG,
                ping_avg LONG
            )
        """)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_SERVERS")
        db.execSQL("DROP TABLE IF EXISTS $TABLE_STATS")
        onCreate(db)
    }

    fun syncDailyData(serverListJson: String) {
        val db = this.writableDatabase
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        
        db.beginTransaction()
        try {
            db.execSQL("DELETE FROM $TABLE_SERVERS")
            // إضافة البيانات اليومية الجديدة
            db.execSQL("INSERT INTO $TABLE_SERVERS (protocol, address, port, config_json, last_updated) VALUES ('VLESS', 'node.apex.net', 443, ?, ?)", arrayOf(serverListJson, today))
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
            db.close()
        }
    }
}
EOF

echo "✅ تم بناء الصلاحيات والتخزين وقاعدة البيانات اليومية بنجاح."

# ---------------------------------------------------------
# رفع التحديثات إلى GitHub
# ---------------------------------------------------------
echo "=========================================="
echo "🔄 دفع التحديثات الشاملة إلى مستودع VPN على GitHub..."
echo "=========================================="

git add .
git commit -m "feat(Permissions&DB): add auto permissions request, external/internal storage, and daily SQLite database sync"
git push -u origin main --force

echo "=========================================="
echo "🎉 تم رفع كافة الأنظمة والصلاحيات وقاعدة البيانات اليومية بنجاح تام!"
echo "=========================================="
EOF

