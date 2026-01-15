"""
Scheduler Configuration
Manages background jobs for data fetching
"""
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger
from datetime import datetime, timedelta
from typing import Dict, Optional, Any
import logging
from config import settings
from cache.cache_manager import cache
from services.yahoo_service import yahoo_service
from services.tefas_service import tefas_service

logger = logging.getLogger(__name__)

class DataScheduler:
    """Background scheduler for periodic data fetching"""
    
    def __init__(self):
        self.scheduler = BackgroundScheduler(
            timezone="Europe/Istanbul",  # Turkish timezone
            job_defaults={
                'coalesce': True,
                'max_instances': 1,
                'misfire_grace_time': 300  # 5 minutes grace period
            }
        )
        self.last_fetch_times: Dict[str, Optional[str]] = {
            "stocks": None,
            "forex": None,
            "commodities": None,
            "funds": None
        }
    
    def _fetch_stock_group_generic(self, group_symbols: list[str], group_name: str, include_forex_commodities: bool = False) -> None:
        """
        Generic method to fetch a stock group (DRY principle)
        
        Args:
            group_symbols: List of stock symbols to fetch
            group_name: Name for logging
            include_forex_commodities: Whether to also fetch forex and commodities
        """
        try:
            logger.info(f"⏰ Fetching: {group_name}" + (" + Forex + Commodities" if include_forex_commodities else ""))
            
            # Fetch stock group
            stocks = yahoo_service.fetch_stock_group(group_symbols, group_name)
            if stocks:
                current_stocks = cache.get_stocks()
                # Remove old stocks from this group, add new ones
                updated_stocks = [s for s in current_stocks if s['symbol'] not in group_symbols]
                updated_stocks.extend(stocks)
                cache.update_stocks(updated_stocks)
                self.last_fetch_times["stocks"] = datetime.now().isoformat()
            
            # Optionally fetch forex and commodities (Group 1 only)
            if include_forex_commodities:
                forex = yahoo_service.fetch_forex()
                if forex:
                    cache.update_forex(forex)
                    self.last_fetch_times["forex"] = datetime.now().isoformat()
                
                commodities = yahoo_service.fetch_commodities()
                if commodities:
                    cache.update_commodities(commodities)
                    self.last_fetch_times["commodities"] = datetime.now().isoformat()
            
            logger.info(f"✅ {group_name} completed")
        except Exception as e:
            logger.error(f"❌ Error in {group_name}: {e}", exc_info=True)
    
    def fetch_stock_group_1(self):
        """Fetch BIST100 Group 1 + Forex + Commodities (minute 0)"""
        self._fetch_stock_group_generic(settings.BIST100_GROUP_1, "Stock Group 1", include_forex_commodities=True)
    
    def fetch_stock_group_2(self):
        """Fetch BIST100 Group 2 (minute 3)"""
        self._fetch_stock_group_generic(settings.BIST100_GROUP_2, "Stock Group 2")
    
    def fetch_stock_group_3(self):
        """Fetch BIST100 Group 3 (minute 6)"""
        self._fetch_stock_group_generic(settings.BIST100_GROUP_3, "Stock Group 3")
    
    def fetch_stock_group_4(self):
        """Fetch BIST100 Group 4 (minute 9)"""
        self._fetch_stock_group_generic(settings.BIST100_GROUP_4, "Stock Group 4")
    
    def fetch_stock_group_5(self):
        """Fetch BIST100 Group 5 (minute 12)"""
        self._fetch_stock_group_generic(settings.BIST100_GROUP_5, "Stock Group 5")
    
    def fetch_group_b_data(self):
        """
        GROUP B: Fetch TEFAS funds (3 times daily: 10:00, 14:00, 18:00)
        This is the low-frequency job
        """
        try:
            logger.info("⏰ Scheduled fetch: Group B data (TEFAS funds)")
            
            # Fetch funds data
            funds_data = tefas_service.fetch_all_funds()
            
            # Update cache
            if funds_data:
                cache.update_funds(funds_data)
                self.last_fetch_times["funds"] = datetime.now().isoformat()
                logger.info(f"✅ Updated {len(funds_data)} TEFAS funds")
            else:
                logger.warning("⚠️  No funds data received")
            
            logger.info("✅ Group B fetch completed")
            
        except Exception as e:
            logger.error(f"❌ Error in Group B fetch: {e}", exc_info=True)
    
    def setup_jobs(self):
        """Configure all scheduled jobs"""
        
        # STOCK GROUPS: Every 15 minutes with 3-minute offsets
        stock_groups = [
            (self.fetch_stock_group_1, 0, "Stock Group 1 + Forex + Commodities"),
            (self.fetch_stock_group_2, 3, "Stock Group 2"),
            (self.fetch_stock_group_3, 6, "Stock Group 3"),
            (self.fetch_stock_group_4, 9, "Stock Group 4"),
            (self.fetch_stock_group_5, 12, "Stock Group 5")
        ]
        
        for idx, (fetch_func, offset_minutes, job_name) in enumerate(stock_groups, 1):
            start_date = datetime.now() + timedelta(minutes=offset_minutes) if offset_minutes > 0 else None
            
            self.scheduler.add_job(
                fetch_func,
                trigger=IntervalTrigger(
                    minutes=settings.HIGH_FREQ_INTERVAL_MINUTES,
                    start_date=start_date
                ),
                id=f'stock_group_{idx}',
                name=job_name,
                replace_existing=True
            )
            logger.info(f"📅 Scheduled {job_name.split('+')[0].strip()}: Every {settings.HIGH_FREQ_INTERVAL_MINUTES} minutes (offset {offset_minutes})")
        
        # GROUP B: 3 times daily at specific times (TEFAS Funds)
        for fetch_time in settings.FUND_FETCH_TIMES:
            hour, minute = fetch_time.split(":")
            
            self.scheduler.add_job(
                self.fetch_group_b_data,
                trigger=CronTrigger(hour=int(hour), minute=int(minute)),
                id=f'group_b_job_{fetch_time}',
                name=f'Fetch Group B (TEFAS Funds) at {fetch_time}',
                replace_existing=True
            )
            logger.info(f"📅 Scheduled Group B: Daily at {fetch_time}")
        
        # Initial fetch on startup (run immediately)
        logger.info("🚀 Running initial data fetch...")
        self.fetch_stock_group_1()  # Fetch Group 1 + Forex + Commodities immediately
        self.fetch_group_b_data()  # Fetch Group B immediately
    
    def start(self) -> None:
        """Start the scheduler"""
        self.setup_jobs()
        self.scheduler.start()
        logger.info("✅ Scheduler started successfully")
    
    def shutdown(self) -> None:
        """Gracefully shutdown the scheduler"""
        if self.scheduler.running:
            self.scheduler.shutdown(wait=True)
            logger.info("🛑 Scheduler shut down")
    
    def get_status(self) -> Dict[str, Any]:
        """Get scheduler status"""
        jobs: list[Dict[str, Any]] = []
        for job in self.scheduler.get_jobs():
            jobs.append({
                "id": job.id,
                "name": job.name,
                "next_run": job.next_run_time.isoformat() if job.next_run_time else None
            })
        
        return {
            "running": self.scheduler.running,
            "jobs": jobs,
            "last_fetch": self.last_fetch_times
        }

# Global scheduler instance
data_scheduler = DataScheduler()
