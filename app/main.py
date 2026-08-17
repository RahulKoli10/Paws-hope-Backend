import logging
from fastapi import FastAPI
from app.db.database import Base, engine
from app.models.user import User
from app.api.routes.auth_routes import router as auth_router
from app.api.routes.test_db import router as test_router
from app.api.routes.user_routes import router as user_router
from app.api.routes.volunteer_routes import router as volunteer_router
from app.models.password_reset_otp import PasswordResetOTP
from app.models.email_verification_otp import EmailVerificationOTP

app = FastAPI()

logger = logging.getLogger(__name__)


@app.on_event("startup")
def create_tables():
    try:
        Base.metadata.create_all(bind=engine)
    except Exception as exc:
        logger.warning("Database initialization skipped: %s", exc)

app.include_router(auth_router)
app.include_router(volunteer_router, prefix="/volunteer")
app.include_router(test_router)
app.include_router(user_router)


@app.get("/")
def root():
    return {"message": "NGO backend is running"}


@app.get("/health")
def health():
    return {"status": "ok"}
