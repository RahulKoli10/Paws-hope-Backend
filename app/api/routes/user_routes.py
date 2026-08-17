from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session 
from app.db.database import get_db
from app.models.user import User
from app.auth.deps import get_current_user

router = APIRouter()

@router.get("/users")
def get_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    return users

@router.get("/me")
def get_me(user = Depends(get_current_user)):
    return {
        "id": str(user.id),
        "name": user.name,
        "email": user.email,
        "role": user.role
    }