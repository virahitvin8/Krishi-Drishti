# Krishi Drishti v3 — Complete Deployment Guide (Step by Step)

This guide takes you from zero to a **live 24/7 running app** on free services.

## Step 1: Push Code to GitHub

1. Create a new repository on GitHub (name it `krishidrishti` or similar).
2. Upload / push the entire `KrishiDrishti_v3_Complete` folder to that repo.
3. Make sure these folders exist:
   - `frontend/` (contains `index.html`)
   - `backend/`
   - `assets/`
   - `deployment/`

## Step 2: Deploy Frontend to Netlify (Takes 2 minutes)

1. Go to https://app.netlify.com
2. Sign in with GitHub
3. Click **"Add new site" → "Import an existing project"**
4. Select your GitHub repository
5. **Build command**: Leave empty
6. **Publish directory**: `frontend`
7. Click **Deploy site**
8. Your app is now live at `https://your-project-name.netlify.app`

**Done for frontend.**

## Step 3: Create Supabase Project (Database + Auth)

1. Go to https://supabase.com and create a free account + new project.
2. After project is ready, go to **SQL Editor** and run this:

```sql
CREATE TABLE farms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT,
    name TEXT,
    boundary_geojson JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID REFERENCES farms(id),
    health_score INTEGER,
    health_status TEXT,
    recommendation TEXT,
    hotspot_grid JSONB,
    weather JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

3. Go to **Settings → API** and copy:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

## Step 4: Deploy Backend to Render (Free 24/7)

1. Go to https://dashboard.render.com
2. Click **New → Web Service**
3. Connect your GitHub account and select the repo
4. Fill:
   - **Name**: `krishidrishti-backend`
   - **Root Directory**: `backend`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. Add these **Environment Variables**:
   - `CDSE_CLIENT_ID` = Your Copernicus Client ID
   - `CDSE_CLIENT_SECRET` = Your Copernicus Secret
   - `SUPABASE_URL` = From Supabase
   - `SUPABASE_KEY` = From Supabase (anon key)
6. Click **Create Web Service**

Your backend is now running 24/7 at `https://krishidrishti-backend.onrender.com`

## Step 5: Connect Frontend to Backend (Optional but Recommended)

In `frontend/index.html`, find the `analyzeSelectedArea()` function and replace the demo logic with real API call:

```js
async function analyzeSelectedArea() {
    // ... show loading ...
    
    const response = await fetch('https://krishidrishti-backend.onrender.com/api/v1/analyze', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            polygon_geojson: currentPolygon.toGeoJSON()
        })
    });
    
    const data = await response.json();
    
    // Update UI with real data from backend
    document.getElementById('overallScore').innerText = data.health_score;
    // ... update other elements ...
}
```

## Step 6: Set Up Automatic Updates (GitHub Actions)

Create folder `.github/workflows/` in your repo and add file `auto-update.yml`:

```yaml
name: KrishiDrishti Auto Update
on:
  schedule:
    - cron: '0 */6 * * *'   # Every 6 hours
jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Backend Update
        run: |
          curl -X POST https://krishidrishti-backend.onrender.com/api/v1/admin/trigger-full-update
```

Push this file. Now your app updates automatically every 6 hours.

## Step 7: App Icon & Final Polish

- Use the logo image you uploaded as the official app icon for Android/iOS.
- The animated SVG in `assets/` is perfect for web splash/loading screens.

## Step 8: Test Everything

1. Open your Netlify URL
2. Click "Demo Farm"
3. Click "Analyze Selected Land"
4. Toggle the Hotspot Grid
5. Open Advanced Report

You now have a **complete, branded, live Krishi Drishti app** running 24/7.

---

**Need help with any specific step?** Just reply with the step number.

Your app is ready to help farmers. Deploy it with confidence. 🌾🛰️
