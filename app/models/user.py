from sqlalchemy import Column, String, Boolean, Enum 
from sqlalchemy.dialects.postgresql import UUID
import uuid
import enum
from app.db.database import Base

class UserRole(str, enum.Enum):
    admin = "admin"
    volunteer = "volunteer"

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    name = Column(String(100), nullable=False)
    email = Column(String, unique=True, nullable=False)
    password_hash = Column(String, nullable=False)

    role = Column(Enum(UserRole), nullable=False)

    phone = Column(String(13))
    status = Column(String(20), default="active")
    
    is_verified = Column(Boolean, default=False)