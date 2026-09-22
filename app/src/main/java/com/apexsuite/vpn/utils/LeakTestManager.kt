package com.apexsuite.vpn.utils

import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

object LeakTestManager {
    data class LeakInfo(
        val ip: String,
        val country: String,
        val city: String,
        val isp: String
    )

    suspend fun performLeakTest(): LeakInfo? = withContext(Dispatchers.IO) {
        try {
            val url = URL("https://ipapi.co/json/")
            val connection = url.openConnection() as HttpURLConnection
            connection.connectTimeout = 6000
            connection.readTimeout = 6000
            connection.setRequestProperty("User-Agent", "ApexSuite-VPN")
            connection.connect()

            if (connection.responseCode == 200) {
                val reader = BufferedReader(InputStreamReader(connection.inputStream))
                val response = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    response.append(line)
                }
                reader.close()

                val json = JSONObject(response.toString())
                return@withContext LeakInfo(
                    ip = json.optString("ip", "غير معروف"),
                    country = json.optString("country_name", "غير معروف"),
                    city = json.optString("city", "غير معروف"),
                    isp = json.optString("org", "غير معروف")
                )
            }
        } catch (e: Exception) {
            Log.e("LeakTest", "خطأ: ${e.message}")
        }
        return@withContext null
    }
}
