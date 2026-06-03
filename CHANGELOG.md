# Changelog

All notable changes to **Krishi Drishti** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-06-03

### Added
- **Complete SETUP_GUIDE.md** — Step-by-step guide covering directory structure, APK installation, feature walkthrough, maps & layers, quantum tech, CI/CD setup, and troubleshooting
- **Animated SVG workflow diagram** — `workflow-overview.svg` showing full data flow from satellites → backend → app UI → deployment
- **Quantum technology integration docs** — IBM Quantum, AWS Braket, Azure Quantum, Google Cirq integration guide with code examples
- **Harness CI pipeline fix** — Resolved commit `8b044f1` failure (added `set -e`, timeout, license acceptance, APK verification, fixed GRADLE_OPTS escaping)
- **Setup guide link** in main README for easy navigation
- **Workflow diagram section** in README with visual overview
- **Quantum section** in README with quick-start code example

### Changed
- README now links to SETUP_GUIDE.md for detailed instructions
- `.gitignore` now tracks `pubspec.lock` for reproducible builds
- Updated `CONTRIBUTING.md` with satellite-farming focus and emoji icons

### Fixed
- Harness CI pipeline: `set -e`, timeout, GRADLE_OPTS escaping, Android license acceptance, APK verification
- `.gitignore` pubspec.lock exclusion removed

---

## [3.0.0] - 2026-06-02

### Added
- Beautiful GitHub-style README with badges and professional formatting
- Individual percentage boxes for every metric (NDVI, EVI, REIP, NDWI, ET, Soil Moisture, etc.)
- Click-to-expand breakdown for each analysis section
- Transparent Hotspot/Coldspot Grid on map (Red = stressed, Bluish = healthy)
- Animated logo with satellite orbit + leaf pulse
- Loading and processing animations tied to brand concept
- Added DEM analysis (Slope, Drainage, Aspect)
- Added Pest Risk Scoring
- Full multi-satellite transparency in Advanced Report
- `LICENSE` (MIT) and `CONTRIBUTING.md`
- Complete deployment guide for Netlify + Render + Supabase

### Changed
- Major UI restructure for better farmer experience
- Improved hotspot grid visibility (light transparency)
- Enhanced overall health score display at the top

### Fixed
- Grid layer now properly toggleable without hiding base map

---

## [2.0.0] - 2026-06-02

### Added
- Core Sentinel-2 analysis (NDVI, EVI, NDWI, REIP)
- Weather integration with Open-Meteo
- Hotspot grid generation
- Supabase integration ready
- Automatic updates via GitHub Actions

### Changed
- Switched from mock data to real satellite processing structure

---

## [1.0.0] - 2026-06-02

### Added
- Initial project structure
- Basic farmer dashboard concept
- Brand identity (Krishi Drishti)

---

*Maintained with ❤️ for Indian farmers*
