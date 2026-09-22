package com.apexsuite.vpn.updater

import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

data class RemoteConfig(
    val version: Int,
    val serverListUrl: String,
    val announcement: String,
    val forceUpdate: Boolean
)

object ConfigUpdater {
    private const val TAG = "ConfigUpdater"
    private const val CONFIG_CHECK_URL = "https://raw.githubusercontent.com/badeerabed375-art/VPN/main/config_update.json"

    suspend fun fetchLatestConfig(): RemoteConfig? = withContext(Dispatchers.IO) {
        try {
            val url = URL(CONFIG_CHECK_URL)
            val connection = url.openConnection() as HttpURLConnection
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            connection.connect()

            if (connection.responseCode == 200) {
                val reader = BufferedReader(InputStreamReader(connection.inputStream))
                val sb = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    sb.append(line)
                }
                reader.close()

                val json = JSONObject(sb.toString())
                return@withContext RemoteConfig(
                    version = json.optInt("version", 1),
                    serverListUrl = json.optString("serverListUrl", ""),
                    announcement = json.optString("announcement", "لا توجد إشعارات جديدة"),
                    forceUpdate = json.optBoolean("forceUpdate", false)
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في جلب التحديثات: ${e.message}")
        }
        return@withContext null
    }
}
