package com.argusvpn.app.mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import com.wireguard.android.backend.Backend
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.Config
import com.wireguard.config.InetEndpoint
import com.wireguard.config.InetNetwork
import com.wireguard.config.Interface
import com.wireguard.config.Peer
import com.wireguard.crypto.Key
import com.wireguard.crypto.KeyPair
import java.net.InetAddress
import java.util.concurrent.atomic.AtomicBoolean

/**
 * ArgusVpnService — Full-Tunnel WireGuard VPN Engine
 *
 * Uses the official WireGuard GoBackend to encrypt and route 100% of device traffic (0.0.0.0/0)
 * to the remote exit node (e.g. 158.180.31.224 in Frankfurt, Germany).
 */
class ArgusVpnService : Service() {

    companion object {
        const val TAG = "ArgusVpnService"
        const val ACTION_CONNECT    = "com.argusvpn.app.CONNECT"
        const val ACTION_DISCONNECT = "com.argusvpn.app.DISCONNECT"
        const val ACTION_RELOAD     = "com.argusvpn.app.RELOAD"
        const val CHANNEL_ID        = "argus_vpn_channel"
        const val NOTIFICATION_ID   = 1001

        val isRunning: AtomicBoolean = AtomicBoolean(false)
        var activeInstance: ArgusVpnService? = null
        var currentActiveKeyPair: KeyPair? = null

        var currentServerIp: String         = "158.180.31.224"
        var currentServerPort: Int          = 51820
        var currentAssignedIp: String       = "10.8.0.2"
        var currentClientPrivateKey: String = ""
        var currentServerPublicKey: String  = "lrKW+2hSOCZ8XlQoTRJwQ5I73wORkVodEgdsTKQwuAQ="
        var currentDnsServers: List<String> = listOf("1.1.1.1", "1.0.0.1")
        var disallowedPackages: List<String> = emptyList()
        var isKillSwitchActive: Boolean     = false
        var currentServerCity: String       = "Frankfurt"
        var currentServerCountry: String    = "Germany"
        var currentServerFlag: String       = "🇩🇪"

        fun getLiveStatistics(): Map<String, Long> {
            val backendInstance = activeInstance?.backend
            val tunnelInstance = activeInstance?.tunnel
            if (backendInstance != null && tunnelInstance != null && isRunning.get()) {
                try {
                    val stats = backendInstance.getStatistics(tunnelInstance)
                    val rx = stats.totalRx()
                    val tx = stats.totalTx()
                    return mapOf("bytesRx" to rx, "bytesTx" to tx)
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to read live statistics: ${e.message}")
                }
            }
            return mapOf("bytesRx" to 0L, "bytesTx" to 0L)
        }
    }

    private var backend: Backend? = null
    private val tunnel = ArgusTunnel("argus0")
    private val executor = java.util.concurrent.Executors.newSingleThreadExecutor()
    private var currentServerCity: String = "Frankfurt"
    private var currentServerCountry: String = "Germany"
    private var currentServerFlag: String = "🇩🇪"
    private var isLocalLanAccess: Boolean = true
    private var currentPacketMtu: Int = 1420
    private var isStealthMode: Boolean = false

    private class ArgusTunnel(private val name: String) : Tunnel {
        override fun getName(): String = name
        override fun onStateChange(newState: Tunnel.State) {
            Log.i(TAG, "WireGuard Tunnel state changed: $newState")
            isRunning.set(newState == Tunnel.State.UP)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        activeInstance = this
        createNotificationChannel()
        try {
            backend = GoBackend(applicationContext)
            Log.i(TAG, "WireGuard GoBackend initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize WireGuard GoBackend: ${e.message}", e)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: return START_NOT_STICKY

        when (action) {
            ACTION_CONNECT -> {
                currentServerIp         = intent.getStringExtra("serverIp") ?: "158.180.31.224"
                currentServerPort       = intent.getIntExtra("serverPort", 51820)
                currentAssignedIp       = intent.getStringExtra("assignedIp") ?: "10.8.0.2"
                currentClientPrivateKey = intent.getStringExtra("clientPrivateKey") ?: ""
                currentServerPublicKey  = intent.getStringExtra("serverPublicKey") ?: "lrKW+2hSOCZ8XlQoTRJwQ5I73wORkVodEgdsTKQwuAQ="
                currentDnsServers       = intent.getStringArrayListExtra("dnsList") ?: arrayListOf("1.1.1.1", "1.0.0.1")
                disallowedPackages      = intent.getStringArrayListExtra("disallowedPackages") ?: arrayListOf()
                isKillSwitchActive      = intent.getBooleanExtra("killSwitch", false)
                currentServerCity       = intent.getStringExtra("serverCity") ?: "Frankfurt"
                currentServerCountry    = intent.getStringExtra("serverCountry") ?: "Germany"
                currentServerFlag       = intent.getStringExtra("serverFlag") ?: "🇩🇪"
                isLocalLanAccess        = intent.getBooleanExtra("localLanAccess", true)
                currentPacketMtu        = intent.getIntExtra("packetMtu", 1420)
                isStealthMode           = intent.getBooleanExtra("stealthMode", false)

                startForegroundWithNotification()
                startWireGuardTunnel()
            }
            ACTION_RELOAD -> {
                val newDns = intent.getStringArrayListExtra("dnsList")
                if (!newDns.isNullOrEmpty()) {
                    currentDnsServers = newDns
                }
                val newDisallowed = intent.getStringArrayListExtra("disallowedPackages")
                if (newDisallowed != null) {
                    disallowedPackages = newDisallowed
                }
                val newCity = intent.getStringExtra("serverCity")
                if (!newCity.isNullOrEmpty()) {
                    currentServerCity = newCity
                    currentServerCountry = intent.getStringExtra("serverCountry") ?: currentServerCountry
                    currentServerFlag = intent.getStringExtra("serverFlag") ?: currentServerFlag
                }
                isLocalLanAccess = intent.getBooleanExtra("localLanAccess", isLocalLanAccess)
                currentPacketMtu = intent.getIntExtra("packetMtu", currentPacketMtu)
                isStealthMode = intent.getBooleanExtra("stealthMode", isStealthMode)
                updateNotification()
                reloadWireGuardTunnel()
            }
            ACTION_DISCONNECT -> stopWireGuardTunnel()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        if (activeInstance == this) {
            activeInstance = null
        }
        stopWireGuardTunnel()
        super.onDestroy()
    }

    private fun getOrCreateDeviceKeyPair(): KeyPair {
        val prefs = applicationContext.getSharedPreferences("argus_wireguard_keys", Context.MODE_PRIVATE)
        val savedPrivKey = prefs.getString("private_key", null)
        if (!savedPrivKey.isNullOrEmpty()) {
            try {
                return KeyPair(Key.fromBase64(savedPrivKey))
            } catch (e: Exception) {
                Log.w(TAG, "Failed to restore saved private key: ${e.message}")
            }
        }
        val newKeyPair = KeyPair()
        prefs.edit().putString("private_key", newKeyPair.privateKey.toBase64()).apply()
        Log.i(TAG, "Generated and stored permanent device WireGuard keypair")
        return newKeyPair
    }

    private fun startWireGuardTunnel() {
        executor.execute {
            try {
                if (backend == null) {
                    backend = GoBackend(applicationContext)
                    Log.i(TAG, "GoBackend initialized on executor")
                }

                // If tunnel is already running, safely tear down before re-applying config
                if (isRunning.get()) {
                    Log.i(TAG, "Tunnel already active, resetting state before re-configuration...")
                    try {
                        backend?.setState(tunnel, Tunnel.State.DOWN, null)
                        Thread.sleep(100)
                    } catch (e: Exception) {
                        Log.w(TAG, "Notice during tunnel reset: ${e.message}")
                    }
                }

                // STEP 1: Retrieve or generate stable Curve25519 keypair
                Log.i(TAG, "=== STEP 1: Resolving WireGuard Curve25519 keypair ===")
                val keyPair: KeyPair = if (currentClientPrivateKey.isNotEmpty()) {
                    try {
                        KeyPair(Key.fromBase64(currentClientPrivateKey))
                    } catch (_: Exception) {
                        getOrCreateDeviceKeyPair()
                    }
                } else {
                    getOrCreateDeviceKeyPair()
                }
                currentActiveKeyPair = keyPair

                val clientPubKeyBase64 = keyPair.publicKey.toBase64()
                Log.i(TAG, "Client public key: $clientPubKeyBase64")

                // STEP 2: Register peer with remote node daemon BEFORE bringing tunnel up
                Log.i(TAG, "=== STEP 2: Registering peer on node $currentServerIp:4001 ===")
                val remoteAssignedIp = registerPeerOnRemoteNode(currentServerIp, clientPubKeyBase64)
                val ipToUse = remoteAssignedIp ?: currentAssignedIp
                currentAssignedIp = ipToUse
                Log.i(TAG, "Using assigned IP: $ipToUse (from daemon: ${remoteAssignedIp ?: "FAILED, using fallback"})")

                // STEP 3: Build WireGuard config
                Log.i(TAG, "=== STEP 3: Building WireGuard tunnel config ===")
                val cleanIp = ipToUse.split("/")[0]
                val interfaceAddress = InetNetwork.parse("$cleanIp/32")

                val ifaceBuilder = Interface.Builder()
                    .addAddress(interfaceAddress)
                    .setKeyPair(keyPair)

                if (currentPacketMtu in 1280..1500) {
                    try {
                        ifaceBuilder.setMtu(currentPacketMtu)
                    } catch (_: Exception) {}
                }

                // Add DNS servers (fallback to Cloudflare 1.1.1.1 if empty)
                val dnsToApply = if (currentDnsServers.isNotEmpty()) currentDnsServers else listOf("1.1.1.1", "1.0.0.1")
                for (dns in dnsToApply) {
                    try {
                        ifaceBuilder.addDnsServer(InetAddress.getByName(dns))
                        Log.i(TAG, "Added DNS: $dns")
                    } catch (e: Exception) {
                        Log.w(TAG, "Could not add DNS $dns: ${e.message}")
                    }
                }

                // Split Tunneling (Applications to exclude)
                if (disallowedPackages.isNotEmpty()) {
                    ifaceBuilder.excludeApplications(disallowedPackages)
                    Log.i(TAG, "Excluded ${disallowedPackages.size} apps from VPN")
                }

                val builtInterface = ifaceBuilder.build()

                // Parse server endpoint & public key
                val serverPubKey = Key.fromBase64(currentServerPublicKey)
                val portToUse = if (isStealthMode) 443 else currentServerPort
                val endpoint = InetEndpoint.parse("$currentServerIp:$portToUse")
                Log.i(TAG, "Server: $currentServerIp:$portToUse (Stealth: $isStealthMode) | PubKey: $currentServerPublicKey")

                val peerBuilder = Peer.Builder()
                    .setPublicKey(serverPubKey)
                    .setEndpoint(endpoint)
                    .setPersistentKeepalive(25)

                addAllowedIps(peerBuilder, isLocalLanAccess)

                val config = Config.Builder()
                    .setInterface(builtInterface)
                    .addPeer(peerBuilder.build())
                    .build()

                // STEP 4: Bring tunnel UP
                Log.i(TAG, "=== STEP 4: Bringing tunnel UP ===")
                Log.i(TAG, "Config: Interface=$cleanIp/32, Endpoint=$currentServerIp:$currentServerPort, AllowedIPs=0.0.0.0/0, ::/0")
                backend?.setState(tunnel, Tunnel.State.UP, config)
                isRunning.set(true)
                Log.i(TAG, "✓ WireGuard full-tunnel ACTIVE! All traffic -> $currentServerIp (Frankfurt)")

            } catch (e: Exception) {
                Log.e(TAG, "✗ Failed to bring WireGuard tunnel UP: ${e.message}", e)
                isRunning.set(false)
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
    }

    private fun reloadWireGuardTunnel() {
        executor.execute {
            try {
                Log.i(TAG, "=== RELOADING WireGuard Tunnel in-place with new DNS: $currentDnsServers ===")
                if (backend == null) {
                    backend = GoBackend(applicationContext)
                }

                // 1. Maintain exact same Curve25519 keypair and assigned IP
                val keyPair = currentActiveKeyPair ?: if (currentClientPrivateKey.isNotEmpty()) {
                    try {
                        KeyPair(Key.fromBase64(currentClientPrivateKey))
                    } catch (_: Exception) {
                        getOrCreateDeviceKeyPair()
                    }
                } else {
                    getOrCreateDeviceKeyPair()
                }
                currentActiveKeyPair = keyPair

                val cleanIp = currentAssignedIp.split("/")[0]
                val interfaceAddress = InetNetwork.parse("$cleanIp/32")

                val ifaceBuilder = Interface.Builder()
                    .addAddress(interfaceAddress)
                    .setKeyPair(keyPair)

                val dnsToApply = if (currentDnsServers.isNotEmpty()) currentDnsServers else listOf("1.1.1.1", "1.0.0.1")
                for (dns in dnsToApply) {
                    try {
                        ifaceBuilder.addDnsServer(InetAddress.getByName(dns))
                        Log.i(TAG, "Reload Added DNS: $dns")
                    } catch (e: Exception) {
                        Log.w(TAG, "Could not add DNS $dns: ${e.message}")
                    }
                }

                if (disallowedPackages.isNotEmpty()) {
                    ifaceBuilder.excludeApplications(disallowedPackages)
                }

                val builtInterface = ifaceBuilder.build()
                val serverPubKey = Key.fromBase64(currentServerPublicKey)
                val endpoint = InetEndpoint.parse("$currentServerIp:$currentServerPort")

                val peerBuilder = Peer.Builder()
                    .setPublicKey(serverPubKey)
                    .setEndpoint(endpoint)
                    .addAllowedIp(InetNetwork.parse("0.0.0.0/0"))
                    .addAllowedIp(InetNetwork.parse("::/0"))
                    .setPersistentKeepalive(25)

                val config = Config.Builder()
                    .setInterface(builtInterface)
                    .addPeer(peerBuilder.build())
                    .build()

                // 2. In-place configuration update (GoBackend reconfigures TUN interface seamlessly)
                backend?.setState(tunnel, Tunnel.State.UP, config)
                isRunning.set(true)
                Log.i(TAG, "✓ WireGuard tunnel reloaded in-place successfully with new DNS: $currentDnsServers")
            } catch (e: Exception) {
                Log.e(TAG, "✗ Failed to reload WireGuard tunnel: ${e.message}", e)
            }
        }
    }

    private fun registerPeerOnRemoteNode(serverIp: String, clientPublicKey: String): String? {
        try {
            val url = java.net.URL("http://$serverIp:4001/api/peers")
            val conn = url.openConnection() as java.net.HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("x-argus-node-secret", "argus_node_secret_key_123")
            conn.doOutput = true
            conn.connectTimeout = 4000
            conn.readTimeout = 4000

            val jsonBody = org.json.JSONObject().apply {
                put("clientPublicKey", clientPublicKey)
            }

            conn.outputStream.use { os ->
                os.write(jsonBody.toString().toByteArray(Charsets.UTF_8))
            }

            if (conn.responseCode in 200..299) {
                val response = conn.inputStream.bufferedReader().use { it.readText() }
                val json = org.json.JSONObject(response)
                val assignedIp = json.optString("assignedIp", "")
                Log.i(TAG, "✓ Registered WireGuard peer on node $serverIp -> assigned IP: $assignedIp")
                return assignedIp
            } else {
                Log.w(TAG, "Node daemon returned status ${conn.responseCode}")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not reach node daemon for peer registration: ${e.message}")
        }
        return null
    }

    private fun stopWireGuardTunnel() {
        executor.execute {
            try {
                Log.i(TAG, "Tearing down WireGuard tunnel...")
                backend?.setState(tunnel, Tunnel.State.DOWN, null)
            } catch (e: Exception) {
                Log.w(TAG, "Error bringing WireGuard tunnel down: ${e.message}")
            } finally {
                isRunning.set(false)
                stopForeground(STOP_FOREGROUND_REMOVE)
                MainActivity.notifyDisconnect()
                stopSelf()
            }
        }
    }

    // ─────────────────────── Notification ────────────────────────────

    private fun startForegroundWithNotification() {
        val n = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                startForeground(NOTIFICATION_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } catch (_: Exception) {
                startForeground(NOTIFICATION_ID, n)
            }
        } else {
            startForeground(NOTIFICATION_ID, n)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                CHANNEL_ID,
                "Argus VPN Connection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Active WireGuard VPN connection"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(ch)
        }
    }

    fun updateNotification() {
        if (isRunning.get()) {
            try {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                nm?.notify(NOTIFICATION_ID, buildNotification())
            } catch (e: Exception) {
                Log.w(TAG, "Failed to update notification: ${e.message}")
            }
        }
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pi = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val icon = if (applicationInfo.icon != 0) applicationInfo.icon
                   else android.R.drawable.sym_def_app_icon

        val disconnectIntent = Intent(this, ArgusVpnService::class.java).apply {
            action = ACTION_DISCONNECT
        }
        val disconnectPendingIntent = PendingIntent.getService(
            this, 1, disconnectIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val disconnectAction = Notification.Action.Builder(
                null, "Disconnect", disconnectPendingIntent
            ).build()

            Notification.Builder(this, CHANNEL_ID)
                .setSmallIcon(icon)
                .setContentTitle("Argus VPN • Connected")
                .setContentText("Protected by WireGuard • $currentServerFlag $currentServerCity")
                .setContentIntent(pi)
                .addAction(disconnectAction)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setSmallIcon(icon)
                .setContentTitle("Argus VPN • Connected")
                .setContentText("Protected by WireGuard • $currentServerFlag $currentServerCity")
                .setContentIntent(pi)
                .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Disconnect", disconnectPendingIntent)
                .setOngoing(true)
                .build()
        }
    }

    private fun addAllowedIps(peerBuilder: Peer.Builder, allowLocalLan: Boolean) {
        if (!allowLocalLan) {
            peerBuilder.addAllowedIp(InetNetwork.parse("0.0.0.0/0"))
            peerBuilder.addAllowedIp(InetNetwork.parse("::/0"))
        } else {
            val nonLanSubnets = listOf(
                "0.0.0.0/5", "8.0.0.0/7", "11.0.0.0/8", "12.0.0.0/6", "16.0.0.0/4",
                "32.0.0.0/3", "64.0.0.0/2", "128.0.0.0/3", "160.0.0.0/5", "168.0.0.0/6",
                "172.0.0.0/12", "172.32.0.0/11", "172.64.0.0/10", "172.128.0.0/9", "173.0.0.0/8",
                "174.0.0.0/7", "176.0.0.0/4", "192.0.0.0/9", "192.128.0.0/11", "192.160.0.0/13",
                "192.169.0.0/16", "192.170.0.0/15", "192.172.0.0/14", "192.176.0.0/12",
                "192.192.0.0/10", "193.0.0.0/8", "194.0.0.0/7", "196.0.0.0/6", "200.0.0.0/5",
                "208.0.0.0/4", "224.0.0.0/3"
            )
            for (subnet in nonLanSubnets) {
                try {
                    peerBuilder.addAllowedIp(InetNetwork.parse(subnet))
                } catch (_: Exception) {}
            }
            peerBuilder.addAllowedIp(InetNetwork.parse("::/0"))
        }
    }
}
