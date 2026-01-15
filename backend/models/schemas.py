from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class StockData(BaseModel):
    """Individual stock/asset data model"""
    symbol: str
    name: Optional[str] = None
    price: float
    change: float
    change_percent: float
    volume: Optional[int] = None
    market_cap: Optional[float] = None
    timestamp: datetime = Field(default_factory=datetime.now)

class ForexData(BaseModel):
    """Forex pair data model"""
    pair: str
    rate: float
    change: float
    change_percent: float
    timestamp: datetime = Field(default_factory=datetime.now)

class CommodityData(BaseModel):
    """Commodity data model"""
    symbol: str
    name: str
    price: float
    change: float
    change_percent: float
    timestamp: datetime = Field(default_factory=datetime.now)

class FundData(BaseModel):
    """TEFAS fund data model"""
    code: str
    name: str
    price: float
    change: float
    change_percent: float
    timestamp: datetime = Field(default_factory=datetime.now)

class MarketDataResponse(BaseModel):
    """Complete market data response"""
    bist100: List[StockData] = []
    forex: List[ForexData] = []
    commodities: List[CommodityData] = []
    funds: List[FundData] = []
    last_updated: Dict[str, Any] = {
        "stocks": None,
        "funds": None
    }
    
class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    scheduler_status: str
    last_fetch: Dict[str, Any]
    uptime_seconds: float
