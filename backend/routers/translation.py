"""
Krishi Drishti - Translation Router
Provides localized responses in Telugu, Hindi, and English.
"""
from fastapi import APIRouter, Query
from typing import Optional

router = APIRouter(prefix="/api/v1/translate", tags=["Translation"])

# Translation dictionaries for key terms
TRANSLATIONS = {
    "te": {  # Telugu
        "crop_health": "పంట ఆరోగ్యం",
        "soil_moisture": "నేల తేమ",
        "weather": "వాతావరణం",
        "pest_risk": "తెగుళ్ళ ప్రమాదం",
        "ndvi": "NDVI - మొక్కల ఆరోగ్య సూచిక",
        "evi": "EVI - మెరుగైన వృక్ష సూచిక",
        "ndwi": "NDWI - నీటి సూచిక",
        "recommendations": "సిఫార్సులు",
        "healthy": "ఆరోగ్యకరమైన",
        "moderate": "మితమైన",
        "stressed": "ఒత్తిడికి గురైన",
        "irrigation_advice": "నీటి పారుదల సలహా",
        "analyze": "విశ్లేషించండి",
        "upload_csv": "CSV అప్‌లోడ్ చేయండి",
        "dashboard": "డ్యాష్‌బోర్డ్",
        "report": "నివేదిక",
        "field": "పొలం",
        "area": "విస్తీర్ణం",
        "temperature": "ఉష్ణోగ్రత",
        "humidity": "తేమ",
        "rainfall": "వర్షపాతం",
        "wind": "గాలి",
        "solar_radiation": "సౌర వికిరణం",
        "evapotranspiration": "బాష్పీభవనం",
        "drainage": "నీటి ఎద్దడి",
        "organic_matter": "సేంద్రియ పదార్థం",
        "action_required": "చర్య అవసరం",
        "monitor": "పర్యవేక్షించండి",
        "good": "మంచిది",
        "critical": "క్లిష్టమైన",
        "jai_kisan": "జై కిసాన్"
    },
    "hi": {  # Hindi
        "crop_health": "फसल स्वास्थ्य",
        "soil_moisture": "मिट्टी की नमी",
        "weather": "मौसम",
        "pest_risk": "कीट जोखिम",
        "ndvi": "NDVI - वनस्पति स्वास्थ्य सूचकांक",
        "evi": "EVI - उन्नत वनस्पति सूचकांक",
        "ndwi": "NDWI - जल सूचकांक",
        "recommendations": "सिफारिशें",
        "healthy": "स्वस्थ",
        "moderate": "मध्यम",
        "stressed": "तनावग्रस्त",
        "irrigation_advice": "सिंचाई सलाह",
        "analyze": "विश्लेषण करें",
        "upload_csv": "CSV अपलोड करें",
        "dashboard": "डैशबोर्ड",
        "report": "रिपोर्ट",
        "field": "खेत",
        "area": "क्षेत्रफल",
        "temperature": "तापमान",
        "humidity": "आर्द्रता",
        "rainfall": "वर्षा",
        "wind": "हवा",
        "solar_radiation": "सौर विकिरण",
        "evapotranspiration": "वाष्पीकरण-उत्सर्जन",
        "drainage": "जल निकासी",
        "organic_matter": "कार्बनिक पदार्थ",
        "action_required": "कार्रवाई आवश्यक",
        "monitor": "निगरानी करें",
        "good": "अच्छा",
        "critical": "गंभीर",
        "jai_kisan": "जय किसान"
    }
}


@router.get("/{language}/{term}")
async def translate_term(language: str, term: str):
    """Translate a single term to the specified language."""
    if language not in TRANSLATIONS:
        return {"error": f"Unsupported language. Supported: {list(TRANSLATIONS.keys())}"}
    
    translation = TRANSLATIONS[language].get(term, term)
    return {
        "term": term,
        "language": language,
        "translation": translation
    }


@router.get("/{language}")
async def get_all_translations(language: str):
    """Get all translations for a language."""
    if language not in TRANSLATIONS:
        return {"error": f"Unsupported language. Supported: {list(TRANSLATIONS.keys())}"}
    
    return {
        "language": language,
        "translations": TRANSLATIONS[language]
    }


@router.get("/supported")
async def get_supported_languages():
    """Get list of supported languages."""
    return {
        "languages": [
            {"code": "en", "name": "English"},
            {"code": "te", "name": "తెలుగు (Telugu)"},
            {"code": "hi", "name": "हिन्दी (Hindi)"}
        ]
    }
