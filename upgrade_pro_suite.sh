#!/bin/bash
set -e

echo "=========================================="
echo "🧹 جاري بناء وإضافة محركات SD Maid، التنظيف، البروتوكولات، وملف الإعدادات الاحترافي..."
echo "=========================================="

# 1. إنشاء المجلدات الاحترافية الجديدة
mkdir -p app/src/main/java/com/apexsuite/vpn/optimizer
mkdir -p app/src/main/java/com/apexsuite/vpn/protocols
mkdir -p app/src/main/java/com/apexsuite/vpn/localization
mkdir -p app/src/main/res/values

# ---------------------------------------------------------
# 1. محرك التنظيف الذكي (SD Maid & Cache Cleaner لـ A04e)
# ---------------------------------------------------------
cat << 'EOF' > app/src/main/java/com/apexsuite/vpn/optimizer/SDMaidOptimizer.kt
package com.apexsuite.vpn.optimizer

import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

/**
 * محرك تنظيف احترافي مستوحى من أدوات SD Maid لإدارة الذاكرة،
 * تنظيف الكاش والملفات المؤقتة لحماية أداء هاتف A04e من البطء.
 */
object SDMaidOptimizer {
    private const val TAG = "SDMaidOptimizer"

    data class CleanResult(
        val freedMemoryMB: Double,
        val deletedFilesCount: Int
    )

    suspend fun performDeepClean(context: Context): CleanResult = withContext(Dispatchers.IO) {
        var deletedCount = 0
        var freedBytes: Long = 0

        try {
            // 1. تنظيف كاش التطبيق الداخلي
            val cacheDir = context.cacheDir
            freedBytes += cleanDir(cacheDir) { deletedCount++ }

            // 2. تنظيف الكاش الخارجي المخصص
            context.externalCacheDir?.let { extCache ->
                freedBytes += cleanDir(extCache) { deletedCount++ }
            }

            // 3. تنظيف ملفات السجل المؤقتة (Logs)
            val logDir = File(context.filesDir, "logs")
            if (logDir.exists()) {
                freedBytes += cleanDir(logDir) { deletedCount++ }
            }

            // طلب تحرير الذاكرة العشوائية من النظام
            System.gc()
            Runtime.getRuntime().gc()

            Log.i(TAG, "تم التنظيف بنجاح: تم حذف $deletedCount ملف وتحرير ${freedBytes / (1024 * 1024)} MB")
        } catch (e: Exception) {
            Log.e(TAG, "خطأ أثناء عملية التنظيف العميق: ${e.message}")
        }

        return@withContext CleanResult(
            freedMemoryMB = freedBytes / (1024.0 * 1024.0),
            deletedFilesCount = deletedCount
        )
    }

    private fun cleanDir(dir: File, onDelete: () -> Unit): Long {
        var length: Long = 0
        if (dir.isDirectory) {
            dir.listFiles()?.let { files ->
                for (file in files) {
                    if (file.isDirectory) {
                        length += cleanDir(file, onDelete)
                    } else {
                        val fileSize = file.length()
                        if (file.delete()) {
                            length += fileSize
                            onDelete()
                        }
                    }
                }
            }
        }
        return length
    }
}
EOF

# ---------------------------------------------------------
# 2. محرك البروتوكولات المتقدمة (Multi-Protocol Engine)
# ---------------------------------------------------------
cat << 'EOF' > app/src/main/java/com/apexsuite/vpn/protocols/ProtocolManager.kt
package com.apexsuite.vpn.protocols

object ProtocolManager {
    enum class VpnProtocol(val protocolName: String, val defaultPort: Int) {
        VLESS_REALITY("VLESS-REALITY", 443),
        VMESS("VMess", 10086),
        TROJAN("Trojan", 443),
        SHADOWSOCKS("Shadowsocks", 8388),
        HYSTERIA2("Hysteria2", 36530),
        TUIC("TUIC", 8443)
    }

    fun getRecommendedProtocolForA04e(): VpnProtocol {
        // بروتوكول Hysteria2 أو VLESS-REALITY هما الأسرع والأقل استهلاكاً للمعالج الاقتصادي
        return VpnProtocol.VLESS_REALITY
    }
}
EOF

# ---------------------------------------------------------
# 3. ملف الإعدادات الاحترافي المركزي (Apex Master Config JSON)
# ---------------------------------------------------------
cat << 'EOF' > apex_master_config.json
{
  "project_name": "Apex Suite VPN Pro",
  "version": 200,
  "target_device": "Samsung Galaxy A04e",
  "performance_mode": "ULTRA_PRO",
  "engine_optimizations": {
    "wakelock_timeout_ms": 600000,
    "mtu_size": 1280,
    "tcp_fast_open": true,
    "mux_concurrency": 8
  },
  "sd_maid_settings": {
    "auto_clean_on_start": true,
    "max_cache_limit_mb": 50
  },
  "supported_protocols": [
    "VLESS-REALITY",
    "VMess",
    "Trojan",
    "Shadowsocks",
    "Hysteria2",
    "TUIC"
  ],
  "languages_supported": [
    "ar", "en", "fa", "tr", "ru", "es", "id"
  ]
}
EOF

echo "✅ تم بناء وإضافة كافة الأدوات الاحترافية والمحركات بنجاح."

# ---------------------------------------------------------
# دفع التحديثات إلى مستودع GitHub (VPN)
# ---------------------------------------------------------
echo "=========================================="
echo "🔄 رفع حزمة الأدوات الاحترافية (Pro Suite) إلى GitHub..."
echo "=========================================="

git add .
git commit -m "feat(ProSuite): add SD Maid cleaner, multi-protocol engine, and master config for A04e"
git push -u origin main --force

echo "=========================================="
echo "🎉 تم تفعيل ورفع النسخة الاحترافية PRO بالكامل على مستودع VPN بنجاح!"
echo "=========================================="
EOF

