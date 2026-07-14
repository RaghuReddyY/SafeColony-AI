from fastapi import FastAPI

from app.api.auth import router as auth_router
from app.api.organization import router as organization_router
from app.api.property import router as property_router
from app.api.section import router as section_router
from app.api.unit import router as unit_router
from app.api.resident import router as resident_router
from app.api.vehicle import router as vehicle_router
from app.api.visitor import router as visitor_router
from app.core.exceptions import global_exception_handler
from app.api.guard import router as guard_router
from app.api.notification import router as notification_router


app = FastAPI(
    title="SafeColony AI",
    version="1.0.0",
)

app.include_router(auth_router)
app.include_router(property_router)
app.include_router(organization_router)
app.include_router(section_router)
app.include_router(unit_router)
app.include_router(resident_router)
app.include_router(vehicle_router)
app.include_router(visitor_router)
app.include_router(guard_router)
app.include_router(notification_router)


@app.get("/")
def home():
    return {"message": "SafeColony AI Running"}

app.add_exception_handler(
    Exception,
    global_exception_handler
)