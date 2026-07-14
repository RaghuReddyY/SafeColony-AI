from fastapi import FastAPI

from app.api.auth import router as auth_router
from app.api.organization import router as organization_router
from app.api.property import router as property_router
from app.api.section import router as section_router
from app.api.unit import router as unit_router


app = FastAPI(
    title="SafeColony AI",
    version="1.0.0",
)

app.include_router(auth_router)
app.include_router(property_router)
app.include_router(organization_router)
app.include_router(section_router)
app.include_router(unit_router)

@app.get("/")
def home():
    return {"message": "SafeColony AI Running"}