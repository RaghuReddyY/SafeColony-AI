from hmac import compare_digest

from fastapi import APIRouter, Header, HTTPException

from app.config import settings
from app.scheduler.bootstrap import create_scheduler

router = APIRouter(prefix="/internal/scheduler", tags=["Internal Scheduler"])

# Job names are deliberately fixed; arbitrary callables cannot be selected via HTTP.
def _job_for_name(name: str):
    scheduler = create_scheduler()
    jobs = {job.name(): job for job in scheduler.registry.get_jobs()}
    names = {
        "vacation": "Vacation Job",
        "maintenance": "Maintenance Reminder Job",
        "notification": "Notification Outbox Job",
    }
    job = jobs.get(names.get(name, ""))
    if job is None:
        raise HTTPException(status_code=404, detail="Scheduled job not found.")
    return job


def _run_job(name: str, secret: str | None):
    if not settings.SCHEDULER_SECRET:
        raise HTTPException(status_code=503, detail="Scheduler endpoint is not configured.")

    if not secret or not compare_digest(secret, settings.SCHEDULER_SECRET):
        raise HTTPException(status_code=401, detail="Unauthorized.")

    job = _job_for_name(name)
    job.run()
    return {"status": "ok", "job": job.name()}


@router.post("/{name}")
def run_scheduled_job(name: str, x_safecolony_scheduler_secret: str | None = Header(default=None)):
    return _run_job(name, x_safecolony_scheduler_secret)
