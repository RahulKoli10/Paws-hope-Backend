from sqlalchemy import Column, String, Text
from sqlalchemy.dialects.postgresql import UUID
import uuid
from app.db.database import Base

class VolunteerRequest(Base):
    __tablename__ = "volunteer_requestes"

    id = Column(UUID(as_uuid= True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    email = Column(String, nullable=False)
    phone = Column(String(13))
    address = Column(String(100))

    government_id_proof_url = Column(Text, nullable=False)
    message = Column(Text)