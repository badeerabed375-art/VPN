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
