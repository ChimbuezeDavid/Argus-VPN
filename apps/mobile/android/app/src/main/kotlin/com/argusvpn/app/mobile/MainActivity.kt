package com.argusvpn.app.mobile

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.VpnService
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.ArrayList

class MainActivity : FlutterActivity() {
    private val VPN_CHANNEL = "com.argusvpn.app/vpn"
    private val APPS_CHANNEL = "com.argusvpn.app/installed_apps"
    private val VPN_REQUEST_CODE = 2026

    private var pendingResult: MethodChannel.Result? = null
    private var pendingConnectIntent: Intent? = null
    private var connectivityManager: ConnectivityManager? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    companion object {
        var vpnChannel: MethodChannel? = null
        private val mainHandler = Handler(Looper.getMainLooper())

        fun notifyDisconnect() {
            mainHandler.post {
                vpnChannel?.invokeMethod("onVpnStateChanged", "disconnected")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL)
        vpnChannel = channel
        registerNetworkCallback()

        // 1. VPN Channel for connect / disconnect / status
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareVpn" -> {
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        pendingResult = result
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                    } else {
                        result.success(true)
                    }
                }
                "connectVpn" -> {
                    val serverIp = call.argument<String>("serverIp") ?: "158.180.31.224"
                    val serverPort = call.argument<Int>("serverPort") ?: 51820
                    val assignedIp = call.argument<String>("assignedIp") ?: "10.8.0.2"
                    val clientPrivateKey = call.argument<String>("clientPrivateKey") ?: ""
                    val serverPublicKey = call.argument<String>("serverPublicKey") ?: "lrKW+2hSOCZ8XlQoTRJwQ5I73wORkVodEgdsTKQwuAQ="
                    val dnsList = call.argument<ArrayList<String>>("dnsList") ?: arrayListOf("1.1.1.1", "1.0.0.1")
                    val disallowedPackages = call.argument<ArrayList<String>>("disallowedPackages") ?: arrayListOf()
                    val killSwitch = call.argument<Boolean>("killSwitch") ?: false
                    val serverCity = call.argument<String>("serverCity") ?: "Frankfurt"
                    val serverCountry = call.argument<String>("serverCountry") ?: "Germany"
                    val serverFlag = call.argument<String>("serverFlag") ?: "🇩🇪"
                    val localLanAccess = call.argument<Boolean>("localLanAccess") ?: true
                    val packetMtu = call.argument<Int>("packetMtu") ?: 1420
                    val stealthMode = call.argument<Boolean>("stealthMode") ?: false

                    val intent = Intent(this, ArgusVpnService::class.java).apply {
                        action = ArgusVpnService.ACTION_CONNECT
                        putExtra("serverIp", serverIp)
                        putExtra("serverPort", serverPort)
                        putExtra("assignedIp", assignedIp)
                        putExtra("clientPrivateKey", clientPrivateKey)
                        putExtra("serverPublicKey", serverPublicKey)
                        putStringArrayListExtra("dnsList", dnsList)
                        putStringArrayListExtra("disallowedPackages", disallowedPackages)
                        putExtra("killSwitch", killSwitch)
                        putExtra("serverCity", serverCity)
                        putExtra("serverCountry", serverCountry)
                        putExtra("serverFlag", serverFlag)
                        putExtra("localLanAccess", localLanAccess)
                        putExtra("packetMtu", packetMtu)
                        putExtra("stealthMode", stealthMode)
                    }

                    val prepareIntent = VpnService.prepare(this)
                    if (prepareIntent != null) {
                        pendingConnectIntent = intent
                        pendingResult = result
                        startActivityForResult(prepareIntent, VPN_REQUEST_CODE)
                    } else {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }
                }
                "reloadTunnel" -> {
                    val dnsList = call.argument<ArrayList<String>>("dnsList") ?: arrayListOf("1.1.1.1", "1.0.0.1")
                    val disallowedPackages = call.argument<ArrayList<String>>("disallowedPackages") ?: arrayListOf()
                    val serverCity = call.argument<String>("serverCity")
                    val serverCountry = call.argument<String>("serverCountry")
                    val serverFlag = call.argument<String>("serverFlag")
                    val localLanAccess = call.argument<Boolean>("localLanAccess") ?: true
                    val packetMtu = call.argument<Int>("packetMtu") ?: 1420
                    val stealthMode = call.argument<Boolean>("stealthMode") ?: false

                    val intent = Intent(this, ArgusVpnService::class.java).apply {
                        action = ArgusVpnService.ACTION_RELOAD
                        putStringArrayListExtra("dnsList", dnsList)
                        putStringArrayListExtra("disallowedPackages", disallowedPackages)
                        if (serverCity != null) putExtra("serverCity", serverCity)
                        if (serverCountry != null) putExtra("serverCountry", serverCountry)
                        if (serverFlag != null) putExtra("serverFlag", serverFlag)
                        putExtra("localLanAccess", localLanAccess)
                        putExtra("packetMtu", packetMtu)
                        putExtra("stealthMode", stealthMode)
                    }
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "getCurrentWifiSsid" -> {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? android.net.wifi.WifiManager
                        val info = wifiManager?.connectionInfo
                        var ssid = info?.ssid?.replace("\"", "") ?: ""
                        if (ssid == "<unknown ssid>" || ssid.isEmpty()) {
                            ssid = "Wi-Fi (Protected)"
                        }
                        result.success(ssid)
                    } catch (e: Exception) {
                        result.success("Wi-Fi (Protected)")
                    }
                }
                "getTunnelStats" -> {
                    val stats = ArgusVpnService.getLiveStatistics()
                    result.success(stats)
                }
                "disconnectVpn" -> {
                    val intent = Intent(this, ArgusVpnService::class.java).apply {
                        action = ArgusVpnService.ACTION_DISCONNECT
                    }
                    startService(intent)
                    result.success(true)
                }
                "isVpnRunning" -> {
                    result.success(ArgusVpnService.isRunning.get())
                }
                else -> result.notImplemented()
            }
        }

        // 2. Apps Channel for Split Tunneling: list installed user applications
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APPS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInstalledApps") {
                try {
                    val pm = packageManager
                    val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
                    val appList = mutableListOf<Map<String, Any>>()

                    for (appInfo in packages) {
                        val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                        val appName = pm.getApplicationLabel(appInfo).toString()
                        val packageName = appInfo.packageName

                        if (packageName != applicationContext.packageName) {
                            var iconBytes: ByteArray? = null
                            try {
                                val drawable = pm.getApplicationIcon(appInfo)
                                val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
                                    drawable.bitmap
                                } else {
                                    val w = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth.coerceAtMost(96) else 72
                                    val h = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight.coerceAtMost(96) else 72
                                    val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                                    val canvas = Canvas(bmp)
                                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                                    drawable.draw(canvas)
                                    bmp
                                }
                                val stream = ByteArrayOutputStream()
                                bitmap.compress(Bitmap.CompressFormat.PNG, 80, stream)
                                iconBytes = stream.toByteArray()
                            } catch (_: Exception) {}

                            val map = mutableMapOf<String, Any>(
                                "name" to appName,
                                "packageName" to packageName,
                                "isSystemApp" to isSystem
                            )
                            if (iconBytes != null) {
                                map["icon"] = iconBytes
                            }
                            appList.add(map)
                        }
                    }
                    // Sort alphabetically
                    appList.sortBy { it["name"] as String }
                    result.success(appList)
                } catch (e: Exception) {
                    result.error("APPS_ERROR", "Failed to retrieve apps: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE) {
            val isSuccess = (resultCode == Activity.RESULT_OK)
            if (isSuccess && pendingConnectIntent != null) {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    startForegroundService(pendingConnectIntent)
                } else {
                    startService(pendingConnectIntent)
                }
                pendingConnectIntent = null
            }
            pendingResult?.success(isSuccess)
            pendingResult = null
        }
    }

    private fun registerNetworkCallback() {
        try {
            connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val request = NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .build()

            networkCallback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    val caps = connectivityManager?.getNetworkCapabilities(network)
                    val isWifi = caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
                    val isCellular = caps?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true

                    runOnUiThread {
                        vpnChannel?.invokeMethod("onNetworkAvailable", mapOf(
                            "isWifi" to isWifi,
                            "isCellular" to isCellular
                        ))
                    }
                }

                override fun onLost(network: Network) {
                    runOnUiThread {
                        vpnChannel?.invokeMethod("onNetworkLost", null)
                    }
                }
            }
            connectivityManager?.registerNetworkCallback(request, networkCallback!!)
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "Failed to register network callback: ${e.message}")
        }
    }

    override fun onDestroy() {
        try {
            if (networkCallback != null && connectivityManager != null) {
                connectivityManager?.unregisterNetworkCallback(networkCallback!!)
            }
        } catch (_: Exception) {}
        vpnChannel = null
        super.onDestroy()
    }
}
