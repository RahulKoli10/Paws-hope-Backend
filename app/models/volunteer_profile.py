from sqlalchemy import Column, String, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
import uuid

from app.db.database import Base


class VolunteerProfile(Base):
    __tablename__ = "volunteer_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))

    address = Column(String(100))
    government_id_proof_url = Column(String)

    approved_by = Column(UUID(as_uuid=True))