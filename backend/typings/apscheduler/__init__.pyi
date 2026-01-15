"""
Type stubs for APScheduler library
Professional stub file for static type checking
"""
from typing import Any, Callable, Optional, List


class Job:
    """Represents a scheduled job"""
    id: str
    name: str
    next_run_time: Optional[Any]
    
    def __init__(self) -> None: ...


class BaseScheduler:
    """Base scheduler class"""
    running: bool
    
    def __init__(self, **kwargs: Any) -> None: ...
    def start(self, paused: bool = False) -> None: ...
    def shutdown(self, wait: bool = True) -> None: ...
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
    ) -> Job: ...
    def get_jobs(self, jobstore: Optional[str] = None, pending: Optional[bool] = None) -> List[Job]: ...
    def remove_job(self, job_id: str, jobstore: Optional[str] = None) -> None: ...
    def pause_job(self, job_id: str, jobstore: Optional[str] = None) -> Job: ...
    def resume_job(self, job_id: str, jobstore: Optional[str] = None) -> Job: ...


class BaseTrigger:
    """Base trigger class"""
    def __init__(self, **kwargs: Any) -> None: ...
