package com.apexsuite.vpn.security

import android.content.Context
import android.os.Build
import android.provider.Settings
import java.security.MessageDigest

object SecurityShield {
    
    /**
     * التحقق من سلامة البيئة التشغيلية ومنع تشغيل التطبيق على أجهزة روت (Root) غير آمنة 
     * إذا تطلب الأمر لتأمين بيانات المستخدم الحساسة.
     */
    fun isDeviceSecure(context: Context): Boolean {
        return !checkRootMethod1() && !checkRootMethod2() && checkAdbStatus(context)
    }

    private fun checkRootMethod1(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk", "/sbin/su", "/system/bin/su",
            "/system/xbin/su", "/data/local/xbin/su", "/data/local/bin/su",
            "/system/sd/xbin/su", "/system/bin/failsafe/su", "/data/local/su"
        )
        for (path in paths) {
            if (File(path).exists()) return true
        }
        return false
    }

    private fun checkRootMethod2(): Boolean {
        var buildTags = Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }

    private fun checkAdbStatus(context: Context): Boolean {
        return try {
            Settings.Global.getInt(context.contentResolver, Settings.Global.ADB_ENABLED, 0) == 0
        } catch (e: Exception) {
            true
        }
    }

    fun hashConfigToken(token: String): String {
        val bytes = MessageDigest.getInstance("SHA-256").digest(token.toByteArray())
        return bytes.joinToString("") { "%02x".format(it) }
    }
}
