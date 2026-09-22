package com.apexsuite.vpn.core

import android.net.Uri
import android.util.Log
import java.net.URLDecoder

data class ParsedServer(
    val protocol: String,
    val address: String,
    val port: Int,
    val uuidOrPassword: String,
    val sni: String,
    val path: String,
    val security: String,
    val network: String,
    val pbk: String?,
    val sid: String?,
    val fp: String,
    val remark: String
)

object VpnUrlParser {
    fun parse(url: String): ParsedServer? {
        try {
            val uri = Uri.parse(url.trim())
            val protocol = uri.scheme?.lowercase() ?: return null
            val userInfo = uri.userInfo ?: return null
            val host = uri.host ?: return null
            val port = if (uri.port != -1) uri.port else 443

            val sni = uri.getQueryParameter("sni") ?: host
            val path = uri.getQueryParameter("path") ?: "/"
            val security = uri.getQueryParameter("security") ?: "tls"
            val network = uri.getQueryParameter("type") ?: "tcp"
            val pbk = uri.getQueryParameter("pbk")
            val sid = uri.getQueryParameter("sid")
            val fp = uri.getQueryParameter("fp") ?: "chrome"

            val remark = uri.fragment?.let { 
                URLDecoder.decode(it, "UTF-8") 
            } ?: "سيرفر $protocol"

            return ParsedServer(
                protocol = protocol,
                address = host,
                port = port,
                uuidOrPassword = userInfo,
                sni = sni,
                path = path,
                security = security,
                network = network,
                pbk = pbk,
                sid = sid,
                fp = fp,
                remark = remark
            )
        } catch (e: Exception) {
            Log.e("VpnUrlParser", "خطأ في التحليل: ${e.message}")
            return null
        }
    }
}
