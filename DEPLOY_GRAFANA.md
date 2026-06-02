# 📈 Krishi Drishti — Grafana Live Dashboard

**Real-time agricultural monitoring dashboard** with NDVI trends, crop health scores, weather data, pest risk tracking, and field location mapping.

---

## Quick Start (5 minutes)

### 1. Create Grafana Cloud Account

1. Go to **[https://grafana.com](https://grafana.com)** → **Get started free**
2. Sign up with your email (no credit card required for free tier)
3. Choose **Grafana Cloud** stack (not Grafana OSS)
4. Wait for your stack to provision (~1 minute)

**Free Tier Includes:**
- 10,000 metrics series
- 50 GB logs
- 3 team members
- 14-day data retention
- Up to 1,000 dashboards

### 2. Install Infinity Datasource

1. In Grafana Cloud, go to **Connections → Add new connection**
2. Search for **"Infinity"** → Click on **Infinity** by Grafana Labs
3. Click **Install & Add data source**
4. Name it: `Krishi Drishti API`
5. **URL**: `https://krishi-drishti-backend.onrender.com`
6. **Authentication**: None (public API)
7. Click **Save & Test**

### 3. Import the Dashboard

**Option A: From the backend API (easiest)**
1. Visit: `https://krishi-drishti-backend.onrender.com/api/v1/grafana/dashboard-json`
2. Copy the entire JSON response
3. In Grafana, go to **Dashboards → New → Import**
4. Paste JSON → Click **Load**
5. Select **Infinity** as the datasource (the one you created in step 2)
6. Click **Import**

**Option B: From the project file**
1. The file `backend/routers/grafana.py` contains the dashboard definition in the `get_dashboard_json_definition()` function
2. You can also run the backend locally and visit the endpoint above

### 4. Dashboard Panels

Once imported, your dashboard will have these panels:

| Panel | Type | What It Shows |
|-------|------|---------------|
| **Total Fields** | Stat | Count of registered fields |
| **Average Crop Health** | Stat | Mean health score across all fields |
| **Healthy Fields** | Stat | Count of fields with score > 80 |
| **Stressed Fields** | Stat | Fields needing attention (score < 50) |
| **Crop Health Trend** | Time-series | 7-day health score trend with thresholds |
| **NDVI Trend** | Time-series | NDVI values over time (green/red zones) |
| **All Vegetation Indices** | Time-series | NDVI, EVI, NDWI, GNDVI, REIP, SAVI |
| **Pest Risk Gauge** | Gauge | Current pest pressure (green → red) |
| **Health Distribution** | Bar Gauge | Healthy vs stressed field breakdown |
| **Current Weather** | Stat | Temperature, humidity, precipitation |
| **Field Health Map** | GeoMap | Interactive map with color-coded fields |
| **Alerts & Recommendations** | Table | Recent actionable recommendations |
| **Pest Risk Trend** | Time-series | Pest pressure changes over 30 days |

---

## Manual Configuration (Advanced)

### Adding a PostgreSQL Data Source (Optional)

If you want to query Supabase directly instead of using the Infinity API:

1. Get your Supabase connection string from **Supabase Dashboard → Settings → Database**
2. In Grafana, go to **Connections → Data sources → Add → PostgreSQL**
3. Fill in:
   - **Host**: Your Supabase host (e.g., `db.xxxxx.supabase.co`)
   - **Database**: `postgres`
   - **User/Password**: Your Supabase database credentials
   - **TLS/SSL**: Enable
   - **Max open**: 10
4. Click **Save & Test**

Then you can create custom SQL panels:
```sql
-- Example: Get latest health scores for all fields
SELECT 
  created_at AS "time",
  analysis->'health_score'->>'overall' AS "Health Score"
FROM analyses
ORDER BY created_at DESC
LIMIT 100;
```

### Customizing the Dashboard

1. Click the **gear icon** (Dashboard Settings) → **Variables**
2. Add a variable `field_id` to filter by specific fields
3. Click **Save**
4. Now you can use `$field_id` in your Infinity queries:
   ```
   POST https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/ndvi-trend
   Body: {"field_id": "$field_id", "days": 30}
   ```

---

## API Endpoints Reference

The backend exposes these endpoints for Grafana:

| Endpoint | Method | Returns | Panel Type |
|----------|--------|---------|------------|
| `/api/v1/grafana/health` | GET/POST | Connection status | Health check |
| `/api/v1/grafana/query/ndvi-trend` | POST | `[{time, value}]` | Time-series |
| `/api/v1/grafana/query/vegetation-indices` | POST | `[{time, value, metric}]` | Multi-line |
| `/api/v1/grafana/query/health-trend` | POST | `[{time, value, status}]` | Time-series/Stat |
| `/api/v1/grafana/query/weather-trend` | POST | `[{time, value, metric, unit}]` | Stat/Table |
| `/api/v1/grafana/query/field-summary` | POST | `[{total, avg, counts}]` | Stat/Bar gauge |
| `/api/v1/grafana/query/field-locations` | POST | `[{lat, lng, name, score}]` | GeoMap |
| `/api/v1/grafana/query/pest-risk-trend` | POST | `[{time, value, level}]` | Gauge/Time-series |
| `/api/v1/grafana/query/recommendations` | POST | `[{time, recommendation, type}]` | Table |
| `/api/v1/grafana/dashboard-json` | GET | Complete dashboard JSON | Import |

---

## Example: Viewing NDVI Trend in Grafana

1. Create a new **Time-series** panel
2. Query type: **Infinity**
3. Method: **POST**
4. URL: `https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/ndvi-trend`
5. Body: `{"field_id": "demo", "days": 30}`
6. Parse as: **JSON**
7. Columns:
   - `time` → Time (timestamp)
   - `value` → NDVI (number)
8. Thresholds: Red (< 25%), Yellow (25-45%), Green (> 45%)

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| **"Data source not found"** | Install Infinity datasource from Connections |
| **"404 Not Found"** | Check the backend URL is correct and running |
| **No data in panels** | Click "Analyze" on the app first to generate data |
| **GeoMap shows no locations** | The map only shows fields that have been analyzed |
| **"CORS error"** | Backend has `allow_origins=["*"]` — should work with all Grafana instances |
| **Dashboard JSON import fails** | Try copying the raw JSON from `/api/v1/grafana/dashboard-json` endpoint |

---

## Architecture

```
┌─────────────────────┐     ┌──────────────────────┐
│   Krishi Drishti    │     │   Grafana Cloud       │
│   Backend API       │────▶│   (Infinity Plugin)   │
│                     │     │                       │
│  /api/v1/grafana/*  │     │  - Stat panels        │
│                     │     │  - Time-series        │
│  Returns JSON data  │     │  - Gauges             │
│  for all metrics    │     │  - GeoMap             │
│                     │     │  - Tables             │
│  Works with or      │     │                       │
│  without Supabase   │     │  Free tier:           │
│                     │     │  10k metrics          │
└─────────────────────┘     └──────────────────────┘
```

---

**Jai Kisan! 🌾 Your fields now have a live Grafana dashboard.**
