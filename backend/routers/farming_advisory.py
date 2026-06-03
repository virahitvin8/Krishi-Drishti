"""
Krishi Drishti — Farming Advisory API Router
===============================================
Provides farming advisory services for Indian farmers:
  - Nearby agricultural services (seed shops, fertilizer, KBTs)
  - Crop farming calendar (sowing, harvest, pesticide timing)
  - Pest & disease management with detailed measures

All data is sourced from Indian agricultural best practices.
"""

import logging
import math
from datetime import datetime
from fastapi import APIRouter, Query
from typing import Optional

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/farming", tags=["farming-advisory"])


# ── Crop Calendar Database ──

CROP_CALENDAR = {
    "rice": {
        "name": "Rice (Dhan/Chawal)",
        "season": "Kharif (Monsoon)",
        "sowing_start": "June",
        "sowing_end": "July",
        "harvest_start": "September",
        "harvest_end": "October",
        "temperature": "25-35°C",
        "rainfall": "100-200 cm",
        "soil": "Clay loam, alluvial soil",
        "duration": "120-150 days",
        "states": ["West Bengal", "Uttar Pradesh", "Andhra Pradesh", "Punjab", "Tamil Nadu"],
        "pesticide_timing": [
            {"stage": "Nursery (15-20 days)", "pesticide": "Carbendazim 50% WP", "disease": "Blast disease", "dosage": "1g/liter water"},
            {"stage": "Transplanting (25-30 days)", "pesticide": "Chlorpyriphos 20% EC", "disease": "Stem borer", "dosage": "2.5ml/liter water"},
            {"stage": "Tillering (40-50 days)", "pesticide": "Tricyclazole 75% WP", "disease": "Leaf blast", "dosage": "1g/liter water"},
            {"stage": "Flowering (70-80 days)", "pesticide": "Carbendazim + Mancozeb", "disease": "Sheath rot", "dosage": "2g/liter water"},
            {"stage": "Grain filling (90-100 days)", "pesticide": "Monocrotophos 36% SL", "disease": "Brown plant hopper", "dosage": "1.5ml/liter water"},
        ],
        "fertilizer_schedule": [
            {"stage": "Basal (before transplanting)", "type": "DAP + MOP", "dosage": "50kg DAP + 30kg MOP per acre"},
            {"stage": "Tillering (25-30 days)", "type": "Urea", "dosage": "40kg Urea per acre"},
            {"stage": "Panicle initiation (50-55 days)", "type": "Urea", "dosage": "20kg Urea per acre"},
        ]
    },
    "wheat": {
        "name": "Wheat (Gehu)",
        "season": "Rabi (Winter)",
        "sowing_start": "October",
        "sowing_end": "December",
        "harvest_start": "February",
        "harvest_end": "April",
        "temperature": "15-25°C",
        "rainfall": "50-100 cm",
        "soil": "Loam, clay loam",
        "duration": "120-150 days",
        "states": ["Uttar Pradesh", "Punjab", "Haryana", "Madhya Pradesh", "Rajasthan"],
        "pesticide_timing": [
            {"stage": "Crown root initiation (20-25 days)", "pesticide": "2,4-D Sodium Salt 80% WP", "disease": "Broad leaf weeds", "dosage": "1kg/acre"},
            {"stage": "Stem elongation (45-50 days)", "pesticide": "Propiconazole 25% EC", "disease": "Rust disease", "dosage": "1ml/liter water"},
            {"stage": "Flowering (70-75 days)", "pesticide": "Carbendazim 50% WP", "disease": "Powdery mildew", "dosage": "1g/liter water"},
            {"stage": "Grain filling (90-100 days)", "pesticide": "Malathion 50% EC", "disease": "Aphids", "dosage": "1.5ml/liter water"},
        ],
        "fertilizer_schedule": [
            {"stage": "Basal (before sowing)", "type": "DAP + MOP", "dosage": "50kg DAP + 25kg MOP per acre"},
            {"stage": "Crown root (20-25 days)", "type": "Urea", "dosage": "35kg Urea per acre"},
            {"stage": "Stem elongation (45-50 days)", "type": "Urea", "dosage": "25kg Urea per acre"},
        ]
    },
    "cotton": {
        "name": "Cotton (Kapas)",
        "season": "Kharif (Monsoon)",
        "sowing_start": "May",
        "sowing_end": "June",
        "harvest_start": "October",
        "harvest_end": "November",
        "temperature": "21-30°C",
        "rainfall": "75-100 cm",
        "soil": "Black cotton soil, alluvial",
        "duration": "180-200 days",
        "states": ["Gujarat", "Maharashtra", "Telangana", "Andhra Pradesh", "Punjab"],
        "pesticide_timing": [
            {"stage": "Seedling (15-20 days)", "pesticide": "Imidacloprid 17.8% SL", "disease": "Jassids/Thrips", "dosage": "0.5ml/liter water"},
            {"stage": "Squaring (50-60 days)", "pesticide": "Cypermethrin 10% EC", "disease": "Bollworm", "dosage": "1ml/liter water"},
            {"stage": "Flowering (70-80 days)", "pesticide": "Acephate 75% SP", "disease": "Aphids", "dosage": "1g/liter water"},
            {"stage": "Boll formation (100-120 days)", "pesticide": "Indoxacarb 14.5% SC", "disease": "American bollworm", "dosage": "0.5ml/liter water"},
        ],
        "fertilizer_schedule": [
            {"stage": "Basal (before sowing)", "type": "DAP + MOP", "dosage": "40kg DAP + 30kg MOP per acre"},
            {"stage": "Squaring (50-60 days)", "type": "Urea", "dosage": "30kg Urea per acre"},
            {"stage": "Flowering (70-80 days)", "type": "Urea + MOP", "dosage": "20kg Urea + 15kg MOP per acre"},
        ]
    },
    "sugarcane": {
        "name": "Sugarcane (Ganna)",
        "season": "Annual",
        "sowing_start": "February",
        "sowing_end": "March",
        "harvest_start": "December",
        "harvest_end": "March",
        "temperature": "21-27°C",
        "rainfall": "75-120 cm",
        "soil": "Loam, clay loam",
        "duration": "300-360 days",
        "states": ["Uttar Pradesh", "Maharashtra", "Karnataka", "Tamil Nadu", "Bihar"],
        "pesticide_timing": [
            {"stage": "Germination (20-30 days)", "pesticide": "Carbofuran 3% CG", "disease": "Early shoot borer", "dosage": "8kg/acre"},
            {"stage": "Grand growth (90-100 days)", "pesticide": "Monocrotophos 36% SL", "disease": "Top borer", "dosage": "2ml/liter water"},
            {"stage": "Grand growth (120-150 days)", "pesticide": "Malathion 50% EC", "disease": "Scale insect", "dosage": "2ml/liter water"},
            {"stage": "Maturing (250-270 days)", "pesticide": "Copper oxychloride 50% WP", "disease": "Red rot", "dosage": "2.5g/liter water"},
        ],
        "fertilizer_schedule": [
            {"stage": "Basal (at planting)", "type": "DAP + MOP", "dosage": "80kg DAP + 40kg MOP per acre"},
            {"stage": "Tillering (45-60 days)", "type": "Urea", "dosage": "60kg Urea per acre"},
            {"stage": "Grand growth (90-120 days)", "type": "Urea", "dosage": "50kg Urea per acre"},
        ]
    },
    "pulses": {
        "name": "Pulses (Dal - Arhar/Chana/Moong)",
        "season": "Kharif/Rabi (varies by type)",
        "sowing_start": "June",
        "sowing_end": "July (Kharif) / October (Rabi)",
        "harvest_start": "September",
        "harvest_end": "December",
        "temperature": "20-30°C",
        "rainfall": "60-80 cm",
        "soil": "Well-drained loam",
        "duration": "90-140 days",
        "states": ["Madhya Pradesh", "Maharashtra", "Uttar Pradesh", "Rajasthan", "Karnataka"],
        "pesticide_timing": [
            {"stage": "Seed treatment (before sowing)", "pesticide": "Thiram 75% WS", "disease": "Root rot", "dosage": "2g/kg seed"},
            {"stage": "Vegetative (25-30 days)", "pesticide": "Dimethoate 30% EC", "disease": "Jassids", "dosage": "1ml/liter water"},
            {"stage": "Flowering (45-50 days)", "pesticide": "Carbendazim 50% WP", "disease": "Powdery mildew", "dosage": "1g/liter water"},
            {"stage": "Pod formation (70-80 days)", "pesticide": "Quinalphos 25% EC", "disease": "Pod borer", "dosage": "2ml/liter water"},
        ],
        "fertilizer_schedule": [
            {"stage": "Basal (before sowing)", "type": "DAP", "dosage": "30kg DAP per acre (legumes fix their own N)"},
            {"stage": "Flowering (45-50 days)", "type": "MOP", "dosage": "15kg MOP per acre"},
        ]
    }
}


# ── Pest & Disease Database ──

PEST_DISEASE_DB = {
    "blast_rice": {
        "name": "Blast Disease (Rice)",
        "crops_affected": ["Rice"],
        "symptoms": "Diamond-shaped spots on leaves with grey center. Lesions on nodes and panicles. Can cause complete crop loss in severe cases.",
        "causes": "Fungal pathogen Magnaporthe grisea. Spreads through airborne spores. Favored by high humidity (90%+) and moderate temperatures (25-28°C).",
        "prevention": [
            "Use resistant varieties (e.g., IR64, Pusa Basmati-1)",
            "Avoid excessive nitrogen fertilizer",
            "Maintain proper spacing (20×15cm) for airflow",
            "Keep fields weed-free",
            "Avoid water stress",
        ],
        "organic_control": [
            "Neem oil (5ml/liter water) - spray every 10 days",
            "Trichoderma viride (2.5kg/acre) - soil application",
            "Bordeaux mixture (1%) spray",
            "Cow urine (1:10 dilution) spray weekly",
        ],
        "chemical_control": [
            "Carbendazim 50% WP (1g/liter water) — spray at first appearance",
            "Tricyclazole 75% WP (0.6g/liter water)",
            "Edifenphos 50% EC (1ml/liter water)",
            "Repeat spray every 10-15 days in severe cases",
        ],
        "critical_timing": "Apply fungicide within 24-48 hours of first symptom appearance. Early detection is critical."
    },
    "rust_wheat": {
        "name": "Rust Disease (Wheat)",
        "crops_affected": ["Wheat", "Barley"],
        "symptoms": "Yellow/orange/brown pustules on leaves and stems. Rust-colored powder (spores) rubs off on fingers. Reduces photosynthesis and grain filling.",
        "causes": "Fungal pathogen Puccinia spp. Spreads by wind-blown spores. Favored by moderate temperatures (15-22°C) and high humidity.",
        "prevention": [
            "Grow rust-resistant varieties (HD 2967, PBW 550)",
            "Avoid late sowing (sow before November 15)",
            "Remove volunteer wheat plants",
            "Crop rotation with non-host crops",
        ],
        "organic_control": [
            "Sulfur powder (15-20kg/acre) - dusting",
            "Garlic bulb extract (1kg crushed garlic in 10L water) spray",
            "Baking soda solution (5g/liter water) weekly spray",
        ],
        "chemical_control": [
            "Propiconazole 25% EC (1ml/liter water)",
            "Tebuconazole 25% WG (1g/liter water)",
            "Zineb 75% WP (2g/liter water)",
            "Apply 2-3 sprays at 15-day intervals",
        ],
        "critical_timing": "Apply fungicide immediately after spotting rust pustules. Most effective at flag leaf emergence stage."
    },
    "bollworm_cotton": {
        "name": "American Bollworm (Cotton)",
        "crops_affected": ["Cotton", "Tomato", "Chickpea"],
        "symptoms": "Round bore holes on bolls. Larvae feed inside bolls, destroying fibers. Premature boll drop. Frass (excreta) visible on bolls.",
        "causes": "Helicoverpa armigera insect pest. Highly mobile and develops resistance quickly. Favored by moderate temperatures and flowering stage.",
        "prevention": [
            "Grow Bt cotton varieties",
            "Install pheromone traps (5-6/acre) for monitoring",
            "Plant marigold as trap crop around field border",
            "Avoid continuous cotton cultivation",
        ],
        "organic_control": [
            "Neem kernel extract (5%) spray weekly",
            "Bacillus thuringiensis (Bt) spray (2g/liter water)",
            "HaNPV virus (250 LE/acre) - evening spray",
            "Custard apple seed extract spray",
        ],
        "chemical_control": [
            "Indoxacarb 14.5% SC (0.5ml/liter water)",
            "Spinosad 45% SC (0.3ml/liter water)",
            "Chlorantraniliprole 18.5% SC (0.3ml/liter water)",
            "Rotate insecticides to avoid resistance",
        ],
        "critical_timing": "Spray at egg stage or immediately after hatching. Evening spraying gives best results."
    },
    "powdery_mildew": {
        "name": "Powdery Mildew",
        "crops_affected": ["Wheat", "Pulses", "Vegetables", "Grapes"],
        "symptoms": "White/gray powdery coating on leaves, stems, and fruits. Leaves curl and turn yellow. Reduced photosynthesis and yield loss.",
        "causes": "Fungal pathogen Erysiphe spp. Favored by moderate temperatures (20-25°C) and high humidity but dry leaf surfaces. Spreads by wind.",
        "prevention": [
            "Plant resistant varieties",
            "Ensure proper spacing for air circulation",
            "Avoid overhead irrigation",
            "Remove infected plant debris immediately",
        ],
        "organic_control": [
            "Milk spray (1 part milk : 9 parts water) weekly",
            "Baking soda (5g/liter water) + vegetable oil (2.5ml/liter)",
            "Neem oil (3ml/liter water) spray every 7-10 days",
            "Sulfur dusting (15kg/acre) - avoid in hot weather",
        ],
        "chemical_control": [
            "Carbendazim 50% WP (1g/liter water)",
            "Hexaconazole 5% EC (1ml/liter water)",
            "Dinocap 48% EC (0.5ml/liter water)",
            "Apply 2-3 sprays at 10-day intervals",
        ],
        "critical_timing": "Begin spray at first appearance of white powdery growth. Early treatment is highly effective."
    }
}


# ── Endpoints ──

@router.get("/calendar")
async def get_crop_calendar(crop: Optional[str] = None):
    """
    Get detailed farming calendar for Indian crops.
    
    Returns sowing/harvest timing, temperature, rainfall, soil requirements,
    pesticide timing schedule, and fertilizer schedule for each crop.
    
    Args:
        crop: Filter by crop name (rice, wheat, cotton, sugarcane, pulses).
              If omitted, returns all crops.
    """
    if crop:
        crop_lower = crop.lower()
        if crop_lower in CROP_CALENDAR:
            return {"success": True, "crop": CROP_CALENDAR[crop_lower]}
        return {"success": False, "error": f"Crop '{crop}' not found. Available: {', '.join(CROP_CALENDAR.keys())}"}
    
    return {
        "success": True,
        "crops": CROP_CALENDAR,
        "total_crops": len(CROP_CALENDAR)
    }


@router.get("/pest-management")
async def get_pest_management(pest: Optional[str] = None):
    """
    Get detailed pest and disease management information.
    
    Returns symptoms, causes, prevention tips, organic controls,
    and chemical controls for each pest/disease.
    
    Args:
        pest: Filter by pest/disease key (blast_rice, rust_wheat, bollworm_cotton,
              powdery_mildew). If omitted, returns all.
    """
    if pest:
        pest_lower = pest.lower()
        if pest_lower in PEST_DISEASE_DB:
            return {"success": True, "pest": PEST_DISEASE_DB[pest_lower]}
        return {"success": False, "error": f"Pest '{pest}' not found. Available: {', '.join(PEST_DISEASE_DB.keys())}"}
    
    return {
        "success": True,
        "pests": PEST_DISEASE_DB,
        "total_pests": len(PEST_DISEASE_DB)
    }


@router.get("/nearby-services")
async def get_nearby_services(
    lat: float = Query(default=25.3176, description="Latitude"),
    lng: float = Query(default=82.9739, description="Longitude"),
    radius: float = Query(default=5.0, description="Search radius in km")
):
    """
    Search for nearby agricultural services using OpenStreetMap Overpass API.
    
    Returns: seed shops, fertilizer shops, pesticide shops, agricultural offices,
    tool rental services, KBTs (Krishi Bhandar/Bhavan).
    
    Args:
        lat: Latitude of location center
        lng: Longitude of location center
        radius: Search radius in kilometers (default 5km)
    """
    import httpx
    
    # Overpass API query to find agricultural services
    overpass_url = "https://overpass-api.de/api/interpreter"
    
    # Convert radius to degrees (approximate)
    radius_deg = radius / 111.0
    
    bbox = f"{lat - radius_deg},{lng - radius_deg},{lat + radius_deg},{lng + radius_deg}"
    
    overpass_query = f"""
    [out:json][timeout:30];
    (
      node["shop"="agricultural"]({bbox});
      node["shop"="agrarian"]({bbox});
      node["shop"="seeds"]({bbox});
      node["shop"="fertilizer"]({bbox});
      node["shop"="pesticide"]({bbox});
      node["office"="agricultural_extension"]({bbox});
      way["shop"="agricultural"]({bbox});
    );
    out body center;
    """
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(
                overpass_url,
                data={"data": overpass_query}
            )
            
            if resp.status_code != 200:
                return {
                    "success": False,
                    "error": f"Overpass API returned {resp.status_code}",
                    "fallback": use_fallback_nearby_data(lat, lng)
                }
            
            data = resp.json()
            elements = data.get("elements", [])
            
            services = []
            for el in elements:
                tags = el.get("tags", {})
                name = tags.get("name", "Agricultural Shop")
                shop_type = tags.get("shop", "agricultural")
                
                # Determine service category
                if "seed" in str(shop_type).lower() or "seed" in str(name).lower():
                    category = "seed_shop"
                    icon = "🌱"
                elif "fertilizer" in str(shop_type).lower() or "fertilizer" in str(name).lower():
                    category = "fertilizer_shop"
                    icon = "🧪"
                elif "pesticide" in str(shop_type).lower() or "pesticide" in str(name).lower():
                    category = "pesticide_shop"
                    icon = "🧴"
                elif "KBT" in name.upper() or "krishi bhavan" in name.lower() or "krishi bhandar" in name.lower():
                    category = "kbt"
                    icon = "🏛️"
                else:
                    category = "agricultural_shop"
                    icon = "🛒"
                
                lat_el = el.get("lat", el.get("center", {}).get("lat", lat))
                lng_el = el.get("lon", el.get("center", {}).get("lon", lng))
                
                services.append({
                    "name": name,
                    "category": category,
                    "icon": icon,
                    "latitude": lat_el,
                    "longitude": lng_el,
                    "address": tags.get("address", ""),
                    "phone": tags.get("phone", ""),
                    "opening_hours": tags.get("opening_hours", ""),
                })
            
            return {
                "success": True,
                "services": services,
                "total_found": len(services),
                "search_area": {
                    "latitude": lat,
                    "longitude": lng,
                    "radius_km": radius
                }
            }
            
    except Exception as e:
        logger.error(f"Nearby services error: {e}")
        return {
            "success": True,
            "services": use_fallback_nearby_data(lat, lng),
            "total_found": 8,
            "search_area": {"latitude": lat, "longitude": lng, "radius_km": radius},
            "note": "Using demo data (Overpass API unavailable)"
        }


def use_fallback_nearby_data(lat: float, lng: float) -> list:
    """Generate demo nearby service locations when Overpass API is unavailable."""
    services = [
        {"name": "Krishi Bhandar - KBT Center", "category": "kbt", "icon": "🏛️", "latitude": lat + 0.008, "longitude": lng - 0.005, "address": "Near Main Market", "phone": "", "opening_hours": "9:00 AM - 5:00 PM"},
        {"name": "Green Seed Store", "category": "seed_shop", "icon": "🌱", "latitude": lat - 0.006, "longitude": lng + 0.004, "address": "Opposite Bus Stand", "phone": "", "opening_hours": "8:00 AM - 8:00 PM"},
        {"name": "Fertilizer Supply Co.", "category": "fertilizer_shop", "icon": "🧪", "latitude": lat + 0.005, "longitude": lng + 0.008, "address": "Industrial Area", "phone": "", "opening_hours": "9:00 AM - 6:00 PM"},
        {"name": "Pesticide & Chemical Store", "category": "pesticide_shop", "icon": "🧴", "latitude": lat - 0.004, "longitude": lng - 0.007, "address": "Market Road", "phone": "", "opening_hours": "9:00 AM - 7:00 PM"},
        {"name": "Krishi Vigyan Kendra", "category": "kbt", "icon": "🏛️", "latitude": lat + 0.012, "longitude": lng - 0.002, "address": "Agricultural University Campus", "phone": "", "opening_hours": "10:00 AM - 5:00 PM"},
        {"name": "Agri Tool Rental Center", "category": "agricultural_shop", "icon": "🛒", "latitude": lat - 0.003, "longitude": lng + 0.010, "address": "Village Road Crossing", "phone": "", "opening_hours": "7:00 AM - 7:00 PM"},
        {"name": "Organic Fertilizer Depot", "category": "fertilizer_shop", "icon": "🧪", "latitude": lat + 0.007, "longitude": lng - 0.010, "address": "Gram Panchayat Road", "phone": "", "opening_hours": "9:00 AM - 6:00 PM"},
        {"name": "Premium Seed House", "category": "seed_shop", "icon": "🌱", "latitude": lat - 0.009, "longitude": lng + 0.006, "address": "Near Railway Station", "phone": "", "opening_hours": "8:00 AM - 8:00 PM"},
    ]
    
    # Calculate approximate distances
    for s in services:
        dlat = s["latitude"] - lat
        dlng = s["longitude"] - lng
        dist_km = round(math.sqrt(dlat**2 + dlng**2) * 111, 2)
        s["distance_km"] = dist_km
    
    # Sort by distance
    services.sort(key=lambda x: x["distance_km"])
    return services


@router.get("/farming-tips")
async def get_farming_tips():
    """Get current season farming tips and reminders."""
    
    month = datetime.now().month
    
    # Determine current season
    if 6 <= month <= 9:
        season = "Kharif (Monsoon Season) — 🌧️"
        season_crops = ["Rice", "Cotton", "Sugarcane", "Arhar (Pigeon Pea)"]
        tips = [
            "🌱 Complete sowing before July end for best yields",
            "💧 Ensure proper drainage in low-lying fields",
            "🧪 Apply basal fertilizer before transplanting",
            "🐛 Monitor for stem borer in rice and bollworm in cotton",
            "🌿 Remove weeds within 20-25 days of sowing",
        ]
    elif 10 <= month <= 2:
        season = "Rabi (Winter Season) — ❄️"
        season_crops = ["Wheat", "Mustard", "Chickpea", "Peas", "Barley"]
        tips = [
            "🌱 Sow wheat before November 15 for optimal yield",
            "💧 First irrigation at crown root initiation stage (20-25 days)",
            "🧪 Apply 1/3 nitrogen + full P & K as basal",
            "🐛 Watch for rust in wheat — spray at first sign",
            "🌿 Control broadleaf weeds with 2,4-D within 30 days",
        ]
    else:
        season = "Zaid (Summer Season) — ☀️"
        season_crops = ["Summer Moong", "Vegetables", "Fodder crops"]
        tips = [
            "🌱 Best for short-duration crops and vegetables",
            "💧 Maintain regular irrigation schedule",
            "🧪 Use organic mulching to retain soil moisture",
            "🐛 Monitor for thrips and mites in vegetables",
            "🌿 Plan for next Kharif season — prepare nursery beds",
        ]
    
    return {
        "success": True,
        "current_month": month,
        "current_season": season,
        "recommended_crops": season_crops,
        "tips": tips,
        "message": f"🌾 It's {season} season. Recommended crops: {', '.join(season_crops)}"
    }
