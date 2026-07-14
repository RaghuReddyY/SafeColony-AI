from app.database.base import Base

# Import every model here
from app.models.user import User
from app.models.property import Property

from app.database.session import engine
Base.metadata.create_all(bind=engine)

print("Database Created Successfully")