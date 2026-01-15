"""
Type stubs for yahooquery library
Professional stub file for static type checking
"""
from typing import Dict, List, Any, Optional, Union
from datetime import datetime


class Ticker:
    """
    YahooQuery Ticker class for fetching financial data
    
    Args:
        symbols: Single symbol string or list of symbols
        asynchronous: Whether to use async requests
        progress: Show progress bar
        formatted: Return formatted data
        validate: Validate symbols
    """
    
    def __init__(
        self,
        symbols: Union[str, List[str]],
        asynchronous: bool = False,
        progress: bool = False,
        formatted: bool = False,
        validate: bool = False,
    ) -> None: ...
    
    @property
    def price(self) -> Dict[str, Dict[str, Any]]:
        """
        Get price data for symbols
        
        Returns:
            Dict mapping symbol to price data containing:
            - regularMarketPrice: float
            - regularMarketPreviousClose: float
            - regularMarketChange: float
            - regularMarketChangePercent: float
            - marketCap: int
            - regularMarketVolume: int
            - longName: str
            - shortName: str
        """
        ...
    
    @property
    def summary_detail(self) -> Dict[str, Dict[str, Any]]:
        """Get summary details for symbols"""
        ...
    
    @property
    def summary_profile(self) -> Dict[str, Dict[str, Any]]:
        """Get company profile for symbols"""
        ...
    
    @property
    def financial_data(self) -> Dict[str, Dict[str, Any]]:
        """Get financial data for symbols"""
        ...
    
    @property
    def key_stats(self) -> Dict[str, Dict[str, Any]]:
        """Get key statistics for symbols"""
        ...
    
    def history(
        self,
        period: str = "1mo",
        interval: str = "1d",
        start: Optional[datetime] = None,
        end: Optional[datetime] = None,
    ) -> Any:
        """Get historical price data"""
        ...
