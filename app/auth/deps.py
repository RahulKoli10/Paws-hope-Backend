from fastapi import Depends, HTTPException, status
from jose import jwt 
from sqlalchemy.orm import Session
from fastapi.security import HTTPBearer , HTTPAuthorizationCredentials
import os
from dotenv import load_dotenv
from app.db.database import get_db
from app.models.user import User

load_dotenv()
JWT_SECRET= os.getenv("SECRET_KEY")
ALGORITHM = "HS256"
security = HTTPBearer()

def get_current_user(
    creadentails : HTTPAuthorizationCredentials = Depends(security),
    db: Session= Depends(get_db)):
    token = creadentails.credentials

    try:
        payload = jwt.decode(
            token,
            JWT_SECRET,
            algorithms=[ALGORITHM]
        )

        user_id = payload.get("user_id")
        token_type = payload.get("token_type")

        if token_type != "access":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid access token"
            )

    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )

    user = (
        db.query(User)
        .filter(User.id == user_id)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    if user.status != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive"
        )

    return user


def admin_only(
    current_user: User = Depends(get_current_user)
):
    if current_user.role.value != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin only"
        )

    return current_user