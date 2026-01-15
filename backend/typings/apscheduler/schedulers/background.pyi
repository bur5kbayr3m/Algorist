"""
Type stubs for APScheduler BackgroundScheduler
"""
from typing import Any, Callable, Optional, List
from .. import BaseScheduler, Job


class BackgroundScheduler(BaseScheduler):
    """
    A scheduler that runs in a background thread.
    
    Args:
        timezone: Timezone for job scheduling
        job_defaults: Default settings for jobs
        executors: Custom executor configurations
        jobstores: Custom job store configurations
    """
    running: bool
    
    def __init__(
        self,
        gconfig: Optional[dict[str, Any]] = None,
        timezone: Optional[str] = None,
        job_defaults: Optional[dict[str, Any]] = None,
        executors: Optional[dict[str, Any]] = None,
        jobstores: Optional[dict[str, Any]] = None,
        **options: Any,
    ) -> None: ...
    
    def start(self, paused: bool = False) -> None:
        """Start the scheduler in a background thread"""
        ...
    
    def shutdown(self, wait: bool = True) -> None:
        """Gracefully shutdown the scheduler"""
        ...
    
    def add_job(
        self,
        func: Callable[..., Any],
        trigger: Optional[Any] = None,
        args: Optional[tuple[Any, ...]] = None,
        kwargs: Optional[dict[str, Any]] = None,
        id: Optional[str] = None,
        name: Optional[str] = None,
        misfire_grace_time: Optional[int] = None,
        coalesce: bool = True,
        max_instances: int = 1,
        next_run_time: Optional[Any] = None,
        jobstore: str = "default",
        executor: str = "default",
        replace_existing: bool = False,
        **trigger_args: Any,
    ) -> Job:
        """Add a job to the scheduler"""
        ...
    
    def get_jobs(
        self,
        jobstore: Optional[str] = None,
        pending: Optional[bool] = None
    ) -> List[Job]:
        """Get list of scheduled jobs"""
        ...
