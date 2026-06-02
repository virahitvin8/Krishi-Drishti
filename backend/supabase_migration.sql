-- ============================================
-- Krishi Drishti - Supabase Database Migration
-- Run this SQL in your Supabase SQL Editor
-- ============================================
-- Created: June 2026
-- Description: Tables for field profiles, satellite analyses, CSV batches, and schedules

-- ============================================
-- 1. FIELD PROFILES TABLE
-- Stores registered farm field information
-- ============================================
CREATE TABLE IF NOT EXISTS field_profiles (
    id BIGSERIAL PRIMARY KEY,
    field_id TEXT UNIQUE NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    crop_type TEXT DEFAULT 'general',
    area_hectares DOUBLE PRECISION DEFAULT 1.0,
    last_health_score DOUBLE PRECISION DEFAULT 0,
    last_status TEXT DEFAULT 'Unknown',
    polygon_geojson JSONB DEFAULT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for field lookups
CREATE INDEX IF NOT EXISTS idx_field_profiles_location ON field_profiles (latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_field_profiles_health ON field_profiles (last_health_score DESC);
CREATE INDEX IF NOT EXISTS idx_field_profiles_crop ON field_profiles (crop_type);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS trigger_field_profiles_updated ON field_profiles;
CREATE TRIGGER trigger_field_profiles_updated
    BEFORE UPDATE ON field_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- ============================================
-- 2. ANALYSES TABLE
-- Stores satellite analysis results for fields
-- JSONB columns allow flexible schema for different analysis types
-- ============================================
CREATE TABLE IF NOT EXISTS analyses (
    id BIGSERIAL PRIMARY KEY,
    analysis_id TEXT UNIQUE NOT NULL,
    field_id TEXT NOT NULL REFERENCES field_profiles(field_id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    analysis_type TEXT DEFAULT 'on_demand', -- 'on_demand', 'scheduled', 'csv_upload'
    
    -- Core metrics (extracted from JSON for fast SQL queries)
    health_score DOUBLE PRECISION DEFAULT 0,
    ndvi DOUBLE PRECISION DEFAULT 0,
    evi DOUBLE PRECISION DEFAULT 0,
    ndwi DOUBLE PRECISION DEFAULT 0,
    gndvi DOUBLE PRECISION DEFAULT 0,
    reip DOUBLE PRECISION DEFAULT 0,
    savi DOUBLE PRECISION DEFAULT 0,
    soil_moisture_pct DOUBLE PRECISION DEFAULT 0,
    drainage_score DOUBLE PRECISION DEFAULT 50,
    pest_risk_score DOUBLE PRECISION DEFAULT 0,
    temperature_c DOUBLE PRECISION DEFAULT 0,
    humidity_pct DOUBLE PRECISION DEFAULT 0,
    precipitation_mm DOUBLE PRECISION DEFAULT 0,
    
    -- Full analysis data (stored as JSONB for extensibility)
    analysis JSONB NOT NULL DEFAULT '{}',
    recommendations JSONB DEFAULT '[]',
    hotspot_grid JSONB DEFAULT '[]',
    satellite_sources JSONB DEFAULT '[]',
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for time-series queries (used by Grafana)
CREATE INDEX IF NOT EXISTS idx_analyses_field_time ON analyses (field_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analyses_created_at ON analyses (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analyses_health_score ON analyses (health_score DESC);
CREATE INDEX IF NOT EXISTS idx_analyses_ndvi ON analyses (ndvi DESC);
CREATE INDEX IF NOT EXISTS idx_analyses_type ON analyses (analysis_type);
CREATE INDEX IF NOT EXISTS idx_analyses_field_ndvi ON analyses (field_id, created_at DESC, ndvi);


-- ============================================
-- 3. CSV BATCHES TABLE
-- Tracks CSV upload jobs for batch field analysis
-- ============================================
CREATE TABLE IF NOT EXISTS csv_batches (
    id BIGSERIAL PRIMARY KEY,
    batch_id TEXT UNIQUE NOT NULL,
    filename TEXT NOT NULL,
    total_rows INTEGER DEFAULT 0,
    processed INTEGER DEFAULT 0,
    failed INTEGER DEFAULT 0,
    errors JSONB DEFAULT '[]',
    status TEXT DEFAULT 'processing', -- 'processing', 'completed', 'failed'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_csv_batches_status ON csv_batches (status);
CREATE INDEX IF NOT EXISTS idx_csv_batches_created ON csv_batches (created_at DESC);


-- ============================================
-- 4. SCHEDULES TABLE
-- Manages recurring analysis schedules
-- ============================================
CREATE TABLE IF NOT EXISTS schedules (
    id BIGSERIAL PRIMARY KEY,
    schedule_id TEXT UNIQUE NOT NULL,
    field_id TEXT REFERENCES field_profiles(field_id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    interval_days INTEGER DEFAULT 7,
    polygon_geojson JSONB DEFAULT NULL,
    webhook_url TEXT DEFAULT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_run TIMESTAMPTZ DEFAULT NULL,
    next_run TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_schedules_next_run ON schedules (next_run) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_schedules_field ON schedules (field_id);


-- ============================================
-- 5. ALERTS TABLE
-- Stores system-generated alerts for fields
-- ============================================
CREATE TABLE IF NOT EXISTS alerts (
    id BIGSERIAL PRIMARY KEY,
    field_id TEXT REFERENCES field_profiles(field_id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL, -- 'critical', 'warning', 'info'
    message TEXT NOT NULL,
    health_score DOUBLE PRECISION DEFAULT 0,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alerts_field ON alerts (field_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_unread ON alerts (is_read, created_at DESC);


-- ============================================
-- 6. HELPER VIEWS (for Grafana PostgreSQL queries)
-- ============================================

-- View: Latest analysis for each field
CREATE OR REPLACE VIEW v_latest_field_health AS
SELECT DISTINCT ON (a.field_id)
    a.field_id,
    fp.latitude,
    fp.longitude,
    fp.crop_type,
    fp.area_hectares,
    a.health_score,
    a.ndvi,
    a.evi,
    a.ndwi,
    a.pest_risk_score,
    a.soil_moisture_pct,
    a.temperature_c,
    a.humidity_pct,
    a.created_at as last_analysis_at,
    CASE 
        WHEN a.health_score >= 80 THEN 'Healthy'
        WHEN a.health_score >= 65 THEN 'Good'
        WHEN a.health_score >= 50 THEN 'Moderate'
        ELSE 'Stressed'
    END as health_status
FROM analyses a
LEFT JOIN field_profiles fp ON a.field_id = fp.field_id
ORDER BY a.field_id, a.created_at DESC;

-- View: Daily aggregation for time-series charts
CREATE OR REPLACE VIEW v_daily_field_stats AS
SELECT 
    DATE(created_at) as analysis_date,
    field_id,
    COUNT(*) as analysis_count,
    ROUND(AVG(health_score), 1) as avg_health_score,
    ROUND(AVG(ndvi), 3) as avg_ndvi,
    ROUND(AVG(evi), 3) as avg_evi,
    ROUND(AVG(ndwi), 3) as avg_ndwi,
    ROUND(AVG(pest_risk_score), 1) as avg_pest_risk,
    ROUND(AVG(soil_moisture_pct), 1) as avg_soil_moisture,
    ROUND(AVG(temperature_c), 1) as avg_temperature,
    ROUND(AVG(humidity_pct), 1) as avg_humidity
FROM analyses
GROUP BY DATE(created_at), field_id
ORDER BY analysis_date DESC;


-- ============================================
-- 7. ROW LEVEL SECURITY
-- (Optional - enable if you want per-user data isolation)
-- ============================================
-- Enable RLS on all tables
ALTER TABLE field_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE csv_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;

-- Public read access (for the Grafana dashboard)
CREATE POLICY "Allow public read access" ON field_profiles FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON analyses FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON csv_batches FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON schedules FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON alerts FOR SELECT USING (true);

-- Allow anon key to insert (for the backend API)
CREATE POLICY "Allow anon insert" ON field_profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow anon insert" ON analyses FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow anon insert" ON csv_batches FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow anon insert" ON schedules FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow anon insert" ON alerts FOR INSERT WITH CHECK (true);

-- Allow anon to update schedules and field profiles
CREATE POLICY "Allow anon update" ON field_profiles FOR UPDATE USING (true);
CREATE POLICY "Allow anon update" ON schedules FOR UPDATE USING (true);


-- ============================================
-- END OF MIGRATION
-- ============================================
