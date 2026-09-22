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
