<div align="center">
  <img src="https://raw.githubusercontent.com/virahitvin8/Krishi-Drishti/main/.github/banner.svg" alt="Krishi Drishti Banner" width="100%">
</div>

<br>

<div align="center">
  
  # 🌾 Krishi Drishti — कृषि दृष्टि
  
  ### *Satellite Vision for Smart Farming*
  
  **Free satellite-based crop health monitoring for Indian farmers.**
  
  <br>
  
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
  [![FastAPI](https://img.shields.io/badge/FastAPI-05998B?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
  [![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
  [![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
  [![Leaflet](https://img.shields.io/badge/Leaflet-199900?style=for-the-badge&logo=leaflet&logoColor=white)](https://leafletjs.com)
  [![Netlify](https://img.shields.io/badge/Netlify-00C7B7?style=for-the-badge&logo=netlify&logoColor=white)](https://netlify.com)

  <br>

  [![GitHub Release](https://img.shields.io/github/v/release/virahitvin8/Krishi-Drishti?style=flat-square&logo=github&color=2ECC71)](https://github.com/virahitvin8/Krishi-Drishti/releases)
  [![Build APK](https://img.shields.io/github/actions/workflow/status/virahitvin8/Krishi-Drishti/build-apk.yml?style=flat-square&logo=githubactions&logoColor=white&label=build)](https://github.com/virahitvin8/Krishi-Drishti/actions)
  [![GitHub Downloads](https://img.shields.io/github/downloads/virahitvin8/Krishi-Drishti/total?style=flat-square&logo=github&color=3498DB)](https://github.com/virahitvin8/Krishi-Drishti/releases)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
  [![GitHub Stars](https://img.shields.io/github/stars/virahitvin8/Krishi-Drishti?style=flat-square&logo=github&color=8E44AD)](https://github.com/virahitvin8/Krishi-Drishti/stargazers)
  [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](CONTRIBUTING.md)
  [![GitHub Issues](https://img.shields.io/github/issues/virahitvin8/Krishi-Drishti?style=flat-square&logo=github&color=E74C3C)](https://github.com/virahitvin8/Krishi-Drishti/issues)

  <br>
  
  <a href="#-download-apk">
    <img src="https://img.shields.io/badge/📲%20Download%20APK-2E7D32?style=for-the-badge&logo=android" alt="Download APK">
  </a>
  <a href="https://krishidrishti.netlify.app">
    <img src="https://img.shields.io/badge/🌐%20Web%20App-1976D2?style=for-the-badge&logo=googlechrome" alt="Web App">
  </a>
  <a href="#-quick-start">
    <img src="https://img.shields.io/badge/🚀%20Quick%20Start-F9A825?style=for-the-badge" alt="Quick Start">
  </a>

  <br>
  <br>

  <p><b>Made with ❤️ for Indian Farmers • जय किसान 🌾</b></p>
  
  <sub>Supported Languages: English • हिन्दी • తెలుగు</sub>
  
</div>

<br>

---

<details open>
  <summary><b>📋 Table of Contents</b></summary>
  <br>

- [✨ Features](#-features)
- [🛰️ How It Works](#️-how-it-works)
- [📲 Download APK](#-download-apk)
- [🏗️ System Architecture](#️-system-architecture)
- [🛠️ Technology Stack](#️-technology-stack)
- [📱 Screenshots](#-screenshots)
- [📡 Satellite Data Sources](#-satellite-data-sources)
- [🚀 Quick Start](#-quick-start)
- [📖 API Endpoints](#-api-endpoints)
- [🌍 Deployment](#-deployment)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)
- [🙏 Acknowledgments](#-acknowledgments)
- [📬 Contact](#-contact)

</details>

---

## ✨ Features

<div align="center">
  
| | Feature | Description |
|---|---|---|
| 🛰️ | **Multi-Satellite Analysis** | Sentinel-2, Sentinel-1 SAR, Landsat 8/9, ISRO Resourcesat |
| 🌿 | **Crop Health Indices** | NDVI, EVI, NDWI, GNDVI, REIP, SAVI — all with % breakdowns |
| 📊 | **Overall Health Score** | 0–100 score with color-coded status (Excellent → Critical) |
| 🗺️ | **Interactive Hotspot Grid** | Transparent grid showing stressed (🔴) vs. healthy (🔵) zones |
| 🌤️ | **Weather Integration** | Live weather, 3-day forecast, evapotranspiration data |
| 💧 | **Irrigation Advice** | Smart recommendations combining NDWI + weather + soil moisture |
| 🐛 | **Pest Risk Scoring** | Machine learning risk assessment based on humidity, temp & REIP |
| 🏔️ | **Topography & Drainage** | Slope, aspect, drainage analysis from Copernicus DEM |
| 📄 | **CSV Batch Upload** | Upload multiple field coordinates for bulk analysis |
| 📱 | **PWA + Native App** | Works as installable PWA and native Android (Flutter) app |
| 🌐 | **Multi-lingual** | English, हिन्दी, తెలుగు — with more coming soon |
| 📈 | **Grafana Dashboard** | Real-time monitoring with interactive visualizations |
| 💾 | **Save & Track Farms** | Save farm locations and track health over time |

</div>

---

## 🛰️ How It Works

```
┌──────────────────────────────────────────────────────────────────────┐
│                        Krishi Drishti Flow                           │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ① SELECT LAND                                                        │
│     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐      │
│     │ Draw on Map  │     │ Enter Coords │     │  Upload CSV  │      │
│     └──────┬───────┘     └──────┬───────┘     └──────┬───────┘      │
│            └────────────────────┼────────────────────┘              │
│                                 ▼                                   │
│  ② FETCH SATELLITE DATA                                             │
│     ┌─────────────────────────────────────────────────────────┐     │
│     │  Sentinel-2  •  Sentinel-1  •  Landsat  •  NASA POWER   │     │
│     │  Open-Meteo  •  Copernicus DEM  •  ISRO Resourcesat     │     │
│     └─────────────────────────┬───────────────────────────────┘     │
│                               ▼                                     │
│  ③ COMPUTE INDICES                                                  │
│     ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐   │
│     │ NDVI │  │ EVI  │  │ NDWI │  │ REIP │  │ SAVI │  │GNDVI │   │
│     └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘   │
│        └─────────┴─────────┴─────────┴─────────┴─────────┘        │
│                               ▼                                     │
│  ④ GENERATE INSIGHTS                                                │
│     ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐      │
│     │ Health Score │  │  Pest Risk   │  │ Recommendations  │      │
│     │  0–100       │  │  Low/Med/High│  │  Actionable tips │      │
│     └──────────────┘  └──────────────┘  └──────────────────┘      │
│                               ▼                                     │
│  ⑤ VISUALIZE                                                        │
│     ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐      │
│     │ Hotspot Grid │  │  Time Series │  │  Grafana Dash    │      │
│     │  Map overlay │  │  Chart View  │  │  Live Monitor    │      │
│     └──────────────┘  └──────────────┘  └──────────────────┘      │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Step-by-Step

1. **📍 Select your land** — Draw on the interactive map, enter GPS coordinates, or upload a CSV file with multiple field locations
2. **🛰️ Satellite scans your farm** — The system fetches the latest available imagery from Sentinel-2 (10m resolution), Sentinel-1 SAR (all-weather radar), and Landsat 8/9
3. **📊 AI analyzes crop health** — Advanced vegetation indices are computed: NDVI (vigor), EVI (canopy), NDWI (water), REIP (early stress detection), SAVI (soil-adjusted), and GNDVI (chlorophyll)
4. **📋 Get instant results** — Clear visual dashboard shows your overall health score, individual index breakdowns, weather data, pest risk assessment, and personalized recommendations
5. **📈 Track over time** — Save your farms and monitor changes with periodic satellite passes. View trends via the integrated Grafana dashboard

---

## 📲 Download APK

<div align="center">

### 📱 Android App (Flutter Native)

[![Download Latest APK](https://img.shields.io/badge/📲%20Download%20APK%20v1.0.0-2E7D32?style=for-the-badge&logo=android&logoColor=white)](https://github.com/virahitvin8/Krishi-Drishti/releases/latest)

</div>

| Version | Size | Android | Download |
|---------|------|---------|----------|
| **v1.0.0** (Debug) | 158.8 MB | 5.0+ | [⬇️ Download APK](https://github.com/virahitvin8/Krishi-Drishti/releases/latest) |
| **v1.0.0** (Debug APK) | 158.8 MB | 5.0+ | [⬇️ krishi-drishti-debug.apk](https://github.com/virahitvin8/Krishi-Drishti/releases/download/v1.0.0/krishi-drishti-debug.apk) |

> **Note:** The APK is a debug build. A release build with code signing will be available soon.

### Installation Steps

1. Download the APK from the link above
2. On your Android device, go to **Settings → Security → Install unknown apps**
3. Enable **"Allow from this source"** for your file manager
4. Open the downloaded APK and tap **Install**
5. Launch **Krishi Drishti** and start monitoring your farm! 🎉

### 🌐 Also Available as PWA

Open [krishidrishti.netlify.app](https://krishidrishti.netlify.app) in Chrome on your phone → tap **"Add to Home Screen"** to install the PWA version (works offline!).

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           KRISHI DRISHTI ARCHITECTURE                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────┐    ┌─────────────────────────────────────────┐ │
│  │    CLIENT LAYER      │    │            API LAYER                    │ │
│  │                      │    │                                         │ │
│  │  ┌─────────────────┐ │    │  ┌─────────────────────────────────┐   │ │
│  │  │  Flutter App     │ │    │  │  FastAPI Backend (Python)       │   │ │
│  │  │  (Android/iOS)   │◄├───┼──┤  • Analysis Engine              │   │ │
│  │  └─────────────────┘ │    │  │  • CDSE Integration             │   │ │
│  │                      │    │  │  • GEE Integration              │   │ │
│  │  ┌─────────────────┐ │    │  │  • ISRO Bhoonidhi              │   │ │
│  │  │  PWA Web App     │ │    │  │  • Weather Service             │   │ │
│  │  │  (Leaflet Map)   │◄├───┼──┤  • Translation Engine          │   │ │
│  │  └─────────────────┘ │    │  │  • Grafana Query API           │   │ │
│  │                      │    │  │  • User Management             │   │ │
│  │  ┌─────────────────┐ │    │  │  • CSV Batch Processing        │   │ │
│  │  │  Grafana Dash.   │ │    │  └─────────────────────────────────┘   │ │
│  │  │  (Monitoring)    │◄├───┼────────────────────────────────────┘   │ │
│  │  └─────────────────┘ │    │                                         │ │
│  └─────────────────────┘    └─────────────────────────────────────────┘ │
│                                                                          │
│  ┌─────────────────────┐    ┌─────────────────────────────────────────┐ │
│  │   SATELLITE SOURCES  │    │         STORAGE LAYER                  │ │
│  │                      │    │                                         │ │
│  │  🛰️ Sentinel-2 A/B   │    │  ┌─────────────────────────────────┐   │ │
│  │  📡 Sentinel-1 SAR   │    │  │  Supabase (PostgreSQL)          │   │ │
│  │  🌍 Landsat 8/9      │    │  │  • User profiles                │   │ │
│  │  🇮🇳 ISRO Resourcesat│    │  │  • Saved farms                  │   │ │
│  │  🌤️ NASA POWER       │    │  │  • Analysis history             │   │ │
│  │  🌧️ Open-Meteo       │    │  └─────────────────────────────────┘   │ │
│  │  🗺️ Copernicus DEM   │    │                                         │ │
│  └─────────────────────┘    │  ┌─────────────────────────────────┐   │ │
│                              │  │  Local Storage (PWA/Flutter)   │   │ │
│                              │  │  • Farm cache                  │   │ │
│                              │  │  • User preferences            │   │ │
│                              │  └─────────────────────────────────┘   │ │
│                              └─────────────────────────────────────────┘ │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  DEPLOYMENT                                                      │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐│   │
│  │  │  Netlify     │  │  Render      │  │  GitHub Actions        ││   │
│  │  │  (Frontend)  │  │  (Backend)   │  │  (CI/CD + APK Build)   ││   │
│  │  └──────────────┘  └──────────────┘  └────────────────────────┘│   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack

### Frontend (Mobile App)
| Technology | Purpose |
|------------|---------|
| [Flutter](https://flutter.dev) 3.4+ | Cross-platform mobile framework |
| [Dart](https://dart.dev) 3.4+ | Programming language |
| [flutter_map](https://pub.dev/packages/flutter_map) + OpenStreetMap | Interactive map with field boundary drawing |
| [Provider](https://pub.dev/packages/provider) | State management |
| [geolocator](https://pub.dev/packages/geolocator) | GPS/GNSS location services |
| [http](https://pub.dev/packages/http) | API communication |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | Local storage |
| [shimmer](https://pub.dev/packages/shimmer) | Loading animations |
| [cached_network_image](https://pub.dev/packages/cached_network_image) | Image caching |

### Frontend (Web PWA)
| Technology | Purpose |
|------------|---------|
| HTML5 + CSS3 | Structure & styling |
| [Tailwind CSS](https://tailwindcss.com) | Utility-first styling via CDN |
| [Leaflet.js](https://leafletjs.com) | Interactive satellite map |
| [OpenStreetMap](https://openstreetmap.org) | Base map tiles |
| PWA Service Worker | Offline caching & installability |

### Backend
| Technology | Purpose |
|------------|---------|
| [Python](https://python.org) 3.11+ | Backend language |
| [FastAPI](https://fastapi.tiangolo.com) | High-performance REST API framework |
| [Uvicorn](https://uvicorn.org) | ASGI server |
| [httpx](https://www.python-httpx.org) | Async HTTP client for satellite APIs |
| [Google Earth Engine API](https://developers.google.com/earth-engine) | Satellite data processing |
| [Supabase](https://supabase.com) | PostgreSQL database + auth |

### Data Sources
| Source | Data Provided |
|--------|--------------|
| **Sentinel-2** (ESA Copernicus) | 10m optical imagery — NDVI, EVI, NDWI, REIP, SAVI |
| **Sentinel-1 SAR** (ESA Copernicus) | 10m all-weather radar — soil moisture, flood detection |
| **Landsat 8/9** (NASA/USGS) | 30m optical — long-term vegetation trends since 1982 |
| **Copernicus DEM** (ESA) | 30m elevation — slope, aspect, drainage analysis |
| **NASA POWER** | Temperature, humidity, solar radiation, ET |
| **Open-Meteo** | Free weather forecast (3-day) |
| **ISRO Resourcesat** (LISS-IV) | 5.8m multispectral — field-scale vegetation |
| **ISRO RISAT-1A** (SAR) | 3–25m all-weather radar |
| **ISRO HySIS** | 30m hyperspectral (55 bands) — crop chemistry (N, P, K) |

### DevOps & CI/CD
| Tool | Purpose |
|------|---------|
| [GitHub Actions](https://github.com/features/actions) | CI/CD — auto-build APK on push & tags |
| [Netlify](https://netlify.com) | PWA hosting with automatic deploys |
| [Render](https://render.com) | Backend hosting with health checks |
| [Harness CI](https://harness.io) | Alternative CI pipeline (free tier) |
| [Grafana](https://grafana.com) | Real-time monitoring dashboard |

---

## 📱 Screenshots

<div align="center">
  <table>
    <tr>
      <td align="center"><b>🌿 Dashboard</b></td>
      <td align="center"><b>📊 Full Report</b></td>
      <td align="center"><b>⚙️ Settings</b></td>
    </tr>
    <tr>
      <td>
        <img src="https://raw.githubusercontent.com/virahitvin8/Krishi-Drishti/main/.github/screenshots/placeholder.svg" alt="Dashboard" width="250px"/>
        <br>
        <sub>Overall health score, crop indices, weather, pest risk & recommendations</sub>
      </td>
      <td>
        <img src="https://raw.githubusercontent.com/virahitvin8/Krishi-Drishti/main/.github/screenshots/placeholder.svg" alt="Report" width="250px"/>
        <br>
        <sub>Multi-satellite report with all indices & recommendations</sub>
      </td>
      <td>
        <img src="https://raw.githubusercontent.com/virahitvin8/Krishi-Drishti/main/.github/screenshots/placeholder.svg" alt="Settings" width="250px"/>
        <br>
        <sub>Profile, language, state & data preferences</sub>
      </td>
    </tr>
  </table>
  
  <br>
  <p><i>🎯 <b>Live screenshots coming soon!</b> Open the <a href="https://krishidrishti.netlify.app">Web App</a> or download the <a href="#-download-apk">APK</a> to see the full UI in action.</i></p>
  <p><sub>The placeholder above shows a wireframe preview of the app interface.</sub></p>
</div>

---

## 📡 Satellite Data Sources

Krishi Drishti integrates data from **18+ satellite and earth observation sources** to provide comprehensive farm analysis:

| # | Source | Type | Resolution | Revisit | Key Use |
|---|--------|------|-----------|---------|---------|
| 1 | 🛰️ **Sentinel-2 A/B** (ESA) | Optical | **10 m** | 5-day | NDVI, EVI, NDWI, GNDVI, SAVI |
| 2 | 📡 **Sentinel-1 SAR** (ESA) | Radar | **10 m** | 6-day | Soil moisture, flood detection |
| 3 | 🌍 **Landsat 8/9** (NASA/USGS) | Optical | **30 m** | 8-day | Long-term veg trends (since 1982) |
| 4 | 🔥 **Sentinel-3 SLSTR** (ESA) | Thermal | 1 km | Daily | Land surface temperature |
| 5 | 💧 **Sentinel-3 OLCI** (ESA) | Optical | 300 m | Daily | Chlorophyll, water quality |
| 6 | 🌱 **SMAP** (NASA) | Radar | 10 km | 3-day | Surface soil moisture |
| 7 | 🌊 **GRACE-FO** (NASA) | Gravity | — | Monthly | Groundwater anomaly trends |
| 8 | 📊 **MODIS NDVI** (NASA) | Optical | 250 m | 16-day | Long-term vegetation trends |
| 9 | 🌧️ **CHIRPS** (UCSB) | Rainfall | 5.5 km | Daily | Precipitation |
| 10 | 🗺️ **Copernicus DEM** (ESA) | Elevation | **30 m** | Static | Slope, aspect, drainage |
| 11 | 🧪 **OpenLandMap** (ISRIC) | Soil | 250 m | Static | Texture, pH, organic C |
| 12 | 🌡️ **ERA5-Land** (ECMWF) | Reanalysis | 11 km | Hourly | Climate reanalysis |
| 13 | ☀️ **NASA POWER** | Meteorology | 0.5° | Daily | Temp, humidity, solar, ET |
| 14 | 🌤️ **Open-Meteo** | Forecast | 5 km | 3-day | Free weather forecast |
| 15 | 🇮🇳 **Cartosat-3** (ISRO) | Optical | **0.25 m** | 5-day | Sub-meter crop stress |
| 16 | 🇮🇳 **Resourcesat-2 LISS-IV** (ISRO) | Optical | **5.8 m** | 5-day | Field-scale vegetation |
| 17 | 🇮🇳 **HySIS** (ISRO) | Hyperspectral | **30 m** (55 bands) | 30-day | Crop chemistry (N, P, K) |
| 18 | 🇮🇳 **RISAT-1A** (ISRO) | SAR | 3–25 m | 12-day | All-weather radar |

---

## 🚀 Quick Start

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.4+
- [Python](https://python.org) 3.11+
- Android Studio or VS Code (for Flutter)

### Clone & Run

```bash
# Clone the repository
git clone https://github.com/virahitvin8/Krishi-Drishti.git
cd Krishi-Drishti

# Navigate to the project directory
cd KrishiDrishti_Final_v4

# ─── Run the Flutter Mobile App ───
cd flutter_app
flutter pub get
flutter run          # Run on connected device/emulator

# ─── Build APK for Android ───
flutter build apk --debug   # Debug APK (~159 MB)
flutter build apk --release # Release APK (requires signing)

# ─── Run the Backend API ───
cd ../backend
pip install -r requirements.txt
uvicorn main:app --reload   # API at http://localhost:8000

# ─── View API Documentation ───
# Open http://localhost:8000/docs in your browser
```

### Deploy Frontend (Netlify)

```bash
# Push to GitHub, then:
# 1. Go to netlify.com → "Import from Git"
# 2. Select your repo
# 3. Publish directory: `frontend`
# 4. Deploy!
```

### Deploy Backend (Render)

```bash
# 1. Go to render.com → "New Web Service"
# 2. Connect your GitHub repo
# 3. Root directory: `backend`
# 4. Build: `pip install -r requirements.txt`
# 5. Start: `uvicorn main:app --host 0.0.0.0 --port $PORT`
```

---

## 📖 API Endpoints

Once the backend is running, explore the full API at [http://localhost:8000/docs](http://localhost:8000/docs) (Swagger UI).

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Root — API info & all available endpoints |
| `/health` | GET | Health check for monitoring |
| `/api/v1/analyze` | POST | Analyze a field by polygon coordinates |
| `/api/v1/dashboard` | GET | Get dashboard data for a farm |
| `/api/v1/upload-csv` | POST | Batch upload CSV of field coordinates |
| `/api/v1/schedule` | GET | Satellite data refresh schedule |
| `/api/v1/report/{field_id}` | GET | Detailed report for a specific field |
| `/api/v1/satellites` | GET | Available satellite data sources |
| `/api/v1/translate/{language}` | GET | Translation endpoints |
| `/api/v1/grafana/dashboard-json` | GET | Grafana dashboard JSON config |
| `/api/v1/grafana/query/*` | GET | Grafana query proxy endpoints |
| `/api/v1/user/register` | POST | Register a new user |
| `/api/v1/user/{username}` | GET | Get user profile |

---

## 🌍 Deployment

### Live URLs
| Service | URL |
|---------|-----|
| 🌐 **Web App (PWA)** | [krishidrishti.netlify.app](https://krishidrishti.netlify.app) |
| 🖥️ **Backend API** | [krishi-drishti-backend.onrender.com](https://krishi-drishti-backend.onrender.com) |
| 📄 **API Docs** | [krishi-drishti-backend.onrender.com/docs](https://krishi-drishti-backend.onrender.com/docs) |
| 📈 **Grafana** | Configure via `/api/v1/grafana/dashboard-json` |

### CI/CD Pipeline
The project uses **GitHub Actions** for continuous integration:

- **On push/PR** → Runs `flutter analyze` and builds debug APK
- **On tag `v*`** → Builds release APK and creates a GitHub Release with the APK attached
- **Manual trigger** → Workflow dispatch with build type selection

---

## 🤝 Contributing

We welcome contributions from developers, agriculturists, translators, and designers! Check out [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Ways to Contribute

| Area | How to Help |
|------|-------------|
| 🌐 **Translations** | Add Hindi, Tamil, Telugu, Marathi translations |
| 🐛 **Bug Fixes** | Open issues and submit PRs for bugs |
| 🛰️ **Satellite Integration** | Add new data sources (ISRO, NASA, etc.) |
| 📱 **Mobile UX** | Improve the Flutter app experience |
| 📊 **Pest Models** | Improve early detection algorithms |
| 🌍 **Documentation** | Help with farmer guides & documentation |

### Quick Contribution Flow

```bash
git checkout -b feature/your-awesome-feature
# Make your changes
git commit -m "feat: add your awesome feature"
git push origin feature/your-awesome-feature
# Open a Pull Request 🚀
```

---

## 📜 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

Copyright © 2026 Neelam Akshit Vinay

---

## 🙏 Acknowledgments

- **[ESA Copernicus](https://copernicus.eu)** — Free & open Sentinel satellite data
- **[NASA Earth Science](https://earthdata.nasa.gov)** — Earth observation data & POWER API
- **[ISRO](https://www.isro.gov.in)** — Indian satellite missions (Resourcesat, Cartosat, HySIS)
- **[OpenStreetMap](https://openstreetmap.org)** — Free map tiles & geographic data
- **[Flutter Team](https://flutter.dev)** — Amazing cross-platform framework
- **[FastAPI Team](https://fastapi.tiangolo.com)** — High-performance Python API framework
- **[Leaflet.js](https://leafletjs.com)** — Lightweight interactive maps
- **[Open-Meteo](https://open-meteo.com)** — Free weather API
- **[Supabase](https://supabase.com)** — Open-source Firebase alternative
- **[Shields.io](https://shields.io)** — Badge generation for project READMEs
- **All Indian farmers** — Your feedback makes this project better every day

---

## 📬 Contact

<div align="center">

| 📧 | 🐙 | 🌐 |
|:--:|:--:|:--:|
| **akshitvinay4636@gmail.com** | [@virahitvin8](https://github.com/virahitvin8) | [krishidrishti.netlify.app](https://krishidrishti.netlify.app) |

</div>

---

<div align="center">
  
### **जय किसान • जय विज्ञान**
  
**Empowering Indian farmers with the power of satellites 🛰️🌾**

<br>

[![Star this repo](https://img.shields.io/github/stars/virahitvin8/Krishi-Drishti?style=social&label=⭐%20Star%20this%20repo)](https://github.com/virahitvin8/Krishi-Drishti)
[![Follow](https://img.shields.io/github/followers/virahitvin8?style=social&label=Follow)](https://github.com/virahitvin8)

![Profile Views](https://komarev.com/ghpvc/?username=virahitvin8&label=Profile%20views&color=0e75b6&style=flat)

<br>

<sub>Made with ❤️ and 🛰️ for Indian farmers • © 2026 Krishi Drishti</sub>

</div>
