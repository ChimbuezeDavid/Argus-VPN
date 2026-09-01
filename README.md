# 🛡️ Argus VPN

> **Next-Generation, High-Performance WireGuard® VPN Ecosystem**  
> Engineered with military-grade Curve25519 cryptography, zero-leak DNS Shield, granular Split Tunneling, and intelligent anti-censorship routing.

---

## 🌟 Overview

**Argus VPN** is an enterprise-grade, privacy-first virtual private network application built for Android, iOS, and multi-platform desktop. Powered by native WireGuard kernel bindings, Argus VPN achieves ultra-low latency, wire-speed throughput, and impenetrable encryption while conserving mobile battery life.

---

## 🚀 Key Features

### 1. ⚡ High-Speed WireGuard® Engine
* **Cryptography**: State-of-the-art Curve25519 key exchange, ChaCha20-Poly1305 authenticated encryption, and BLAKE2s hashing.
* **Native Android GoBackend**: Direct Layer-3 TUN interface managed natively with zero user-space packet copying.
* **Seamless In-Place Reloads**: Dynamic DNS and route modifications without tearing down the cryptographic session.

### 2. 🛡️ Argus DNS Shield & Security Suite
* **Malware & Phishing Protection**: Proactively intercepts malicious domains before TCP connection establishment.
* **Tracker & Ad Blocking**: Built-in DNS-level telemetry filter blocking trackers across all apps.
* **Content Filtering**: Optional 1-tap blocking for adult domains, gambling sites, and distracting social media.
* **Hardware MAC Masking**: Layer-2 hardware address isolation to prevent local hotspot and ISP fingerprinting.
* **Custom DNS Resolvers**: Support for NextDNS, Cloudflare, Google, AdGuard Home, Pi-hole, or private custom DNS servers.

### 3. ⚙️ 6 Advanced Configuration Suites
1. **Decoy Traffic (Chaff Injector)**: Randomized background synthetic dummy bursts over the tunnel to defeat AI-driven ISP traffic correlation and flow analysis.
2. **Stealth Censorship Bypass**: Camouflages WireGuard handshakes and packet streams through port 443 with TLS/WebSocket framing to bypass Deep Packet Inspection (DPI).
3. **Trusted Wi-Fi Networks & Auto-Secure**: Automatically secures public/untrusted Wi-Fi hotspots and seamlessly pauses encryption on verified home/office SSIDs.
4. **Local LAN Traffic Access**: Excludes RFC 1918 private subnets (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) so Chromecast, smart TVs, local printers, and Samba/Plex shares remain accessible.
5. **Packet MTU & MSS Tuner**: Dynamic MTU adjustment (`1280`–`1500` bytes) with instant presets (*Safe 1280 B*, *Optimal 1420 B*, *LAN Max 1500 B*) to eliminate carrier packet fragmentation.
6. **Ephemeral Port Forwarding Manager**: Dynamic 24-hour port leasing (ports `49152`–`65535`) on active WireGuard nodes for high-speed P2P, BitTorrent, and gaming server hosting.

### 4. 🔀 Intelligent Split Tunneling
* **Per-App Routing**: Route sensitive banking or streaming apps through the local ISP while keeping other traffic encrypted.
* **Real Application Icons**: Native Android package manager integration extracts and renders crisp PNG application icons in the bypass manager.

### 5. 🌍 Worldwide Global Node Fleet
* **Multi-Continent Network**: Over 50+ high-bandwidth server nodes across Europe, Americas, Asia-Pacific, Middle East, and Africa.
* **Live Latency Ping**: Real-time ICMP/TCP ping testing to auto-select optimal servers.
* **Windscribe-Style Country Accordions**: Clean hierarchical location listing with load percentages and ping metrics.

### 6. 🎨 Human-Computer Interaction (HCI) Compliant UI
* **Dynamic 3D Rotating Globe**: Interactive spherical globe rendering connected nodes and orbital visual feedback.
* **Adaptive Theme Engine**: Flawless Light and Dark themes with contrast-optimized typography and responsive controls.
* **Live Telemetry HUD**: Real-time download/upload speed gauges, data transfer counters, and session duration timers.

---

## 🏗️ Project Architecture

```
Argus-VPN/
├── apps/
│   └── mobile/                      # Flutter mobile client application
│       ├── android/                 # Native Android GoBackend & VpnService
│       │   └── app/src/main/kotlin/com/argusvpn/app/mobile/
│       │       ├── ArgusVpnService.kt   # Native WireGuard VPN Engine
│       │       └── MainActivity.kt      # MethodChannel & System APIs
│       └── lib/
│           ├── config/              # App themes, colors & endpoints
│           ├── models/              # Data models (Shield, Profile, Server)
│           ├── providers/           # State management (VpnProvider)
│           ├── screens/             # UI screens (Dashboard, Settings, Shield, Servers)
│           ├── services/            # WireGuard tunnel, API & storage services
│           └── widgets/             # 3D Globe, custom cards, gauges & painters
├── packages/                        # Shared libraries & utilities
├── services/                        # Backend API & node daemon orchestrator
└── infra/                           # Infrastructure & deployment scripts
```

---

## 🛠️ Getting Started & Build Instructions

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.29.0 or later)
* [Android SDK](https://developer.android.com/studio) (API level 24+)
* [Node.js](https://nodejs.org/) (v18+)

### 1. Clone the Repository
```bash
git clone https://github.com/ChimbuezeDavid/Argus-VPN.git
cd Argus-VPN
```

### 2. Install Dependencies
```bash
# Monorepo dependencies
npm install

# Mobile app dependencies
cd apps/mobile
flutter pub get
```

### 3. Run Development Build
```bash
# Connect an Android device or launch emulator
flutter run
```

### 4. Build Installable APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```
*Generated APK location*: `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`

---

## 🔒 Security & Privacy Policy

* **Zero Logs Policy**: No traffic, DNS queries, browsing metadata, or IP logs are ever stored or recorded.
* **Forward Secrecy**: WireGuard Curve25519 keypairs are periodically refreshed.
* **DNS Leak Protection**: All DNS requests are routed inside the encrypted WireGuard tunnel to private DNS resolvers.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
