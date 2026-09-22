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
