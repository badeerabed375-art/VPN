package com.apexsuite.vpn.utils

import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL

object SpeedTestManager {
    private const val TEST_FILE_URL = "https://speed.hetzner.de/10MB.bin"

    data class SpeedResult(
        val downloadSpeedMbps: Double,
        val pingMs: Long
    )

    suspend fun measureSpeed(onProgress: (Int) -> Unit): SpeedResult = withContext(Dispatchers.IO) {
        var downloadSpeed = 0.0
        var pingMs: Long = 0

        try {
            val startTime = System.currentTimeMillis()
            val url = URL(TEST_FILE_URL)
            val connection = url.openConnection() as HttpURLConnection
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            connection.connect()

            pingMs = System.currentTimeMillis() - startTime
            val fileSize = connection.contentLength.toLong()
            val inputStream: InputStream = connection.inputStream
            val buffer = ByteArray(8192)
            var bytesDownloaded: Long = 0
            var read: Int
            val downloadStartTime = System.currentTimeMillis()

            while (inputStream.read(buffer).also { read = it } != -1) {
                bytesDownloaded += read
                if (bytesDownloaded > 2 * 1024 * 1024) break
                if (fileSize > 0) {
                    val progress = ((bytesDownloaded * 100) / (2 * 1024 * 1024)).toInt()
                    onProgress(progress.coerceIn(0, 100))
                }
            }

            inputStream.close()
            connection.disconnect()

            val downloadEndTime = System.currentTimeMillis()
            val timeTakenSeconds = (downloadEndTime - downloadStartTime) / 1000.0

            if (timeTakenSeconds > 0) {
                val bitsTotal = bytesDownloaded * 8
                downloadSpeed = (bitsTotal / timeTakenSeconds) / 1_000_000.0
            }
        } catch (e: Exception) {
            Log.e("SpeedTest", "خطأ: ${e.message}")
        }

        return@withContext SpeedResult(
            downloadSpeedMbps = String.format("%.2f", downloadSpeed).toDouble(),
            pingMs = pingMs
        )
    }
}
