from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.routing import APIRoute
from fastapi.staticfiles import StaticFiles

# Routers
from app.api.auth import router as auth_router
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
from app.api.setup import router as setup_router


# Core
from app.core.event_registry import register_event_handlers
from app.core.exceptions import register_exception_handlers
from app.core.logger import logger

# Scheduler
from app.scheduler.bootstrap import create_scheduler


def custom_generate_unique_id(route: APIRoute) -> str:
    tag = route.tags[0] if route.tags else "default"
    method = sorted(route.methods)[0].lower()
    return f"{tag}_{route.name}_{method}"


@asynccontextmanager
async def lifespan(app: FastAPI):

    logger.info("==========================================")
    logger.info("Starting SafeColony AI...")
    logger.info("Registering event handlers...")

    register_event_handlers()

    logger.info("Event handlers registered successfully.")

    scheduler = create_scheduler()
    scheduler.start()

    logger.info("Scheduler started successfully.")
    logger.info("SafeColony AI started successfully.")
    logger.info("==========================================")

    yield

    logger.info("==========================================")
    logger.info("Stopping Scheduler...")

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

# Global Exception Handlers
register_exception_handlers(app)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost",
        "http://127.0.0.1:8000",
        "http://127.0.0.1",
    ],
    allow_origin_regex=r"http://localhost:\d+",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(setup_router)
app.include_router(auth_router)
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


# Static Files
app.mount(
    "/uploads/qr",
    StaticFiles(directory="uploads/qr"),
    name="visitor_qr",
)


@app.get("/", tags=["System"])
def home():
    logger.info("Health endpoint accessed.")

    return {
        "success": True,
        "message": "SafeColony AI Running",
        "version": "1.0.0",
    }