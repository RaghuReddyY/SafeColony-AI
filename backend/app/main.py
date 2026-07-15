from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.auth import router as auth_router
from app.api.organization import router as organization_router
from app.api.property import router as property_router
from app.api.section import router as section_router
from app.api.unit import router as unit_router
from app.api.resident import router as resident_router
from app.api.vehicle import router as vehicle_router
from app.api.visitor import router as visitor_router
from app.api.guard import router as guard_router
from app.api.notification import router as notification_router
from app.api.vacation_mode import router as vacation_router
from app.api.security_alert import router as security_alert_router
from app.api.security_dashboard import (
    router as security_dashboard_router,
)
from app.api.delivery import router as delivery_router

from app.core.event_registry import register_event_handlers
from app.core.exceptions import global_exception_handler
from app.api.dashboard import router as dashboard_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Runs once when the application starts.
    Registers all event handlers.
    """

    register_event_handlers()

    yield

    # Future:
    # Cleanup resources here if needed


app = FastAPI(
    title="SafeColony AI",
    version="1.0.0",
    lifespan=lifespan,
)

# -----------------------------
# CORS
# -----------------------------
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

# -----------------------------
# Register Routers
# -----------------------------
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


# -----------------------------
# Home
# -----------------------------
@app.get("/")
def home():
    return {
        "message": "SafeColony AI Running",
        "version": "1.0.0",
    }


# -----------------------------
# Global Exception Handler
# -----------------------------
app.add_exception_handler(
    Exception,
    global_exception_handler,
)