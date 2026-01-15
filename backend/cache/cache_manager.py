import json
import threading
from datetime import datetime
from typing import Dict, Any, List
from config import settings
import logging

logger = logging.getLogger(__name__)

class CacheManager:
    """
    Thread-safe cache manager with in-memory storage and JSON persistence.
    """
    
    def __init__(self):
        self._cache: Dict[str, Any] = {
            "bist100": [],
            "forex": [],
            "commodities": [],
            "funds": [],
            "last_updated": {
                "stocks": None,
                "funds": None
            }
        }
        self._lock = threading.Lock()
        self._load_from_disk()
    
    def _load_from_disk(self):
        """Load cached data from JSON files on startup"""
        try:
            # Load market data (stocks, forex, commodities)
            try:
                with open(settings.MARKET_DATA_FILE, 'r', encoding='utf-8') as f:
                    market_data = json.load(f)
                    with self._lock:
                        self._cache["bist100"] = market_data.get("bist100", [])
                        self._cache["forex"] = market_data.get("forex", [])
                        self._cache["commodities"] = market_data.get("commodities", [])
                        self._cache["last_updated"]["stocks"] = market_data.get("last_updated")
                    logger.info("Market data loaded from disk")
            except FileNotFoundError:
                logger.info("No existing market data file found")
            
            # Load funds data
            try:
                with open(settings.FUNDS_DATA_FILE, 'r', encoding='utf-8') as f:
                    funds_data = json.load(f)
                    with self._lock:
                        self._cache["funds"] = funds_data.get("funds", [])
                        self._cache["last_updated"]["funds"] = funds_data.get("last_updated")
                    logger.info("Funds data loaded from disk")
            except FileNotFoundError:
                logger.info("No existing funds data file found")
                
        except Exception as e:
            logger.error(f"Error loading cache from disk: {e}")
    
    def _save_to_disk(self, data_type: str):
        """Persist cache to disk"""
        try:
            if data_type == "market":
                data = {
                    "bist100": self._cache["bist100"],
                    "forex": self._cache["forex"],
                    "commodities": self._cache["commodities"],
                    "last_updated": self._cache["last_updated"]["stocks"]
                }
                with open(settings.MARKET_DATA_FILE, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                logger.info("Market data saved to disk")
                
            elif data_type == "funds":
                data = {
                    "funds": self._cache["funds"],
                    "last_updated": self._cache["last_updated"]["funds"]
                }
                with open(settings.FUNDS_DATA_FILE, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                logger.info("Funds data saved to disk")
                
        except Exception as e:
            logger.error(f"Error saving cache to disk: {e}")
    
    def _update_market_item(self, item_key: str, data: List[Dict[str, Any]]):
        """Generic method to update market items (DRY principle)"""
        with self._lock:
            self._cache[item_key] = data
            self._cache["last_updated"]["stocks"] = datetime.now().isoformat()
        self._save_to_disk("market")
    
    def update_stocks(self, stocks_data: List[Dict[str, Any]]):
        """Update BIST100 stocks cache"""
        self._update_market_item("bist100", stocks_data)
    
    def update_forex(self, forex_data: List[Dict[str, Any]]):
        """Update forex cache"""
        self._update_market_item("forex", forex_data)
    
    def update_commodities(self, commodities_data: List[Dict[str, Any]]):
        """Update commodities cache"""
        self._update_market_item("commodities", commodities_data)
    
    def update_funds(self, funds_data: List[Dict[str, Any]]):
        """Update funds cache"""
        with self._lock:
            self._cache["funds"] = funds_data
            self._cache["last_updated"]["funds"] = datetime.now().isoformat()
        self._save_to_disk("funds")
    
    def get_all_data(self) -> Dict[str, Any]:
        """Get all cached data (thread-safe read)"""
        with self._lock:
            return self._cache.copy()
    
    def get_stocks(self) -> List[Dict[str, Any]]:
        """Get BIST100 stocks"""
        with self._lock:
            return self._cache["bist100"].copy()
    
    def get_forex(self) -> List[Dict[str, Any]]:
        """Get forex data"""
        with self._lock:
            return self._cache["forex"].copy()
    
    def get_commodities(self) -> List[Dict[str, Any]]:
        """Get commodities data"""
        with self._lock:
            return self._cache["commodities"].copy()
    
    def get_funds(self) -> List[Dict[str, Any]]:
        """Get funds data"""
        with self._lock:
            return self._cache["funds"].copy()
    
    def get_last_updated(self) -> Dict[str, Any]:
        """Get last update timestamps"""
        with self._lock:
            return self._cache["last_updated"].copy()

# Global cache instance
cache = CacheManager()
