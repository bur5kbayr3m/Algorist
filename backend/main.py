"""
Algorist Backend - Financial Data Service
FastAPI application serving cached market data
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import logging
import time
from typing import Any

from config import settings
from cache.cache_manager import cache
from scheduler import data_scheduler
from models.schemas import MarketDataResponse, HealthResponse

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Global state
app_start_time = time.time()

# Lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage startup and shutdown events"""
    # Startup
    logger.info("🚀 Starting Algorist Backend...")
    logger.info(f"📂 Data directory: {settings.DATA_DIR}")
    logger.info(f"⏰ Group A interval: {settings.HIGH_FREQ_INTERVAL_MINUTES} minutes")
    logger.info(f"⏰ Group B times: {', '.join(settings.FUND_FETCH_TIMES)}")
    
    # Start the scheduler
    data_scheduler.start()
    logger.info("✅ Backend started successfully")
    
    yield  # Application runs
    
    # Shutdown
    logger.info("🛑 Shutting down Algorist Backend...")
    data_scheduler.shutdown()
    logger.info("✅ Shutdown complete")

# Create FastAPI app with lifespan
app = FastAPI(
    title="Algorist Financial Data API",
    description="Centralized backend for fetching and caching financial market data",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/", tags=["Root"])
async def root() -> dict[str, Any]:
    """Root endpoint"""
    return {
        "service": "Algorist Financial Data API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "market_data": "/api/market-data",
            "health": "/health",
            "docs": "/docs"
        }
    }

@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check() -> HealthResponse:
    """
    Health check endpoint
    Returns service status and scheduler information
    """
    scheduler_status = data_scheduler.get_status()
    uptime = time.time() - app_start_time
    last_fetch_data: dict[str, Any] = scheduler_status.get("last_fetch", {})  # type: ignore
    
    return HealthResponse(
        status="ok",
        scheduler_status="running" if scheduler_status["running"] else "stopped",
        last_fetch=last_fetch_data,
        uptime_seconds=round(uptime, 2)
    )

@app.get("/api/market-data", response_model=MarketDataResponse, tags=["Market Data"])
async def get_market_data():
    """
    Get all cached market data
    
    Returns:
    - BIST100 stocks
    - Forex pairs (USD/TRY, EUR/TRY, GBP/TRY)
    - Commodities (Gold, Silver)
    - TEFAS funds
    - Last update timestamps
    
    This endpoint serves cached data, so it's extremely fast (< 10ms)
    """
    try:
        data = cache.get_all_data()
        
        return MarketDataResponse(
            bist100=data.get("bist100", []),
            forex=data.get("forex", []),
            commodities=data.get("commodities", []),
            funds=data.get("funds", []),
            last_updated=data.get("last_updated", {
                "stocks": None,
                "funds": None
            })
        )
    
    except Exception as e:
        logger.error(f"Error retrieving market data: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/api/stocks", tags=["Market Data"])
async def get_stocks() -> dict[str, Any]:
    """Get BIST100 stocks only"""
    try:
        return {
            "stocks": cache.get_stocks(),
            "last_updated": cache.get_last_updated()["stocks"]
        }
    except Exception as e:
        logger.error(f"Error retrieving stocks: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/api/forex", tags=["Market Data"])
async def get_forex() -> dict[str, Any]:
    """Get Forex pairs only"""
    try:
        return {
            "forex": cache.get_forex(),
            "last_updated": cache.get_last_updated()["stocks"]
        }
    except Exception as e:
        logger.error(f"Error retrieving forex: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/api/commodities", tags=["Market Data"])
async def get_commodities() -> dict[str, Any]:
    """Get Commodities only"""
    try:
        return {
            "commodities": cache.get_commodities(),
            "last_updated": cache.get_last_updated()["stocks"]
        }
    except Exception as e:
        logger.error(f"Error retrieving commodities: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/api/funds", tags=["Market Data"])
async def get_funds() -> dict[str, Any]:
    """Get TEFAS funds only"""
    try:
        return {
            "funds": cache.get_funds(),
            "last_updated": cache.get_last_updated()["funds"]
        }
    except Exception as e:
        logger.error(f"Error retrieving funds: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.post("/api/refresh/stocks", tags=["Admin"])
async def force_refresh_stocks() -> dict[str, str]:
    """Force immediate refresh of Stock Group 1 + Forex + Commodities (Admin endpoint)"""
    try:
        logger.info("🔄 Manual refresh triggered for Stock Group 1")
        data_scheduler.fetch_stock_group_1()
        return {"status": "success", "message": "Stock Group 1 data refreshed"}
    except Exception as e:
        logger.error(f"Error in manual refresh: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/refresh/funds", tags=["Admin"])
async def force_refresh_funds() -> dict[str, str]:
    """Force immediate refresh of TEFAS Funds (Admin endpoint)"""
    try:
        logger.info("🔄 Manual refresh triggered for TEFAS Funds")
        data_scheduler.fetch_group_b_data()
        return {"status": "success", "message": "TEFAS Funds data refreshed"}
    except Exception as e:
        logger.error(f"Error in manual refresh: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    # Run the server
    logger.info(f"🌐 Starting server on {settings.HOST}:{settings.PORT}")
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower()
    )
