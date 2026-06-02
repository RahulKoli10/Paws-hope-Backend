from fastapi import Depends, HTTPException
from jose import jwt 
from sqlalchemy.orm import Session
from fastapi.security import HTTPBearer , HTTPAuthorizationCredentials
import os
from dotenv import load_dotenv
from app.db.database import get_db
from app.models.user import User

JWT_SECRET= os.getenv("SECRET_KEY")
ALGORITHM = "HS256"
security = HTTPBearer()

def get_current_user(
    creadentails : HTTPAuthorizationCredentials = Depends(security),
    db: Session= Depends(get_db)):
    token = creadentails.credentials

    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
        user_id = payload.get("user_id")
    except:
          raise HTTPException(status_code=401, detail="Invalid token")

    user = db.query(User).filter(User.id ==user_id).first()

    if not user:
         raise HTTPException(status_code=404, detail="user not found")
    
    return user

def admin_only(current_user = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin only")

    return current_user