"""
Yahoo Finance Service - Professional Anti-Ban Architecture with YahooQuery (Ghost Mode)
========================================================================================
Features:
- Uses yahooquery (better cookie/crumb handling than yfinance)
- Circuit Breaker Pattern (stops after 3 failures for 5 minutes)
- Singleton Session with realistic browser headers
- Ultra-conservative throttling (10-15 second delays)
- Very small batch sizes (5 symbols max)
- Automatic smart mock data fallback (cache-based)
"""
from yahooquery import Ticker
from datetime import datetime
from typing import List, Dict, Any, Optional, Callable, TypeVar, cast
import logging
import requests
from requests.adapters import HTTPAdapter
import time
import random
from threading import Lock
from config import settings
from services.mock_data_service import mock_service

logger = logging.getLogger(__name__)

# Type variable for generic return type
T = TypeVar('T')


class CircuitBreaker:
    """
    Circuit Breaker Pattern Implementation
    Prevents cascading failures by stopping requests after threshold
    """
    def __init__(self, failure_threshold: int = 3, timeout: int = 300):
        """
        Args:
            failure_threshold: Number of consecutive failures before opening circuit
            timeout: Seconds to wait before attempting to close circuit (default: 5 minutes)
        """
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failure_count = 0
        self.last_failure_time: Optional[datetime] = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
        self._lock = Lock()
    
    def call(self, func: Callable[..., T], *args: Any, **kwargs: Any) -> Optional[T]:
        """
        Execute function through circuit breaker
        
        Args:
            func: Function to execute
            *args: Positional arguments for func
            **kwargs: Keyword arguments for func
            
        Returns:
            Result of func or None if circuit is open
        """
        with self._lock:
            if self.state == "OPEN":
                # Check if timeout has passed
                if self.last_failure_time and \
                   (datetime.now() - self.last_failure_time).seconds >= self.timeout:
                    self.state = "HALF_OPEN"
                    logger.info("🔄 Circuit breaker entering HALF_OPEN state (testing)")
                else:
                    if self.last_failure_time:
                        time_remaining = self.timeout - (datetime.now() - self.last_failure_time).seconds
                        logger.error(f"⛔ Circuit breaker OPEN - requests blocked for {time_remaining}s more")
                    return None
        
        try:
            result: T = func(*args, **kwargs)
            
            with self._lock:
                if self.state == "HALF_OPEN":
                    # Success in half-open state, close circuit
                    self.state = "CLOSED"
                    self.failure_count = 0
                    logger.info("✅ Circuit breaker CLOSED - system recovered")
            
            return result
            
        except Exception as e:
            with self._lock:
                self.failure_count += 1
                self.last_failure_time = datetime.now()
                
                if self.failure_count >= self.failure_threshold:
                    self.state = "OPEN"
                    logger.error(f"🚨 Circuit breaker OPENED after {self.failure_count} failures")
                    logger.error(f"⏰ System will retry in {self.timeout} seconds")
                else:
                    logger.warning(f"⚠️  Failure {self.failure_count}/{self.failure_threshold}: {e}")
            
            raise


class SessionManager:
    """
    Singleton Session Manager with realistic browser headers
    """
    _instance: Optional['SessionManager'] = None
    _lock = Lock()
    
    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
                    cls._instance._initialize()
        return cls._instance
    
    def _initialize(self) -> None:
        """Initialize session with professional configuration"""
        self.session = requests.Session()
        
        # Realistic Chrome browser headers
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Referer': 'https://finance.yahoo.com/',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'same-origin',
            'Sec-Fetch-User': '?1',
            'Cache-Control': 'max-age=0'
        })
        
        # Connection pool configuration
        adapter = HTTPAdapter(
            pool_connections=5,  # Reduced from default 10
            pool_maxsize=5,      # Reduced from default 10
            max_retries=0,       # No automatic retries
            pool_block=False
        )
        self.session.mount('http://', adapter)
        self.session.mount('https://', adapter)
        
        logger.info("🔐 Session manager initialized with browser headers")
    
    def get_session(self) -> requests.Session:
        """Get the singleton session"""
        return self.session


class YahooFinanceService:
    """
    Professional Yahoo Finance Service with Anti-Ban Mechanisms
    """
    
    def __init__(self):
        """Initialize service with circuit breaker and session manager"""
        self.session_manager = SessionManager()
        self.circuit_breaker = CircuitBreaker(
            failure_threshold=3,  # Open circuit after 3 failures
            timeout=300           # Wait 5 minutes before retry
        )
        self.use_mock_data = False
        logger.info("🕵️  Yahoo Finance Service initialized (Anti-Ban Mode)")
    
    def _aggressive_throttle(self, min_delay: float = 10.0, max_delay: float = 15.0):
        """
        Conservative throttling between requests (Ghost Mode)
        Random delay 10-15 seconds to mimic human behavior and avoid rate limits
        """
        delay = random.uniform(min_delay, max_delay)
        logger.info(f"😴 Ghost Mode Throttle: sleeping {delay:.1f}s...")
        time.sleep(delay)
    
    def _fetch_with_circuit_breaker(self, symbols: List[str]) -> List[Dict[str, Any]]:
        """
        Internal method to fetch symbols with circuit breaker protection using yahooquery
        """
        stocks_data: List[Dict[str, Any]] = []
        
        # Ultra-conservative batch: 5 symbols at a time (Ghost Mode)
        SAFE_CHUNK_SIZE = 5  # Very small batches to avoid rate limiting
        chunks = [symbols[i:i + SAFE_CHUNK_SIZE] for i in range(0, len(symbols), SAFE_CHUNK_SIZE)]
        
        logger.info(f"📦 Fetching {len(symbols)} symbols in {len(chunks)} chunks of {SAFE_CHUNK_SIZE}")
        
        for chunk_idx, chunk in enumerate(chunks, 1):
            logger.info(f"🎯 Processing chunk {chunk_idx}/{len(chunks)}: {chunk}")
            
            try:
                # Create Ticker object with list of symbols
                ticker = Ticker(chunk)
                
                # Get price data (returns dict with symbol as key)
                try:
                    raw_price_data: Any = ticker.price
                    logger.debug(f"📊 Price data type: {type(raw_price_data)}")
                    
                    # Check if we got an error response
                    if isinstance(raw_price_data, dict):
                        price_data = cast(Dict[str, Dict[str, Any]], raw_price_data)
                        for symbol in chunk:
                            try:
                                symbol_data: Dict[str, Any] = price_data.get(symbol, {})
                                
                                # Check for error in response
                                if not isinstance(symbol_data, dict) or 'error' in str(symbol_data).lower():
                                    logger.warning(f"⚠️  Error response for {symbol}: {symbol_data}")
                                    continue
                                
                                if not symbol_data:
                                    logger.warning(f"⚠️  No data for {symbol}")
                                    continue
                                
                                # Extract price information
                                raw_price: Any = symbol_data.get('regularMarketPrice')
                                raw_previous: Any = symbol_data.get('regularMarketPreviousClose')
                                
                                if raw_price is None or raw_previous is None:
                                    logger.warning(f"⚠️  Missing price data for {symbol}")
                                    continue
                                
                                current_price: float = float(raw_price)
                                previous_close: float = float(raw_previous)
                                
                                change = current_price - previous_close
                                change_percent = (change / previous_close * 100) if previous_close else 0
                                
                                # Get additional info
                                name_val: Any = symbol_data.get('longName') or symbol_data.get('shortName') or symbol.replace('.IS', '')
                                name: str = str(name_val) if name_val else symbol.replace('.IS', '')
                                market_cap: Any = symbol_data.get('marketCap')
                                volume_val: Any = symbol_data.get('regularMarketVolume', 0)
                                
                                stock_data: Dict[str, Any] = {
                                    "symbol": symbol,
                                    "name": name,
                                    "price": round(current_price, 2),
                                    "change": round(change, 2),
                                    "change_percent": round(change_percent, 2),
                                    "volume": int(volume_val) if volume_val else 0,
                                    "market_cap": market_cap,
                                    "timestamp": datetime.now().isoformat()
                                }
                                
                                stocks_data.append(stock_data)
                                logger.info(f"✅ {symbol}: ₺{current_price:.2f}")
                                
                            except Exception as e:
                                logger.error(f"❌ Error processing {symbol}: {e}")
                                continue
                    else:
                        logger.error(f"❌ Unexpected price data format: {type(raw_price_data).__name__}")
                        raise Exception(f"Invalid price data format: {type(raw_price_data).__name__}")
                    
                except Exception as e:
                    logger.error(f"❌ Error fetching price data: {e}")
                    raise
                
                # Aggressive throttle between chunks
                if chunk_idx < len(chunks):
                    self._aggressive_throttle()
                
            except Exception as e:
                logger.error(f"❌ Chunk {chunk_idx} failed: {e}")
                # Check if it's a rate limit or authentication error
                error_str = str(e).lower()
                if any(keyword in error_str for keyword in ['429', 'too many', 'unauthorized', 'forbidden']):
                    raise Exception(f"Rate limit or auth error: {e}")
                raise
        
        return stocks_data
    
    def fetch_stock_data_batch(self, tickers: List[str], chunk_size: int = 10) -> List[Dict[str, Any]]:
        """
        Fetch stock data with professional safety mechanisms
        
        Args:
            tickers: List of stock symbols
            chunk_size: Max symbols per batch (default: 10)
        
        Returns:
            List of stock dictionaries
        """
        # If mock mode is enabled, use mock data
        if self.use_mock_data:
            logger.warning("🎭 Using MOCK DATA - Yahoo Finance unavailable")
            return mock_service.generate_stock_data(tickers)
        
        # Try to fetch through circuit breaker
        try:
            result: Optional[List[Dict[str, Any]]] = self.circuit_breaker.call(
                self._fetch_with_circuit_breaker,
                tickers
            )
            
            if result is None:
                # Circuit is open, use mock data
                logger.warning("🎭 Circuit breaker OPEN - using mock data")
                self.use_mock_data = True
                return mock_service.generate_stock_data(tickers)
            
            return result
            
        except Exception as e:
            logger.error(f"❌ Fetch failed: {type(e).__name__}: {e}")
            logger.warning(f"🎭 Falling back to mock data due to: {type(e).__name__}")
            self.use_mock_data = True
            return mock_service.generate_stock_data(tickers)
    
    def fetch_stock_group(self, symbols: List[str], group_name: str = "stocks") -> List[Dict[str, Any]]:
        """
        Fetch a specific group of stocks
        
        Args:
            symbols: List of stock symbols
            group_name: Name for logging
        
        Returns:
            List of stock dictionaries
        """
        logger.info(f"📊 Fetching {group_name}: {len(symbols)} stocks (SAFE MODE)")
        return self.fetch_stock_data_batch(symbols, chunk_size=10)
    
    def fetch_bist100_stocks(self) -> List[Dict[str, Any]]:
        """Fetch all BIST100 stocks"""
        return self.fetch_stock_data_batch(settings.BIST100_SYMBOLS, chunk_size=10)
    
    def fetch_forex(self) -> List[Dict[str, Any]]:
        """Fetch forex data with yahooquery and fallback"""
        if self.use_mock_data:
            return mock_service.generate_forex_data()
        
        try:
            forex_data: List[Dict[str, Any]] = []
            
            # Fetch all forex pairs at once
            ticker = Ticker(settings.FOREX_SYMBOLS)
            raw_price_data: Any = ticker.price
            
            if not isinstance(raw_price_data, dict):
                raise Exception(f"Invalid price data format: {type(raw_price_data).__name__}")
            
            price_data = cast(Dict[str, Dict[str, Any]], raw_price_data)
            
            for symbol in settings.FOREX_SYMBOLS:
                try:
                    symbol_data: Dict[str, Any] = price_data.get(symbol, {})
                    
                    if not isinstance(symbol_data, dict) or 'error' in str(symbol_data).lower():
                        logger.warning(f"⚠️  Error response for {symbol}: {symbol_data}")
                        continue
                    
                    if not symbol_data:
                        logger.warning(f"⚠️  No data for {symbol}")
                        continue
                    
                    raw_rate: Any = symbol_data.get('regularMarketPrice')
                    raw_previous: Any = symbol_data.get('regularMarketPreviousClose')
                    
                    if raw_rate is None or raw_previous is None:
                        logger.warning(f"⚠️  Missing price data for {symbol}")
                        continue
                    
                    current_rate: float = float(raw_rate)
                    previous_close: float = float(raw_previous)
                    
                    change = current_rate - previous_close
                    change_percent = (change / previous_close * 100) if previous_close else 0
                    
                    pair_name = symbol.replace('=X', '').replace('TRY', '/TRY')
                    if pair_name == '/TRY':
                        pair_name = 'USD/TRY'
                    
                    forex_data.append({
                        "pair": pair_name,
                        "symbol": symbol,
                        "rate": round(current_rate, 4),
                        "change": round(change, 4),
                        "change_percent": round(change_percent, 2),
                        "timestamp": datetime.now().isoformat()
                    })
                    
                except Exception as e:
                    logger.error(f"❌ Forex {symbol}: {e}")
                    continue
            
            return forex_data if forex_data else mock_service.generate_forex_data()
            
        except Exception as e:
            logger.error(f"❌ Forex fetch failed: {type(e).__name__}: {e}")
            logger.warning(f"🎭 Falling back to mock forex data due to: {type(e).__name__}")
            return mock_service.generate_forex_data()
    
    def fetch_commodities(self) -> List[Dict[str, Any]]:
        """Fetch commodities data with yahooquery and fallback"""
        if self.use_mock_data:
            return mock_service.generate_commodities_data()
        
        try:
            commodities_data: List[Dict[str, Any]] = []
            
            commodity_names: Dict[str, str] = {
                "GC=F": "Gold Futures",
                "SI=F": "Silver Futures"
            }
            
            # Fetch all commodities at once
            ticker = Ticker(settings.COMMODITY_SYMBOLS)
            raw_price_data: Any = ticker.price
            
            if not isinstance(raw_price_data, dict):
                raise Exception(f"Invalid price data format: {type(raw_price_data).__name__}")
            
            price_data = cast(Dict[str, Dict[str, Any]], raw_price_data)
            
            for symbol in settings.COMMODITY_SYMBOLS:
                try:
                    symbol_data: Dict[str, Any] = price_data.get(symbol, {})
                    
                    if not isinstance(symbol_data, dict) or 'error' in str(symbol_data).lower():
                        logger.warning(f"⚠️  Error response for {symbol}: {symbol_data}")
                        continue
                    
                    if not symbol_data:
                        logger.warning(f"⚠️  No data for {symbol}")
                        continue
                    
                    raw_price: Any = symbol_data.get('regularMarketPrice')
                    raw_previous: Any = symbol_data.get('regularMarketPreviousClose')
                    
                    if raw_price is None or raw_previous is None:
                        logger.warning(f"⚠️  Missing price data for {symbol}")
                        continue
                    
                    current_price: float = float(raw_price)
                    previous_close: float = float(raw_previous)
                    
                    change = current_price - previous_close
                    change_percent = (change / previous_close * 100) if previous_close else 0
                    
                    commodities_data.append({
                        "symbol": symbol,
                        "name": commodity_names.get(symbol, symbol),
                        "price": round(current_price, 2),
                        "change": round(change, 2),
                        "change_percent": round(change_percent, 2),
                        "timestamp": datetime.now().isoformat()
                    })
                    
                except Exception as e:
                    logger.error(f"❌ Commodity {symbol}: {e}")
                    continue
            
            return commodities_data if commodities_data else mock_service.generate_commodities_data()
            
        except Exception as e:
            logger.error(f"❌ Commodities fetch failed: {type(e).__name__}: {e}")
            logger.warning(f"🎭 Falling back to mock commodities data due to: {type(e).__name__}")
            return mock_service.generate_commodities_data()
    
    def fetch_all_group_a(self) -> Dict[str, List[Dict[str, Any]]]:
        """Fetch all Group A data"""
        logger.info("=== 🚀 Starting Group A fetch (PROFESSIONAL MODE) ===")
        
        return {
            "stocks": self.fetch_bist100_stocks(),
            "forex": self.fetch_forex(),
            "commodities": self.fetch_commodities()
        }


# Create service instance
yahoo_service = YahooFinanceService()
