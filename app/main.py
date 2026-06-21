# uvicorn app.main:app --reload
from fastapi import FastAPI
from app.db.database import Base, engine
from app.models.user import User
from app.api.routes.auth_routes import router as auth_router
from app.api.routes.test_db import router as test_router
from app.api.routes.user_routes import router as user_router
from app.api.routes.auth_routes import router as auth_router
from app.api.routes.volunteer_routes import router as volunteer_router
from app.models.password_reset_otp import PasswordResetOTP
from app.models.email_verification_otp import EmailVerificationOTP

Base.metadata.create_all(bind=engine)
app = FastAPI()
app.include_router(auth_router, prefix="/auth")
app.include_router(volunteer_router, prefix="/volunteer")
# test api for db
app.include_router(test_router)
#users router 
app.include_router(user_router)
@app.get('/')
def root():
    return {"message": "NGO bakend is Runnin"}

app.include_router(auth_router, prefix="/auth")