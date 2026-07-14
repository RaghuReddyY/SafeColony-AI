from app.database.base_class import Base

# Import every model so Alembic can discover them

from app.models.user import User
from app.models.organization import Organization
from app.models.property import Property
from app.models.section import Section