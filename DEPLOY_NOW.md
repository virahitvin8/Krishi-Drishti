# 🚀 Krishi Drishti — Deploy Now Guide

**Deploy backend to Render + frontend to Netlify in 10 minutes.**

---

## Step 1: Push Code to GitHub

```bash
cd KrishiDrishti_Final_v4
git add .
git commit -m "v4.0: Complete satellite analysis backend + premium frontend with Telugu support"
git push origin main
```

> ✅ Git is already configured. Remote: `origin` → `https://github.com/virahitvin8/Krishi-Drishti.git`

---

## Step 2: Deploy Backend → Render

### Option A: One-Click Blueprint (Easiest)

1. Go to https://dashboard.render.com
2. Click **New → Blueprint**
3. Connect your GitHub repo
4. Render will auto-detect `render.yaml` in the root folder
5. Click **Apply**
6. After deployment, go to **Environment** tab and add these secrets:

| Variable | Your Value |
|----------|-----------|
| `CDSE_CLIENT_ID` | *(your Copernicus client ID)* |
| `CDSE_CLIENT_SECRET` | *(your Copernicus client secret)* |
| `SUPABASE_URL` | *(your Supabase project URL)* |
| `SUPABASE_KEY` | *(your Supabase anon key)* |

### Option B: Manual Web Service

1. Go to https://dashboard.render.com
2. Click **New → Web Service**
3. Connect your GitHub repo
4. Fill these settings:

| Setting | Value |
|---------|-------|
| **Name** | `krishi-drishti-backend` |
| **Root Directory** | *(leave blank — render.yaml handles this)* |
| **Runtime** | Python 3 |
| **Build Command** | `pip install -r backend/requirements.txt` |
| **Start Command** | `uvicorn backend.main:app --host 0.0.0.0 --port $PORT` |

5. Add Environment Variables (same as above)
6. Click **Create Web Service**

### Verify Backend is Live

After deployment, visit: `https://krishi-drishti-backend.onrender.com/health`

You should see:
```json
{"status": "healthy", "version": "4.0.0", ...}
```

---

## Step 3: Deploy Frontend → Netlify

### Connect Netlify to GitHub

1. Go to https://app.netlify.com
2. Click **Add new site → Import an existing project**
3. Connect your GitHub repo
4. Fill these settings:

| Setting | Value |
|---------|-------|
| **Branch** | `main` |
| **Publish directory** | `frontend` |
| **Build command** | *(leave empty — pure HTML/CSS/JS)* |

5. Click **Deploy site**

### Update API_BASE (Important!)

After deployment, your frontend URL will be something like `https://krishidrishti.netlify.app`

The frontend already has the correct Render URL configured:
```javascript
const API_BASE = 'https://krishi-drishti-backend.onrender.com';
```

If your Render URL is different, update line 34 in `frontend/index.html` and re-deploy.

### Enable Auto-Deploy

1. In Netlify Dashboard → **Site settings → Build & deploy**
2. Under **Auto publish**, ensure it's set to `main` branch
3. ✅ Now every `git push` auto-deploys to Netlify

### Test PWA Installation

1. Open your Netlify URL in Chrome on Android
2. You'll see an "Install" prompt in the address bar
3. Tap to install the app on your home screen

---

## Step 4: Enable Auto-Deploy on Render

1. Go to your Render Web Service Dashboard
2. Go to **Settings → Build & Deploy**
3. Turn ON **Auto-Deploy**
4. Set branch = `main`
5. ✅ Now every `git push` auto-deploys both frontend (Netlify) and backend (Render)

---

## Step 5: Generate APK (Android App)

1. Make sure frontend is live on Netlify
2. Go to https://www.pwabuilder.com
3. Paste your Netlify URL (e.g., `https://krishidrishti.netlify.app`)
4. Click **Start → Package → Android**
5. Download the `.apk` file
6. Install on any Android phone

---

## Architecture Overview

```
GitHub Push
    │
    ├─► Render (auto-deploy) ──► Backend API
    │   https://krishi-drishti-backend.onrender.com
    │   ├── /api/v1/analyze      (POST)
    │   ├── /api/v1/dashboard    (GET)
    │   ├── /api/v1/upload-csv   (POST)
    │   ├── /api/v1/schedule     (POST)
    │   ├── /api/v1/report/{id}  (GET)
    │   ├── /api/v1/satellites   (GET)
    │   └── /api/v1/translate    (GET)
    │
    └─► Netlify (auto-deploy) ──► Frontend SPA
        https://krishidrishti.netlify.app
        ├── index.html (full app)
        ├── manifest.json (PWA)
        ├── service-worker.js (offline)
        ├── netlify.toml (deploy config)
        └── _redirects (SPA routing)
```

## Satellite Data Flow

```
Every 7 days (or on-demand):
  1. User clicks "Analyze" on the map
  2. Frontend calls POST /api/v1/analyze
  3. Backend fetches from multiple satellites:
     ├── CDSE Sentinel Hub (Sentinel-2 NDVI, EVI, NDWI...)
     ├── Sentinel-1 SAR (soil moisture)
     ├── NASA POWER API (weather)
     └── Open-Meteo (forecast)
  4. Analysis engine computes:
     ├── Health score (0-100)
     ├── Pest risk score
     ├── Drainage assessment
     └── Actionable recommendations
  5. Results displayed in:
     ├── Interactive map (hotspot grid)
     ├── Charts (radar, bar, doughnut)
     ├── Detailed report
     └── Recommendations panel
```

---

**Jai Kisan! 🌾 Your app is now live 24/7 with auto-deploy.**
