from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta

from app.db.database import get_db
from app.models.user import User

from app.models.refresh_token import RefreshToken
from app.auth.jwt import decode_token

from app.schemas.user_schema import UserCreate, UserLogin , RefreshTokenRequest , LogoutRequest, ForgotPasswordRequest, VerifyOTPRequest,ResetPasswordRequest,ChangePasswordRequest,SendVerificationOTPRequest,VerifyEmailOTPRequest

from app.auth.hash import hash_password, verify_password
from app.auth.jwt import create_access_token, create_refresh_token
from app.auth.deps import get_current_user
from app.models.password_reset_otp import PasswordResetOTP
from app.utils.otp import generate_otp
from app.models.email_verification_otp import EmailVerificationOTP

router = APIRouter(
    prefix="/auth/v1",
    tags=["Authentication"]
)

@router.post("/register")
def register(user: UserCreate, db:Session= Depends(get_db)):
    existing_user = db.query(User).filter(User.email==user.email).first()

    if existing_user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already exists, Use another")

    new_user = User(
        name=user.name,
        email=user.email,
        password_hash=hash_password(user.password),
        role=user.role
    )    

    db.add(new_user)
    db.commit()
    db.refresh(new_user)


    access_token = create_access_token({
    "user_id": str(new_user.id),
    "role": new_user.role.value
    })

    refresh_token = create_refresh_token(
        {
            "user_id": str(new_user.id),
            "role": new_user.role.value
        }
    )
    refresh_token_record = RefreshToken(
        user_id=new_user.id,
        token=refresh_token,
        expires_at=datetime.utcnow() + timedelta(days=7)
    )

    db.add(refresh_token_record)
    db.commit()
    return {
        "message": "User registered successfully",
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {
            "id": str(new_user.id),
            "name": new_user.name,
            "email": new_user.email,
            "role": new_user.role.value,
            "is_verified": new_user.is_verified
        }
    }

# login route
@router.post("/login")
def login(
    user: UserLogin,
    db: Session = Depends(get_db)
):
    db_user = (
        db.query(User)
        .filter(User.email == user.email)
        .first()
    )

    if not db_user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    if db_user.status != "active":
         raise HTTPException(
        status_code=403,
        detail="Please verify your email first"
    )

    if not verify_password(
        user.password,
        db_user.password_hash
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid credentials"
        )

    # Device Limit Check
    MAX_DEVICES = 3

    active_sessions = (
        db.query(RefreshToken)
        .filter(
            RefreshToken.user_id == db_user.id
        )
        .all()
    )

    if len(active_sessions) >= MAX_DEVICES:
        return {
            "success": False,
            "error": "DEVICE_LIMIT_REACHED",
            "message": "Maximum 3 devices allowed",
            "sessions": [
                {
                    "session_id": str(session.id),
                    "device_name": session.device_name,
                    "created_at": session.created_at,
                    "expires_at": session.expires_at
                }
                for session in active_sessions
            ]
        }

    # Create Tokens
    access_token = create_access_token({
        "user_id": str(db_user.id),
        "role": db_user.role.value
    })

    refresh_token = create_refresh_token({
        "user_id": str(db_user.id),
        "role": db_user.role.value
    })

    # Save Session
    refresh_token_record = RefreshToken(
        user_id=db_user.id,
        token=refresh_token,
        device_name=user.device_name,
        expires_at=datetime.utcnow() + timedelta(days=7)
    )

    db.add(refresh_token_record)

    # Update Last Login
    db_user.last_login = datetime.utcnow()

    db.commit()

    return {
        "success": True,
        "message": "Login successful",
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {
            "id": str(db_user.id),
            "name": db_user.name,
            "email": db_user.email,
            "role": db_user.role.value,
            "is_verified": db_user.is_verified
        }
    }


@router.get("/me")
def get_me(
    current_user: User = Depends(get_current_user)
):

    return {
        "id": str(current_user.id),
        "name": current_user.name,
        "email": current_user.email,
        "role": current_user.role.value,
        "phone": current_user.phone,
        "status": current_user.status,
        "is_verified": current_user.is_verified,
        "created_at": current_user.created_at,
        "last_login": current_user.last_login
    }


@router.post("/refresh-token")
def refresh_token(
    request: RefreshTokenRequest,
    db: Session = Depends(get_db)
):
    payload = decode_token(
        request.refresh_token
    )

    if not payload:
        raise HTTPException(
            status_code=401,
            detail="Invalid refresh token"
        )

    if payload.get("token_type") != "refresh":
        raise HTTPException(
            status_code=401,
            detail="Invalid token type"
        )

    db_token = (
        db.query(RefreshToken)
        .filter(
            RefreshToken.token ==
            request.refresh_token
        )
        .first()
    )

    if not db_token:
        raise HTTPException(
            status_code=404,
            detail="Session not found"
        )

    access_token = create_access_token({
        "user_id": payload["user_id"],
        "role": payload["role"]
    })

    return {
        "access_token": access_token,
        "token_type": "bearer"
    }


@router.post("/logout")
def logout(request:LogoutRequest , db: Session=Depends(get_db)):
    db_token =(
        db.query(RefreshToken).filter(RefreshToken.token == request.refresh_token).first())

    if not db_token:
        raise HTTPException(
            status_code=404,
            detail="Session not found"
        )
    
    db.delete(db_token)
    db.commit()

    return{
        "message": "logout successfully"
    }


@router.post("/logout-all")
def logout_all(current_user:User = Depends(get_current_user), db: Session = Depends(get_db)):
    deleted_count = (
    db.query(RefreshToken)
    .filter(
        RefreshToken.user_id == current_user.id
    )
    .delete()
)
    db.commit()

    return {
    "message": "Logged out from all devices",
    "sessions_removed": deleted_count
    }


@router.get("/sessions")
def get_sessions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    sessions = (
        db.query(RefreshToken)
        .filter(
            RefreshToken.user_id == current_user.id
        )
        .all()
    )

    return {
        "count": len(sessions),
        "sessions": [
           {
                "id": str(session.id),
                "device_name": session.device_name,
                "created_at": session.created_at,
                "expires_at": session.expires_at
            }
            for session in sessions
        ]
    }


@router.delete("/sessions/{session_id}")
def delete_session(
    session_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    session = (
        db.query(RefreshToken)
        .filter(
            RefreshToken.user_id == current_user.id,
            RefreshToken.id == session_id
        )
        .first()
    )

    if not session:
        raise HTTPException(
            status_code=404,
            detail = "Session not found"
        )
    db.delete(session)
    db.commit()
    return{
        "message": "Session removed Successfully"
    }


@router.post("/forgot-password")
def forgot_password(
    request: ForgotPasswordRequest,
    db: Session = Depends(get_db)
):
    user = (
        db.query(User)
        .filter(User.email == request.email)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    otp = generate_otp()

    db.query(PasswordResetOTP).filter(
        PasswordResetOTP.email == request.email
    ).delete()

    otp_record = PasswordResetOTP(
        email=request.email,
        otp=otp,
        expires_at=datetime.utcnow() + timedelta(minutes=10)
    )

    db.add(otp_record)
    db.commit()

    print(
        f"Password Reset OTP for {request.email}: {otp}"
    )

    return {
        "message": "OTP sent successfully"
    }


@router.post("/verify-otp")
def verify_otp(
    request: VerifyOTPRequest,
    db: Session = Depends(get_db)
):
    otp_record = (
        db.query(PasswordResetOTP)
        .filter(
            PasswordResetOTP.email == request.email,
            PasswordResetOTP.otp == request.otp
        )
        .first()
    )

    if not otp_record:
        raise HTTPException(
            status_code=400,
            detail="Invalid OTP"
        )

    if otp_record.expires_at < datetime.utcnow():
        raise HTTPException(
            status_code=400,
            detail="OTP expired"
        )

    otp_record.is_verified = True

    db.commit()

    return {
        "message": "OTP verified successfully"
    }

@router.post("/reset-password")
def reset_password(
    request: ResetPasswordRequest,
    db: Session = Depends(get_db)
):
    otp_record = (
        db.query(PasswordResetOTP)
        .filter(
            PasswordResetOTP.email == request.email,
            PasswordResetOTP.otp == request.otp,
            PasswordResetOTP.is_verified == True
        )
        .first()
    )

    if not otp_record:
        raise HTTPException(
            status_code=400,
            detail="OTP verification required"
        )

    user = (
        db.query(User)
        .filter(User.email == request.email)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    user.password_hash = hash_password(
        request.new_password
    )

    db.delete(otp_record)

    db.commit()

    return {
        "message": "Password reset successful"
    }

@router.put("/change-password")
def change_password(
    request: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not verify_password(
        request.current_password,
        current_user.password_hash
    ):
        raise HTTPException(
            status_code=400,
            detail="Current password is incorrect"
        )

    current_user.password_hash = hash_password(
        request.new_password
    )

    db.commit()

    return {
        "message": "Password changed successfully"
    }

@router.post("/send-verification-otp")
def send_verification_otp(
    request: SendVerificationOTPRequest,
    db: Session = Depends(get_db)
):
    user = (
        db.query(User)
        .filter(User.email == request.email)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    if user.is_verified:
        raise HTTPException(
            status_code=400,
            detail="Email already verified"
        )

    otp = generate_otp()

    db.query(EmailVerificationOTP).filter(
        EmailVerificationOTP.email == request.email
    ).delete()

    otp_record = EmailVerificationOTP(
        email=request.email,
        otp=otp,
        expires_at=datetime.utcnow() + timedelta(minutes=10)
    )

    db.add(otp_record)
    db.commit()

    print(
        f"Email Verification OTP for {request.email}: {otp}"
    )

    return {
        "message": "Verification OTP sent"
    }

@router.post("/verify-email")
def verify_email(
    request: VerifyEmailOTPRequest,
    db: Session = Depends(get_db)
):
    otp_record = (
        db.query(EmailVerificationOTP)
        .filter(
            EmailVerificationOTP.email == request.email,
            EmailVerificationOTP.otp == request.otp
        )
        .first()
    )

    if not otp_record:
        raise HTTPException(
            status_code=400,
            detail="Invalid OTP"
        )

    if otp_record.expires_at < datetime.utcnow():
        raise HTTPException(
            status_code=400,
            detail="OTP expired"
        )

    user = (
        db.query(User)
        .filter(User.email == request.email)
        .first()
    )

    user.is_verified = True

    db.delete(otp_record)

    db.commit()

    return {
        "message": "Email verified successfully"
    }