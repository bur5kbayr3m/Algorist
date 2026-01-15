"""
Type stubs for tefas-crawler library
Professional stub file for static type checking
"""
from typing import Optional, List, Dict, Any, Union
from datetime import date, datetime
import pandas as pd


class Crawler:
    """
    TEFAS (Turkish Electronic Fund Trading Platform) data crawler
    
    Fetches fund data from the TEFAS platform.
    """
    
    def __init__(self) -> None:
        """Initialize the TEFAS crawler"""
        ...
    
    def fetch(
        self,
        date: Optional[Union[str, datetime, date]] = None,
        start: Optional[date] = None,
        end: Optional[date] = None,
        columns: Optional[List[str]] = None,
        name: Optional[str] = None,
    ) -> pd.DataFrame:
        """
        Fetch fund data from TEFAS
        
        Args:
            date: Single date for data retrieval (legacy parameter)
            start: Start date for data retrieval
            end: End date (defaults to today)
            columns: List of fund codes to fetch
            name: Single fund name to fetch
            
        Returns:
            DataFrame with fund prices indexed by date
        """
        ...
