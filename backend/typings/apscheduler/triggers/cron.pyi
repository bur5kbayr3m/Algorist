"""
Type stubs for APScheduler CronTrigger
"""
from typing import Optional, Any
from datetime import datetime
from .. import BaseTrigger


class CronTrigger(BaseTrigger):
    """
    Trigger that fires on a schedule defined by cron-like expressions.
    
    Args:
        year: 4-digit year
        month: Month (1-12)
        day: Day of month (1-31)
        week: ISO week (1-53)
        day_of_week: Number or name of weekday (0-6 or mon,tue,wed,thu,fri,sat,sun)
        hour: Hour (0-23)
        minute: Minute (0-59)
        second: Second (0-59)
        start_date: Earliest possible date/time to trigger on
        end_date: Latest possible date/time to trigger on
        timezone: Timezone to use
    """
    
    def __init__(
        self,
        year: Optional[int | str] = None,
        month: Optional[int | str] = None,
        day: Optional[int | str] = None,
        week: Optional[int | str] = None,
        day_of_week: Optional[int | str] = None,
        hour: Optional[int | str] = None,
        minute: Optional[int | str] = None,
        second: Optional[int | str] = None,
        start_date: Optional[datetime | str] = None,
        end_date: Optional[datetime | str] = None,
        timezone: Optional[str] = None,
        jitter: Optional[int] = None,
    ) -> None: ...
