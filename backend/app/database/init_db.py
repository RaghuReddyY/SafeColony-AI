from app.database.base import Base
from app.database.session import engine

# -----------------------------
# Import ALL models
# -----------------------------

from app.models.user import User
from app.models.organization import Organization
from app.models.property import Property
from app.models.section import Section
from app.models.unit import Unit
from app.models.resident import Resident
from app.models.visitor import Visitor
from app.models.delivery import Delivery
from app.models.notification import Notification
from app.models.security_alert import SecurityAlert
from app.models.vacation_mode import VacationMode

# -----------------------------

Base.metadata.create_all(bind=engine)

print("Database Created Successfully")