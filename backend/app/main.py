from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.trustedhost import TrustedHostMiddleware
from fastapi.routing import APIRoute
from fastapi.staticfiles import StaticFiles

# Routers
from app.api.auth import router as auth_router
from app.api.ai_assistant import router as ai_assistant_router
from app.api.chat import router as chat_router
from app.api.dashboard import router as dashboard_router
from app.api.delivery import router as delivery_router
from app.api.guard import router as guard_router
from app.api.guard_dashboard import router as guard_dashboard_router
from app.api.notification import router as notification_router
from app.api.organization import router as organization_router
from app.api.property import router as property_router
from app.api.resident import router as resident_router
from app.api.section import router as section_router
from app.api.security_alert import router as security_alert_router
from app.api.security_dashboard import router as security_dashboard_router
from app.api.unit import router as unit_router
from app.api.vacation_mode import router as vacation_router
from app.api.vehicle import router as vehicle_router
from app.api.visitor import router as visitor_router
from app.api.join import router as join_router
from app.api.maintenance import router as maintenance_router
from app.api.community_finance import router as community_finance_router
from app.api.setup import router as setup_router
from app.api.public import router as public_router
from app.api.incident import router as incident_router
from app.api.complaint import router as complaint_router
from app.api.amenity import router as amenity_router
from app.api.internal_scheduler import router as internal_scheduler_router


# Core
from app.core.event_registry import register_event_handlers
from app.core.exceptions import register_exception_handlers
from app.core.logger import logger
from app.config import settings

# Scheduler
from app.scheduler.bootstrap import create_scheduler


def custom_generate_unique_id(route: APIRoute) -> str:
    tag = route.tags[0] if route.tags else "default"
    method = sorted(route.methods)[0].lower()
    return f"{tag}_{route.name}_{method}"


@asynccontextmanager
async def lifespan(app: FastAPI):

    settings.validate_for_startup()

    logger.info("==========================================")
    logger.info("Starting SafeColony AI...")
    logger.info("Registering event handlers...")

    register_event_handlers()

    logger.info("Event handlers registered successfully.")

    scheduler = None
    if settings.RUN_IN_PROCESS_SCHEDULER:
        scheduler = create_scheduler()
        scheduler.start()
        logger.info("In-process scheduler started successfully.")
    else:
        logger.info("In-process scheduler disabled; use Cloud Scheduler/Cloud Run Jobs.")

    logger.info("SafeColony AI started successfully.")
    logger.info("==========================================")

    yield

    logger.info("==========================================")
    logger.info("Stopping Scheduler...")

    if scheduler is not None:
        scheduler.shutdown()

    logger.info("Stopping SafeColony AI...")
    logger.info("SafeColony AI stopped.")
    logger.info("==========================================")


app = FastAPI(
    title="SafeColony AI",
    version="1.0.0",
    lifespan=lifespan,
    generate_unique_id_function=custom_generate_unique_id,
)

# Reject unexpected Host headers in production. Development keeps the
# permissive setting so local/emulator/physical-device workflows continue to work.
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=settings.allowed_hosts,
)

# Global Exception Handlers
register_exception_handlers(app)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_origin_regex=r"http://localhost:\d+" if not settings.is_production else None,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(setup_router)
app.include_router(auth_router)
app.include_router(ai_assistant_router)
app.include_router(chat_router)
app.include_router(organization_router)
app.include_router(property_router)
app.include_router(section_router)
app.include_router(unit_router)
app.include_router(resident_router)
app.include_router(vehicle_router)
app.include_router(visitor_router)
app.include_router(guard_router)
app.include_router(notification_router)
app.include_router(vacation_router)
app.include_router(security_alert_router)
app.include_router(security_dashboard_router)
app.include_router(delivery_router)
app.include_router(dashboard_router)
app.include_router(guard_dashboard_router)
app.include_router(join_router)
app.include_router(maintenance_router)
app.include_router(community_finance_router)
app.include_router(public_router)
app.include_router(incident_router)
app.include_router(complaint_router)
app.include_router(amenity_router)
app.include_router(internal_scheduler_router)



# Local file serving is retained for development. Production GCS objects are
# accessed through StorageService/signed URLs instead.
if settings.STORAGE_BACKEND.strip().upper() != "GCS":
    from pathlib import Path

    Path("uploads/qr").mkdir(parents=True, exist_ok=True)
    Path("uploads/incidents").mkdir(parents=True, exist_ok=True)

    app.mount(
        "/uploads/qr",
        StaticFiles(directory="uploads/qr"),
        name="visitor_qr",
    )

    app.mount(
        "/uploads/incidents",
        StaticFiles(directory="uploads/incidents"),
        name="incident_uploads",
    )


@app.get("/health", tags=["System"], include_in_schema=False)
def health():
    return {
        "status": "ok",
        "service": "SafeColony AI",
        "version": "1.0.0",
    }


@app.get("/", tags=["System"])
def home():
    logger.info("Health endpoint accessed.")

    return {
        "success": True,
        "message": "SafeColony AI Running",
        "version": "1.0.0",
    }