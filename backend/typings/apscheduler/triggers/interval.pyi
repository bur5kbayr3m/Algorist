"""
Type stubs for APScheduler IntervalTrigger
"""
from typing import Optional, Any
from datetime import datetime, timedelta
from .. import BaseTrigger


class IntervalTrigger(BaseTrigger):
    """
    Trigger that fires at regular intervals.
    
    Args:
        weeks: Number of weeks to wait
        days: Number of days to wait
        hours: Number of hours to wait
        minutes: Number of minutes to wait
        seconds: Number of seconds to wait
        start_date: Starting point for the interval calculation
        end_date: Latest possible date/time to trigger on
        timezone: Timezone to use
        jitter: Maximum random delay in seconds to add to each run
    """
    
    def __init__(
        self,
        weeks: int = 0,
        days: int = 0,
        hours: int = 0,
        minutes: int = 0,
        seconds: int = 0,
        start_date: Optional[datetime | str] = None,
        end_date: Optional[datetime | str] = None,
        timezone: Optional[str] = None,
        jitter: Optional[int] = None,
    ) -> None: ...
