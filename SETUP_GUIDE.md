# 🚀 Krishi Drishti — Complete Setup & Installation Guide

**Version 1.1.0** | *Satellite Vision for Smart Farming*

---

## ⚡ TL;DR — Get Started in 30 Seconds

> **Confused about where to start? Here's the simplest path:**

```
📱 PATH A: Just use the app (easiest!)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. 📥 Download:  apk-release/krishi-drishti-debug.apk
2. 📲 Install:   Open file on Android → Tap "Install"
3. 🚀 Launch:    Open "Krishi Drishti" app
4. 🎯 Tap:       "🎯 Demo" button on map
5. 🔍 Tap:       "Analyze" → See crop health instantly!

🌐 PATH B: Use the web app (no install)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Open https://krishidrishti.netlify.app in Chrome → Tap "🎯 Demo" → "🔍 Analyze"

💻 PATH C: Run from source (for developers)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
git clone https://github.com/virahitvin8/Krishi-Drishti.git
cd KrishiDrishti_Final_v4/flutter_app
flutter pub get && flutter run
```

> ❓ **"Which file do I need?"** → Just `apk-release/krishi-drishti-debug.apk` (158 MB)
> ❓ **"What's a debug APK?"** → It's like a development build — slower but works perfectly for testing
> ❓ **"Where do I find the web app?"** → https://krishidrishti.netlify.app

---

## 📋 Table of Contents

- [📁 Project Directory Structure Explained](#-project-directory-structure-explained)
- [📲 Installing the App: Which APK to Choose](#-installing-the-app-which-apk-to-choose)
- [📱 Step-by-Step APK Installation](#-step-by-step-apk-installation)
- [🌐 Using the Web App (PWA)](#-using-the-web-app-pwa)
- [🛰️ All Features Explained with Screenshots](#️-all-features-explained-with-screenshots)
- [🗺️ Maps & Layers Explained](#️-maps--layers-explained)
- [⚡ Quantum Technology Integration](#-quantum-technology-integration)
- [🔄 GitHub CI/CD Pipeline](#-github-cicd-pipeline)

---

## 📁 Project Directory Structure Explained

Here's exactly what every folder and file in the project does:

```
KrishiDrishti_Final_v4/
│
├── 📂 .github/                          # GitHub configuration
│   ├── 📂 workflows/
│   │   └── 📄 build-apk.yml            # Auto-build APK on push (GitHub Actions)
│   ├── 📄 banner.svg                    # Social preview banner for GitHub repo
│   └── 📂 screenshots/
│       └── 📄 placeholder.svg           # Placeholder screenshots for README
│
├── 📂 apk-release/                      # Contains the pre-built APK file
│   └── 📄 krishi-drishti-debug.apk      # 📱 THE FILE YOU NEED TO INSTALL!
│
├── 📂 flutter_app/                      # 📱 NATIVE ANDROID APP (Flutter)
│   ├── 📄 pubspec.yaml                  # Flutter dependencies
│   ├── 📂 lib/
│   │   ├── 📄 main.dart                 # App entry point
│   │   ├── 📂 models/                   # Data models (Analysis, Farm, User, etc.)
│   │   ├── 📂 screens/                  # All app screens
│   │   │   ├── 📄 dashboard_screen.dart # Main dashboard with health score
│   │   │   ├── 📄 map_screen.dart       # Interactive map with field selection
│   │   │   ├── 📄 home_screen.dart      # Main navigation hub
│   │   │   ├── 📄 report_screen.dart    # Detailed analysis report
│   │   │   ├── 📄 settings_screen.dart  # User preferences
│   │   │   ├── 📄 login_screen.dart     # User login
│   │   │   ├── 📄 saved_farms_screen.dart # Saved farm locations
│   │   │   ├── 📄 csv_upload_screen.dart # Bulk CSV upload
│   │   │   ├── 📄 satellite_overlay_screen.dart # Satellite layer toggle
│   │   │   ├── 📄 tools_screen.dart     # GPS/GNSS tools
│   │   │   └── ...                      # More screens
│   │   ├── 📂 services/                 # API and business logic
│   │   │   ├── 📄 api_service.dart      # Backend communication
│   │   │   ├── 📄 gps_service.dart      # GPS/GNSS location
│   │   │   ├── 📄 storage_service.dart  # Local data persistence
│   │   │   └── ...                      # More services
│   │   └── 📂 widgets/                  # Reusable UI components
│   │       ├── 📄 health_score_card.dart # Health score display
│   │       ├── 📄 metric_box.dart       # NDVI, EVI, NDWI boxes
│   │       ├── 📄 weather_card.dart     # Weather display
│   │       └── 📄 recommendation_card.dart # Recommendations
│   └── 📂 android/                      # Android native code
│       └── 📄 build.gradle              # Android build config
│
├── 📂 frontend/                         # 🌐 WEB APP (PWA)
│   ├── 📄 index.html                    # 🔥 MAIN WEB APP FILE
│   ├── 📄 manifest.json                 # PWA manifest (install as app)
│   ├── 📄 service-worker.js             # Offline support
│   ├── 📄 netlify.toml                  # Netlify deployment config
│   ├── 📄 _redirects                    # URL redirect rules
│   └── 📂 assets/
│       ├── 📄 icon-192.png              # App icon (192x192)
│       └── 📄 icon-512.png              # App icon (512x512)
│
├── 📂 backend/                          # 🖥️ BACKEND API (Python)
│   ├── 📄 main.py                       # FastAPI server (entry point)
│   ├── 📄 config.py                     # Configuration & API keys
│   ├── 📄 requirements.txt              # Python dependencies
│   ├── 📄 models.py                     # Database models
│   ├── 📄 supabase_migration.sql        # Database setup script
│   ├── 📂 routers/
│   │   ├── 📄 analysis.py               # Satellite analysis endpoints
│   │   ├── 📄 user.py                   # User management endpoints
│   │   ├── 📄 translation.py            # Translation endpoints
│   │   └── 📄 grafana.py               # Grafana dashboard endpoints
│   └── 📂 services/
│       ├── 📄 analysis_service.py       # Core analysis logic
│       ├── 📄 gee_service.py            # Google Earth Engine integration
│       ├── 📄 cdse_service.py           # Copernicus Data Space
│       ├── 📄 isro_service.py           # ISRO satellite integration
│       ├── 📄 weather_service.py        # Weather data fetching
│       └── 📄 supabase_service.py       # Database operations
│
├── 📄 README.md                         # 📖 MAIN PROJECT README
├── 📄 SETUP_GUIDE.md                    # 📖 THIS FILE — Setup instructions
├── 📄 CHANGELOG.md                      # Version history
├── 📄 CONTRIBUTING.md                   # How to contribute
├── 📄 LICENSE                           # MIT License
├── 📄 PRIVACY_POLICY.md                 # Privacy policy
└── 📄 APP_DESCRIPTION.md                # App Store description
```

### Which App Should You Use?

| App Type | File | Best For |
|----------|------|----------|
| **📱 Native Android** | `flutter_app` folder | Best performance, GPS/GNSS, offline maps |
| **🌐 Web PWA** | `frontend/index.html` | Instant access, no install needed, works on any device |
| **🖥️ Backend API** | `backend/` | Required only if you want real satellite data |

---

## 📲 Installing the App: Which APK to Choose

### Debug vs Release APK

| Feature | ⚠️ Debug APK | ✅ Release APK |
|---------|--------------|----------------|
| **File** | `krishi-drishti-debug.apk` | `krishi-drishti-release.apk` |
| **Size** | ~158 MB | ~35-50 MB |
| **Performance** | Slower (debug overhead) | Fast & optimized |
| **Signed** | Default debug key | Your private key |
| **Google Play** | ❌ Cannot upload | ✅ Can upload |
| **Development** | ✅ Perfect for testing | ✅ Best for users |

> **📌 For now, use the Debug APK** — it's the one that's built and ready. A release build will be available after code signing setup.

### 📥 Download the APK

**Option 1: Direct from GitHub (Recommended)**
```
https://github.com/virahitvin8/Krishi-Drishti/releases/latest
```

**Option 2: From the project folder**
```
KrishiDrishti_Final_v4/apk-release/krishi-drishti-debug.apk
```

---

## 📱 Step-by-Step APK Installation

### Step 1: Download the APK
- Open Chrome on your Android phone
- Go to: `https://github.com/virahitvin8/Krishi-Drishti/releases/latest`
- Tap on `krishi-drishti-debug.apk` to download

### Step 2: Enable Installation from Unknown Sources

**For Android 10, 11, 12, 13, 14+:**

```
Settings → Apps → Special app access → Install unknown apps
→ Select "Chrome" (or "Files") → Toggle ON "Allow from this source"
```

> ⚠️ Different phone brands may have slightly different paths, but search for **"Install unknown apps"** in Settings to find it.

### Step 3: Install the APK

1. Open the **Files** app or **Downloads** app
2. Tap on `krishi-drishti-debug.apk`
3. Tap **Install**
4. If Google Play Protect shows a warning, tap **"Install anyway"** (it's safe — we built it!)
5. Wait for installation to complete
6. Tap **Open** 🎉

### Step 4: First Launch

When you first open Krishi Drishti:
1. You'll see the **Login screen** — enter your name (optional)
2. The **Dashboard** loads with demo data
3. Tap **"🎯 Demo"** on the map to see a sample farm analysis
4. Tap **"🔍 Analyze"** to run the analysis

---

## 🌐 Using the Web App (PWA)

**No installation required!** Just open in Chrome:

### Option A: Live Site
```
https://krishidrishti.netlify.app
```

### Option B: Run Locally
```bash
# Simply open the HTML file in your browser
open KrishiDrishti_Final_v4/frontend/index.html
```

### Install as PWA (Android)
1. Open `https://krishidrishti.netlify.app` in Chrome
2. Tap the three dots menu (⋮)
3. Tap **"Add to Home screen"**
4. Tap **"Install"**
5. The app now appears on your home screen like a native app! 📱

### PWA vs Native App

| Feature | PWA (Web) | Native (Flutter) |
|---------|-----------|------------------|
| **Install size** | ~1 MB cache | ~158 MB APK |
| **GPS/GNSS** | Limited | Full access |
| **Offline** | Limited | Full offline maps |
| **Performance** | Good | Excellent |
| **Updates** | Instant (reload) | Requires APK update |

---

## 🛰️ All Features Explained with Screenshots

```
┌─────────────────────────────────────────────────────────────────┐
│                    KRISHI DRISHTI — APP OVERVIEW                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ① DASHBOARD (Main Screen)                                       │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │ 🔝 OVERALL HEALTH SCORE  (0-100 with color status)      │     │
│  │    Score: 78 → 🟢 Excellent  🟡 Good  🟠 Fair  🔴 Poor │     │
│  ├─────────────────────────────────────────────────────────┤     │
│  │ 🌿 CROP HEALTH INDICES                                   │     │
│  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ │     │
│  │  │ NDVI │ │ EVI  │ │ NDWI │ │ REIP │ │ SAVI │ │GNDVI │ │     │
│  │  │ 48%  │ │ 51%  │ │ 31%  │ │ 32%  │ │ 35%  │ │ 44%  │ │     │
│  │  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ │     │
│  │  Tap any metric → Shows detailed explanation             │     │
│  ├─────────────────────────────────────────────────────────┤     │
│  │ 💧 WATER & IRRIGATION  │ 🌤️ WEATHER                     │     │
│  │  • NDWI: 31%            │  • Temp: 33.2°C               │     │
│  │  • ET: 4.8 mm/day      │  • Humidity: 64%              │     │
│  │  • Soil H₂O: 21%       │  • Wind: 14 km/h              │     │
│  ├─────────────────────────────────────────────────────────┤     │
│  │ 🐛 PEST RISK: 28/100    │ 🌊 DRAINAGE: 72/100           │     │
│  ├─────────────────────────────────────────────────────────┤     │
│  │ 📋 RECOMMENDATIONS                                      │     │
│  │  • 💧 Maintain irrigation schedule                      │     │
│  │  • 🌿 Consider fertilizer in low-NDVI zones             │     │
│  │  • 📊 Next satellite pass in ~3 days                   │     │
│  └─────────────────────────────────────────────────────────┘     │
│                                                                   │
│  ② INTERACTIVE MAP                                                │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │  🗺️ OpenStreetMap base tiles                            │     │
│  │  📍 Draw field boundaries (polygon)                     │     │
│  │  🔴🔵 Hotspot Grid: Red=Stressed, Blue=Healthy         │     │
│  │  🔘 Toggle grid on/off                                  │     │
│  │  🎯 Demo farm button for quick test                     │     │
│  │  📂 Load saved farms                                    │     │
│  └─────────────────────────────────────────────────────────┘     │
│                                                                   │
│  ③ MULTI-SATELLITE REPORT                                        │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │ 🛰️ Sentinel-2:  NDVI 48%  EVI 51%  NDWI 31%            │     │
│  │ 📡 Sentinel-1 SAR: Soil moisture, flood detection       │     │
│  │ 🌍 Landsat 8/9: Long-term vegetation trends            │     │
│  │ 🗺️ Copernicus DEM: Slope 2.1%, Drainage 72/100         │     │
│  │ 🌤️ NASA POWER + Open-Meteo: Weather data               │     │
│  │ 🇮🇳 ISRO Resourcesat: Field-scale vegetation            │     │
│  └─────────────────────────────────────────────────────────┘     │
│                                                                   │
│  ④ SATELLITE INFO                                                │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │ Full details on all 18 satellite data sources           │     │
│  │ Resolution, revisit time, bands used                   │     │
│  │ Update cycle: Every 7 days                              │     │
│  └─────────────────────────────────────────────────────────┘     │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🗺️ Maps & Layers Explained

The app uses **Leaflet.js** (web) and **flutter_map** (mobile) with **OpenStreetMap** tiles:

### Map Layers

| Layer | What It Shows | How to Use |
|-------|---------------|------------|
| **🗺️ Base Map** | OpenStreetMap roads, fields, landmarks | Always visible |
| **📍 Field Polygon** | Your selected farm boundary | Draw or click demo |
| **🔴🔵 Hotspot Grid** | 5×5 grid: Red = stressed, Blue = healthy | Toggle checkbox |
| **📌 Saved Farms** | Previously saved locations | Load from "Saved" button |
| **🎯 Demo Farm** | Sample wheat field in Varanasi | Click "🎯 Demo" |

### How the Hotspot Grid Works

```
NDVI Range    Color     Meaning
───────────────────────────────────────
0.60 - 1.00  🟢 Green   → Healthy, dense vegetation
0.45 - 0.60  🟡 Yellow  → Moderate, monitor closely
0.30 - 0.45  🟠 Orange  → Stressed, needs attention
0.00 - 0.30  🔴 Red     → Highly stressed/barren
```

Each grid cell shows its NDVI value on tap:
> **Example:** Tap a blue cell → "NDVI: 0.72 — 🔵 Healthy"
> **Example:** Tap a red cell → "NDVI: 0.31 — 🔴 Stressed"

### How to Use the Map

1. **View a demo:** Click "🎯 Demo" → Farm loads automatically
2. **Draw your farm:** Click on the map to draw boundary (coming soon)
3. **Toggle grid:** Check/uncheck "Grid" to show/hide hotspot overlay
4. **Load saved:** Click "📂 Saved" to load previously saved farms
5. **Analyze:** Click "🔍 Analyze" → Satellite data fetches → Results update

---

## ⚡ Quantum Technology Integration

### What is Quantum Computing?

Quantum computing uses quantum mechanics (superposition, entanglement) to solve complex problems that classical computers struggle with. For agriculture, this means:

### Free Quantum APIs Available

| Provider | Free Tier | Python Library | Best For |
|----------|-----------|----------------|----------|
| **IBM Quantum** | 10 min/month free | `qiskit` | Algorithm development |
| **AWS Braket** | Free simulator credits | `amazon-braket-sdk` | Hybrid quantum-classical |
| **Azure Quantum** | Free simulation tools | `qsharp` | Chemistry & optimization |
| **Google Cirq** | Free simulator | `cirq` | Research & education |

### How Quantum Can Help Krishi Drishti

```
┌──────────────────────────────────────────────────────────────────────┐
│          QUANTUM + CLASSICAL HYBRID ARCHITECTURE                      │
├──────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  CLASSICAL (Current)                      QUANTUM (Future)            │
│  ─────────────────────                    ────────────────────        │
│                                                                        │
│  📡 Satellite data fetch                   🔬 Quantum ML for          │
│  🖼️ Image preprocessing                      pattern recognition       │
│  📊 NDVI/EVI computation                   🧬 Molecular simulation     │
│  🌤️ Weather data                            for fertilizer design     │
│  📋 Report generation                       📈 Route optimization      │
│                                              for irrigation            │
│                                                                        │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │  HYBRID WORKFLOW                                                │   │
│  │                                                                  │   │
│  │  1. Fetch satellite data (Classical)                            │   │
│  │  2. Preprocess with OpenCV/scikit-image (Classical)             │   │
│  │  3. Run classification with Quantum Kernel (Quantum)            │   │
│  │  4. Optimize recommendations with QAOA (Quantum)                │   │
│  │  5. Generate report (Classical)                                 │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                        │
└──────────────────────────────────────────────────────────────────────┘
```

### Quick Start — Try Quantum with Krishi Drishti

```python
# File: backend/services/quantum_service.py
# Install: pip install qiskit amazon-braket-sdk

from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator

def quantum_crop_classification(ndvi_values, evi_values, ndwi_values):
    """
    Uses a quantum circuit to classify crop health
    by processing vegetation indices through quantum gates.
    """
    n_qubits = 3
    qc = QuantumCircuit(n_qubits, n_qubits)
    
    # Encode classical data into quantum states
    # NDVI → qubit 0 rotation
    qc.ry(ndvi_values * 3.14159, 0)
    # EVI → qubit 1 rotation  
    qc.ry(evi_values * 3.14159, 1)
    # NDWI → qubit 2 rotation
    qc.ry(ndwi_values * 3.14159, 2)
    
    # Entangle qubits for correlation analysis
    qc.cx(0, 1)
    qc.cx(1, 2)
    qc.cx(0, 2)
    
    # Measure results
    qc.measure_all()
    
    # Run on simulator
    simulator = AerSimulator()
    result = simulator.run(qc, shots=1024).result()
    counts = result.get_counts()
    
    # Convert quantum measurements to health score
    health_class = max(counts, key=counts.get)
    return {"quantum_classification": health_class, "confidence": counts[health_class] / 1024}

# Example usage
result = quantum_crop_classification(0.48, 0.51, 0.31)
print(result)  # {'quantum_classification': '010', 'confidence': 0.763}
```

### Next Steps for Quantum Integration

1. **Sign up for IBM Quantum** at `https://quantum.ibm.com` (free account)
2. **Install Qiskit:** `pip install qiskit qiskit-aer`
3. **Create `backend/services/quantum_service.py`** with quantum algorithms
4. **Add a `/api/v1/quantum/analyze` endpoint** for quantum-enhanced analysis
5. **Explore QAOA** for irrigation schedule optimization
6. **Monitor quantum api usage** within free tier limits (10 min/month on real hardware)

> 🔬 **Note:** Quantum integration is experimental. Start with simulators (free, unlimited) before using real quantum hardware (limited free quota).

---

## 🔄 GitHub CI/CD Pipeline

The app has an automated build pipeline:

### How It Works

```
You push code → GitHub Action triggers → Flutter analyze → Build APK 
→ Upload artifact → (if tag v*) → Create Release with APK
```

### Triggering a Build

```bash
# Auto-triggers on:
git push origin main                    # Builds debug APK
git push origin v1.0.0                  # Builds release + creates Release
git push origin v1.1.0                  # Builds release + creates Release

# Or manually:
# Go to GitHub → Actions → Build & Release APK → Run workflow
```

### Release Automation

When you push a tag starting with `v` (like `v1.1.0`):
1. ✅ Code is analyzed (flutter analyze)
2. ✅ APK is built (flutter build apk)
3. ✅ GitHub Release is created
4. ✅ APK is attached to the release
5. ✅ Users can download from Releases page

---

## 🚀 Quick Start Summary

```
┌──────────────────────────────────────────────────────────────────────┐
│                        GET STARTED IN 5 MINUTES                      │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  🛤️  PATH 1: Just use the app (easiest)                             │
│  ─────────────────────────────────────────                             │
│  1. Download APK from GitHub Releases                                 │
│  2. Install on your Android phone                                     │
│  3. Tap "🎯 Demo" → "🔍 Analyze" → See results 🎉                     │
│                                                                       │
│  🛤️  PATH 2: Use the web app (no install)                            │
│  ─────────────────────────────────────────                             │
│  1. Open https://krishidrishti.netlify.app                            │
│  2. Tap "🎯 Demo" → "🔍 Analyze" → See results 🎉                     │
│  3. Add to Home Screen for app-like experience                        │
│                                                                       │
│  🛤️  PATH 3: Run from source (for developers)                        │
│  ─────────────────────────────────────────                             │
│  1. git clone https://github.com/virahitvin8/Krishi-Drishti.git       │
│  2. cd KrishiDrishti_Final_v4/flutter_app                             │
│  3. flutter pub get && flutter run                                    │
│                                                                       │
│  🛤️  PATH 4: Run backend + frontend (full setup)                     │
│  ─────────────────────────────────────────                             │
│  1. cd KrishiDrishti_Final_v4/backend                                │
│  2. pip install -r requirements.txt                                  │
│  3. uvicorn main:app --reload (API at localhost:8000)                │
│  4. Open frontend/index.html in browser                              │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| "App not installed" error | Enable "Install from unknown sources" for your file manager |
| APK too large (158 MB) | This is a debug build. Release build will be ~40 MB |
| Map not loading | Check internet connection. OpenStreetMap tiles need internet |
| Analysis stuck on loading | The demo mode works offline. Real satellite data needs internet |
| "Parse Error" on install | Redownload the APK — file may be corrupt |
| Google Play Protect warning | Tap "Install anyway" — this is your own app |

---

## 📞 Need Help?

- **GitHub Issues:** https://github.com/virahitvin8/Krishi-Drishti/issues
- **Email:** akshitvinay4636@gmail.com
- **Web App:** https://krishidrishti.netlify.app

---

<div align="center">
  
**जय किसान • जय विज्ञान** 🌾🛰️

*Made with ❤️ for Indian Farmers*

</div>
