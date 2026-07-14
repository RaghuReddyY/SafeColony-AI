from app.database.base_class import Base

# Import every model so Alembic can discover them

from app.models.user import User
from app.models.organization import Organization
from app.models.property import Property
from app.models.section import Section
from app.models.unit import Unit
from app.models.resident import Resident
from app.models.vehicle import Vehicle
from app.models.visitor import Visitor
from app.models.notification import Notification