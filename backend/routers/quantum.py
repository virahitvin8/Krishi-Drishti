"""
Krishi Drishti — Quantum Computing API Router
===============================================
Exposes quantum-enhanced analysis as REST API endpoints.
Uses free IBM Qiskit AerSimulator (no API key needed for simulator).

Endpoints:
  GET  /api/v1/quantum/status        — Check quantum service status
  POST /api/v1/quantum/analyze       — Quantum crop health classification
  POST /api/v1/quantum/irrigation    — Quantum irrigation optimization

Free tier note: All simulator endpoints are unlimited and free.
IBM Quantum real hardware requires API key (10 min/month free).
"""

import logging
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional

from ..services.quantum_service import (
    quantum_crop_classifier,
    quantum_irrigation_optimization,
    format_quantum_response,
    _qiskit_available,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/quantum", tags=["quantum"])


# ── Request/Response Models ──

class QuantumAnalyzeRequest(BaseModel):
    ndvi: float = Field(default=0.48, ge=0.0, le=1.0, description="Normalized Difference Vegetation Index")
    evi: float = Field(default=0.51, ge=0.0, le=1.0, description="Enhanced Vegetation Index")
    ndwi: float = Field(default=0.31, ge=0.0, le=1.0, description="Normalized Difference Water Index")
    reip: float = Field(default=0.32, ge=0.0, le=1.0, description="Red Edge Inflection Point")
    savi: float = Field(default=0.35, ge=0.0, le=1.0, description="Soil Adjusted Vegetation Index")


class IrrigationRequest(BaseModel):
    field_count: int = Field(default=4, ge=1, le=10, description="Number of fields to optimize")
    moisture_levels: Optional[list[float]] = Field(default=None, description="Soil moisture % per field")
    evaporation_rates: Optional[list[float]] = Field(default=None, description="ET rates mm/day per field")


# ── Endpoints ──

@router.get("/status")
async def quantum_status():
    """Check if quantum computing service is available and ready."""
    return {
        "service": "Krishi Drishti Quantum Engine",
        "status": "operational",
        "qiskit_installed": _qiskit_available(),
        "simulators": {
            "aer_simulator": True,  # Always available (local)
            "ibm_quantum_hardware": False,  # Requires IBM_QUANTUM_TOKEN env var
        },
        "free_tier_info": {
            "local_simulator": "✅ Unlimited, free, no API key needed",
            "ibm_quantum": "⚠️ 10 min/month free on real hardware (set IBM_QUANTUM_TOKEN)",
            "aws_braket": "⚠️ Free simulator credits (pip install amazon-braket-sdk)",
        },
        "endpoints": {
            "analyze": "POST /api/v1/quantum/analyze",
            "irrigation": "POST /api/v1/quantum/irrigation",
        }
    }


@router.post("/analyze")
async def quantum_analyze(request: QuantumAnalyzeRequest):
    """
    Classify crop health using a quantum circuit.
    
    Encodes vegetation indices (NDVI, EVI, NDWI, REIP, SAVI) into 
    quantum rotation angles and uses entanglement gates to detect 
    complex correlations between indices. Returns health classification 
    with confidence score.
    
    Uses free AerSimulator (no API key needed) or IBM Quantum hardware
    if IBM_QUANTUM_TOKEN is set.
    """
    try:
        result = quantum_crop_classifier(
            ndvi=request.ndvi,
            evi=request.evi,
            ndwi=request.ndwi,
            reip=request.reip,
            savi=request.savi,
        )
        return {
            "success": True,
            "method": result.get("method", "quantum"),
            "classification": result.get("quantum_classification", "Unknown"),
            "quantum_score": result.get("quantum_score", 0),
            "confidence": result.get("confidence", 0),
            "circuit_depth": result.get("circuit_depth", 0),
            "top_bitstring": result.get("top_bitstring", ""),
            "backend": result.get("backend", "unknown"),
            "indices": {
                "ndvi": request.ndvi,
                "evi": request.evi,
                "ndwi": request.ndwi,
                "reip": request.reip,
                "savi": request.savi,
            }
        }
    except Exception as e:
        logger.error(f"Quantum analyze error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/irrigation")
async def quantum_irrigation(request: IrrigationRequest):
    """
    Optimize irrigation scheduling using QAOA (Quantum Approximate 
    Optimization Algorithm).
    
    Takes soil moisture levels and ET rates for multiple fields and
    computes an optimized irrigation schedule to minimize total water
    usage while keeping all fields healthy.
    """
    try:
        result = quantum_irrigation_optimization(
            field_count=request.field_count,
            moisture_levels=request.moisture_levels,
            evaporation_rates=request.evaporation_rates,
        )
        return {
            "success": True,
            "optimization": result.get("optimization", ""),
            "schedule": result.get("schedule", []),
            "method": result.get("method", "quantum"),
        }
    except Exception as e:
        logger.error(f"Quantum irrigation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/full-analysis")
async def quantum_full_analysis(request: QuantumAnalyzeRequest):
    """Complete quantum analysis: classification + irrigation optimization."""
    try:
        result = format_quantum_response(
            ndvi=request.ndvi,
            evi=request.evi,
            ndwi=request.ndwi,
            reip=request.reip,
            savi=request.savi,
        )
        return result
    except Exception as e:
        logger.error(f"Quantum full analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
