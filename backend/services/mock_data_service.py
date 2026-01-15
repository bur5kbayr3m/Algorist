"""
Mock Data Service - Smart Fallback with Cache-Based Realism
Generates realistic fake data based on last known successful prices (Ghost Mode)
"""
import random
import json
import os
from datetime import datetime
from typing import List, Dict, Any, Optional
import logging
from pathlib import Path

logger = logging.getLogger(__name__)


class MockDataService:
    """Generate realistic mock financial data based on cached values"""
    
    # Fallback base prices if no cache exists
    FALLBACK_PRICES = {
        "THYAO.IS": 285.50,
        "GARAN.IS": 145.20,
        "AKBNK.IS": 62.75,
        "YKBNK.IS": 38.40,
        "SAHOL.IS": 91.30,
        "EREGL.IS": 52.15,
        "KCHOL.IS": 168.90,
        "TUPRS.IS": 142.60,
        "SISE.IS": 48.25,
        "ASELS.IS": 102.80,
        "PETKM.IS": 195.40,
        "KOZAL.IS": 37.95,
        "PGSUS.IS": 312.50,
        "TTKOM.IS": 15.85,
        "ISCTR.IS": 9.42,
        "VESTL.IS": 58.70,
        "BIMAS.IS": 225.80,
        "ENKAI.IS": 12.34,
        "TAVHL.IS": 89.15,
        "TCELL.IS": 124.50,
    }
    
    def __init__(self):
        """Initialize smart mock data service"""
        self.cache_file = Path("data/market_data.json")
        self.funds_cache_file = Path("data/funds_data.json")
        self._cached_data: Optional[Dict[str, Any]] = None
        logger.info("🎭 Smart Mock Data Service initialized (Ghost Mode)")
    
    def _load_cache(self) -> Dict[str, Any]:
        """
        Load cached data from disk (last known successful data)
        Returns empty dict if file doesn't exist
        """
        if self._cached_data is not None:
            return self._cached_data
        
        try:
            if self.cache_file.exists():
                with open(self.cache_file, 'r', encoding='utf-8') as f:
                    self._cached_data = json.load(f)
                    logger.info(f"👻 Ghost Mode: Loaded cache from {self.cache_file}")
                    return self._cached_data
        except Exception as e:
            logger.warning(f"⚠️  Failed to load cache: {e}")
        
        self._cached_data = {}
        return self._cached_data
    
    def _get_base_price(self, symbol: str, asset_type: str = "stocks") -> Dict[str, Any]:
        """
        Get base price and metadata from cache or fallback
        
        Args:
            symbol: Stock symbol (e.g., 'THYAO.IS')
            asset_type: Type of asset ('stocks', 'forex', 'commodities')
        
        Returns:
            Dict with base_price, name, market_cap (if available)
        """
        cache = self._load_cache()
        
        # Try to find symbol in cache
        if asset_type == "stocks":
            cached_stocks = cache.get("bist100", [])
            for stock in cached_stocks:
                if stock.get("symbol") == symbol:
                    return {
                        "base_price": stock.get("price", 100.0),
                        "name": stock.get("name", symbol.replace('.IS', '')),
                        "market_cap": stock.get("market_cap")
                    }
        
        # Fallback to hardcoded prices
        return {
            "base_price": self.FALLBACK_PRICES.get(symbol, random.uniform(10, 200)),
            "name": symbol.replace('.IS', ''),
            "market_cap": None
        }
    
    def generate_stock_data(self, symbols: List[str]) -> List[Dict[str, Any]]:
        """
        Generate realistic mock stock data based on last known prices
        Applies small random variation (±1.5%) to simulate market movement
        
        Args:
            symbols: List of stock symbols
            
        Returns:
            List of mock stock dictionaries with realistic prices
        """
        logger.info(f"🎭 Ghost Mode: Generating data for {len(symbols)} stocks (±1.5% variation)...")
        stocks_data = []
        
        for symbol in symbols:
            try:
                # Get base price from cache or fallback
                base_data = self._get_base_price(symbol, "stocks")
                base_price = base_data["base_price"]
                
                # Apply small realistic variation (±1.5%)
                variation = random.uniform(0.985, 1.015)  # 98.5% to 101.5%
                current_price = base_price * variation
                
                # Calculate change
                change = current_price - base_price
                change_percent = (change / base_price) * 100 if base_price > 0 else 0
                
                # Generate volume (realistic Turkish market volumes)
                volume = random.randint(1_000_000, 50_000_000)
                
                stock_data = {
                    "symbol": symbol,
                    "name": base_data["name"],
                    "price": round(float(current_price), 2),
                    "change": round(float(change), 2),
                    "change_percent": round(float(change_percent), 2),
                    "volume": volume,
                    "market_cap": base_data["market_cap"],
                    "timestamp": datetime.now().isoformat()
                }
                
                stocks_data.append(stock_data)
                logger.debug(f"👻 {symbol}: ₺{current_price:.2f} (base: ₺{base_price:.2f}, {change_percent:+.2f}%)")
                
            except Exception as e:
                logger.error(f"❌ Error generating mock data for {symbol}: {e}")
                continue
        
        logger.info(f"✅ Generated {len(stocks_data)} realistic mock stocks")
        return stocks_data
    
    def generate_forex_data(self) -> List[Dict[str, Any]]:
        """Generate realistic mock forex data based on cache"""
        logger.info("🎭 Ghost Mode: Generating forex data (±1.5% variation)...")
        
        cache = self._load_cache()
        cached_forex = cache.get("forex", [])
        
        forex_data = []
        forex_pairs = [
            {"pair": "USD/TRY", "symbol": "TRY=X", "fallback": 34.25},
            {"pair": "EUR/TRY", "symbol": "EURTRY=X", "fallback": 37.00},
            {"pair": "GBP/TRY", "symbol": "GBPTRY=X", "fallback": 43.50}
        ]
        
        for pair_info in forex_pairs:
            # Try to find in cache
            base_rate = pair_info["fallback"]
            for cached in cached_forex:
                if cached.get("pair") == pair_info["pair"] or cached.get("symbol") == pair_info["symbol"]:
                    base_rate = cached.get("rate", base_rate)
                    break
            
            # Apply small variation
            variation = random.uniform(0.985, 1.015)
            current_rate = base_rate * variation
            change = current_rate - base_rate
            change_percent = (change / base_rate) * 100 if base_rate > 0 else 0
            
            forex_data.append({
                "pair": pair_info["pair"],
                "symbol": pair_info["symbol"],
                "rate": round(current_rate, 4),
                "change": round(change, 4),
                "change_percent": round(change_percent, 2),
                "timestamp": datetime.now().isoformat()
            })
        
        logger.info(f"✅ Generated {len(forex_data)} realistic mock forex pairs")
        return forex_data
    
    def generate_commodities_data(self) -> List[Dict[str, Any]]:
        """Generate realistic mock commodities data based on cache"""
        logger.info("🎭 Ghost Mode: Generating commodities data (±1.5% variation)...")
        
        cache = self._load_cache()
        cached_commodities = cache.get("commodities", [])
        
        commodities_data = []
        commodity_list = [
            {"symbol": "GC=F", "name": "Gold Futures", "fallback": 2700.0},
            {"symbol": "SI=F", "name": "Silver Futures", "fallback": 31.0}
        ]
        
        for commodity_info in commodity_list:
            # Try to find in cache
            base_price = commodity_info["fallback"]
            for cached in cached_commodities:
                if cached.get("symbol") == commodity_info["symbol"]:
                    base_price = cached.get("price", base_price)
                    break
            
            # Apply small variation
            variation = random.uniform(0.985, 1.015)
            current_price = base_price * variation
            change = current_price - base_price
            change_percent = (change / base_price) * 100 if base_price > 0 else 0
            
            commodities_data.append({
                "symbol": commodity_info["symbol"],
                "name": commodity_info["name"],
                "price": round(current_price, 2),
                "change": round(change, 2),
                "change_percent": round(change_percent, 2),
                "timestamp": datetime.now().isoformat()
            })
        
        logger.info(f"✅ Generated {len(commodities_data)} realistic mock commodities")
        return commodities_data


# Create mock service instance
mock_service = MockDataService()

