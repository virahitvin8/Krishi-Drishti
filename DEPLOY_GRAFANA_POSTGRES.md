# 📈 Grafana + Supabase PostgreSQL Setup Guide

> **Connect your Supabase PostgreSQL database directly to Grafana** for the fastest dashboard performance. No Infinity plugin needed — Grafana queries your data with raw SQL.

| ⏱ Setup Time | 💰 Cost | 🎯 Difficulty |
|:---:|:---:|:---:|
| 10 minutes | Free | Beginner |

---

## Prerequisites

- ✅ Grafana Cloud account (free tier — [grafana.com](https://grafana.com))
- ✅ Supabase project running ([supabase.com](https://supabase.com))
- ✅ Admin access to Supabase (can view Project Settings)

---

## Step 1: Run the SQL Migration

Open your **Supabase Dashboard → SQL Editor** and paste the contents of:

```
backend/supabase_migration.sql
```

Click **"Run"** — this creates all tables (`field_profiles`, `analyses`, `csv_batches`, `schedules`, `alerts`) plus helper views (`v_latest_field_health`, `v_daily_field_stats`) and indexes.

> ✅ The migration is idempotent — safe to run multiple times.

---

## Step 2: Get Your Supabase Connection String

In your **Supabase Dashboard → Project Settings → Database**:

| Setting | Where to Find It |
|---------|-----------------|
| **Host** | Under "Connection string" → `db.<project-ref>.supabase.co` |
| **Port** | `5432` |
| **Database** | `postgres` (default) |
| **User** | `postgres` |
| **Password** | 🔑 Click **"Reveal"** next to your database password |
| **SSL** | `Require` or `Enabled` |

Save these details — you'll need them in Step 3.

---

## Step 3: Add PostgreSQL Data Source in Grafana

1. **Log into** your Grafana Cloud dashboard
2. Click **"Connections"** (plug icon) in the left sidebar
3. Click **"Add new connection"**
4. Search for **"PostgreSQL"**
5. Click the **PostgreSQL** result by Grafana Labs
6. Click **"Install & Add"**

Fill in these values exactly:

| Setting | Value |
|---------|-------|
| **Name** | `Supabase PostgreSQL` |
| **Host** | `db.<your-project-ref>.supabase.co:5432` |
| **Database** | `postgres` |
| **User** | `postgres` |
| **Password** | *(your Supabase DB password)* |
| **SSL Mode** | `require` |
| **Max open** | `5` |
| **Max idle** | `2` |
| **Max lifetime** | `30m` |
| **Timeout** | `10s` |

Click **"Save & Test"** — you should see ✅ **"Database connection OK"**

> **Can't connect?** Make sure your Supabase project has **IPv4 addresses enabled** and the DB isn't blocked by a firewall. In Supabase Dashboard → Database → **"Connection pooling"** — try using the **Session mode** connection string instead.

---

## Step 4: Import the PostgreSQL-Optimized Dashboard

1. In Grafana, go to **Dashboards → New → Import**
2. In the **"Import via dashboard JSON model"** box, paste the JSON from:

   ```
   https://krishi-drishti-backend.onrender.com/api/v1/grafana/dashboard-json/postgres
   ```

   > **Or locally:** `http://127.0.0.1:8003/api/v1/grafana/dashboard-json/postgres`

3. Click **"Load"**
4. When prompted, select your datasource: **"Supabase PostgreSQL"**
5. Click **"Import"**

---

## Step 5: Verify the Dashboard

You should now see **"Krishi Drishti - PostgreSQL Dashboard"** with 13 live panels:

| Panel | Type | What It Shows |
|-------|------|---------------|
| Total Fields | Stat | Row count from `field_profiles` |
| Average Crop Health | Stat | AVG of `health_score` |
| Healthy Fields | Stat | COUNT from `v_latest_field_health` |
| Stressed Fields | Stat | COUNT from `v_latest_field_health` |
| Crop Health Trend | Time-series | `health_score` over time from `analyses` |
| NDVI Trend | Time-series | `ndvi` over time from `analyses` |
| All Vegetation Indices | Time-series | NDVI + EVI + NDWI + GNDVI |
| Pest Risk | Gauge | AVG `pest_risk_score` |
| Health Distribution | Bar gauge | COUNT by health status |
| Weather (Current) | Stat | Temperature, humidity, precipitation |
| Field Health Map | GeoMap | Markers from `v_latest_field_health` with lat/lng |
| Field Overview | Table | `field_id`, health, NDVI, crop type, area |
| Pest Risk Trend | Time-series | `pest_risk_score` over time |

> **Pro tip:** Click the **"Refresh"** button (🔄) or set auto-refresh to **30m** in the dashboard settings.

---

## SQL Queries Used by Each Panel

For reference, here's what each panel queries:

```sql
-- Total Fields (Stat)
SELECT COUNT(*) as total FROM field_profiles;

-- Average Crop Health (Stat)
SELECT ROUND(AVG(health_score), 1) as avg_health FROM analyses WHERE $__timeFilter(created_at);

-- Healthy / Stressed Fields (Stat)
SELECT COUNT(*) as healthy FROM v_latest_field_health WHERE health_status = 'Healthy';
SELECT COUNT(*) as stressed FROM v_latest_field_health WHERE health_status = 'Stressed';

-- Crop Health Trend (Time-series)
SELECT created_at AS "time", health_score AS "Health Score" FROM analyses WHERE $__timeFilter(created_at);

-- NDVI Trend (Time-series)
SELECT created_at AS "time", ROUND(ndvi::numeric * 100, 1) AS "NDVI" FROM analyses WHERE $__timeFilter(created_at);

-- All Vegetation Indices (Multi-line Time-series)
SELECT created_at AS "time", ROUND(ndvi::numeric * 100, 1) AS "NDVI" FROM analyses WHERE $__timeFilter(created_at);
SELECT created_at AS "time", ROUND(evi::numeric * 100, 1) AS "EVI" FROM analyses WHERE $__timeFilter(created_at);
SELECT created_at AS "time", ROUND(ndwi::numeric * 100, 1) AS "NDWI" FROM analyses WHERE $__timeFilter(created_at);
SELECT created_at AS "time", ROUND(gndvi::numeric * 100, 1) AS "GNDVI" FROM analyses WHERE $__timeFilter(created_at);

-- Pest Risk (Gauge)
SELECT ROUND(AVG(pest_risk_score), 1) as score FROM analyses WHERE $__timeFilter(created_at);

-- Health Distribution (Bar Gauge)
SELECT 
    COUNT(*) FILTER (WHERE health_status = 'Healthy') AS "Healthy",
    COUNT(*) FILTER (WHERE health_status = 'Good') AS "Good",
    COUNT(*) FILTER (WHERE health_status = 'Moderate') AS "Moderate",
    COUNT(*) FILTER (WHERE health_status = 'Stressed') AS "Stressed"
FROM v_latest_field_health;

-- Field Health Map (GeoMap)
SELECT latitude, longitude, field_id AS name, health_score, health_status, crop_type, area_hectares
FROM v_latest_field_health;

-- Field Overview (Table)
SELECT field_id, health_status, health_score, ndvi, crop_type,
    ROUND(area_hectares::numeric, 1) as area_ha, last_analysis_at
FROM v_latest_field_health ORDER BY last_analysis_at DESC LIMIT 20;

-- Pest Risk Trend (Time-series)
SELECT created_at AS "time", pest_risk_score AS "Pest Risk" FROM analyses WHERE $__timeFilter(created_at);
```

> **Note:** `$__timeFilter()` is a Grafana macro that automatically filters by the dashboard's time range.

---

## How Your Backend Writes Data to PostgreSQL

Your Krishi Drishti backend already has all the Supabase integration code. Here's what happens when you analyze a field:

1. User clicks **"Analyze Selected Land"** on the frontend
2. Backend runs the analysis (NDVI, EVI, weather, pest risk, etc.)
3. Data is saved to **Supabase PostgreSQL** via `supabase_service.py`:
   - `field_profiles` table — field metadata (lat, lng, crop type)
   - `analyses` table — full analysis results with all metrics
   - `alerts` table — auto-generated from recommendations
4. Grafana queries the same tables directly via PostgreSQL → panels update in real-time ✅

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| **"Connection refused"** | Enable public IPv4 in Supabase → Database → Connection Pooling |
| **"SSL required"** | Set **SSL Mode = require** in Grafana PostgreSQL config |
| **"No data" in panels** | Run an analysis on the Krishi Drishti app first to generate data |
| **Dashboard import fails** | Try the Infinity-based dashboard instead (`/dashboard-json` without `/postgres`) |
| **Time filter not working** | Ensure `$__timeFilter` macro is in the SQL — Grafana replaces it automatically |
| **GeoMap empty** | The `v_latest_field_health` view needs at least one analysis row |

---

## Comparison: PostgreSQL vs Infinity Datasource

| Feature | PostgreSQL (this guide) | Infinity API |
|---------|----------------------|-------------|
| **Latency** | ⚡ Direct DB queries | ⏳ API calls via backend |
| **SQL power** | Full SQL (aggregations, joins, CTEs) | Limited to JSON parsing |
| **Setup complexity** | ~10 minutes | ~5 minutes |
| **Requires plugin** | Built-in PostgreSQL | Install Infinity plugin |
| **Dashboards** | 13 panels (SQL-optimized) | 13 panels (API-based) |
| **Real-time data** | As fast as your DB | Depends on API response |

**Use PostgreSQL if:** You have data in Supabase and want the fastest dashboard.
**Use Infinity if:** You prefer API-based queries and don't want to set up direct DB access.

---

## Next Steps

1. [x] Run the SQL migration in Supabase
2. [x] Add PostgreSQL data source in Grafana
3. [x] Import the PostgreSQL-optimized dashboard
4. [ ] Analyze a field on the app to generate data
5. [ ] Watch your dashboard come to life with real field data!

---

## Need Help?

- 📄 Full deployment guide: `DEPLOY_NOW.md`
- 📄 Grafana Infinity setup: `DEPLOY_GRAFANA.md`
- 🐛 Issues: [GitHub Issues](https://github.com/virahitvin8/Krishi-Drishti/issues)
- 💬 Grafana docs: [grafana.com/docs](https://grafana.com/docs/)
