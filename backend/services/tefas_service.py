"""
TEFAS Service - Group B Data Fetcher
Fetches Turkish Investment Funds 3 times daily (10:00, 14:00, 18:00)
"""
from tefas import Crawler
from datetime import datetime, date, timedelta
from typing import List, Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

class TefasService:
    """Service to fetch TEFAS fund data"""
    
    def __init__(self):
        """Initialize TEFAS crawler with error handling"""
        self.crawler: Optional[Crawler] = None
        try:
            self.crawler = Crawler()
            logger.info("✅ TEFAS crawler initialized")
        except Exception as e:
            logger.warning(f"⚠️  TEFAS crawler initialization failed: {e}")
            logger.warning("🎭 TEFAS service will return empty data")
    
    def fetch_all_funds(self) -> List[Dict[str, Any]]:
        """
        Fetch all investment funds from TEFAS
        Returns list of fund dictionaries
        """
        if not self.crawler:
            logger.warning("⚠️  TEFAS crawler not available")
            return []
        
        logger.info("📊 Fetching TEFAS funds data...")
        
        try:
            return self._fetch_popular_funds()
            
        except Exception as e:
            logger.error(f"❌ Error fetching TEFAS funds: {e}")
            return []
    
    def _fetch_popular_funds(self) -> List[Dict[str, Any]]:
        """
        Fetch popular Turkish funds with proper keyword arguments
        """
        popular_funds = [
            "TCD", "MAC", "GAH", "GEF", "AHL", "AKE", "AYT",
            "TFF", "YAT", "IPM", "HVT", "IVG", "HSY"
        ]
        
        funds_data = []
        today = date.today()
        start_date = today - timedelta(days=7)  # Fetch last 7 days for more reliable data
        
        if not self.crawler:
            logger.warning("⚠️  TEFAS crawler not available")
            return []
        
        failed_funds = []
        
        try:
            for fund_code in popular_funds:
                try:
                    # CRITICAL: Use keyword arguments as required by tefas-crawler
                    # fetch(start=date, columns=list)
                    fund_df = self.crawler.fetch(
                        start=start_date,
                        columns=[fund_code]
                    )
                    
                    if fund_df is not None and not fund_df.empty:
                        # Get the most recent row
                        row = fund_df.iloc[-1]
                        
                        # Try to get price from the fund code column
                        price = 0.0
                        if fund_code in fund_df.columns:
                            price = float(row[fund_code]) if row[fund_code] else 0.0
                        
                        # Calculate change if we have multiple rows
                        change = 0.0
                        change_percent = 0.0
                        if len(fund_df) > 1:
                            previous_price = float(fund_df.iloc[-2][fund_code]) if fund_code in fund_df.columns else 0.0
                            if previous_price > 0:
                                change = price - previous_price
                                change_percent = (change / previous_price) * 100
                        
                        fund_item = {
                            "code": fund_code,
                            "name": fund_code,  # TEFAS API doesn't return names easily
                            "price": round(price, 4),
                            "change": round(change, 4),
                            "change_percent": round(change_percent, 2),
                            "timestamp": datetime.now().isoformat()
                        }
                        
                        funds_data.append(fund_item)
                        
                except Exception as e:
                    failed_funds.append((fund_code, str(e)))
                    continue
            
            # Log summary instead of individual errors
            if failed_funds:
                logger.warning(f"⚠️  Failed to fetch {len(failed_funds)}/{len(popular_funds)} funds: {', '.join([f[0] for f in failed_funds[:3]])}{'...' if len(failed_funds) > 3 else ''}")
            
            logger.info(f"✅ Successfully fetched {len(funds_data)}/{len(popular_funds)} funds")
            return funds_data
            
        except Exception as e:
            logger.error(f"❌ Critical error in fund fetch: {e}")
            return []

# Create service instance
tefas_service = TefasService()
