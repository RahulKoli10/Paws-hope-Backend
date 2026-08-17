from pydantic import BaseModel, EmailStr, Field
from app.models.user import UserRole


# Register
class UserCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=6)
    role: UserRole

# Login
class UserLogin(BaseModel):
    email: EmailStr
    password: str
    device_name: str = Field(..., min_length=2, max_length=255)

# Refresh Token
class RefreshTokenRequest(BaseModel):
    refresh_token: str


# Logout
class LogoutRequest(BaseModel):
    refresh_token: str


# Forgot Password
class ForgotPasswordRequest(BaseModel):
    email: EmailStr


# Verify OTP
class VerifyOTPRequest(BaseModel):
    email: EmailStr
    otp: str


# Reset Password
class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp: str
    new_password: str = Field(..., min_length=6)


# Change Password
class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=6)

class ReplaceSessionRequest(BaseModel):
    session_id: str

class SendVerificationOTPRequest(BaseModel):
    email: EmailStr

class VerifyEmailOTPRequest(BaseModel):
    email: EmailStr
    otp: str