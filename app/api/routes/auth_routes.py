from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.schemas.user_schema import UserCreate, UserLogin
from app.auth.hash import hash_password, verify_password
from app.auth.jwt import create_access_token 
from app.auth.deps import get_current_user

router = APIRouter()

@router.post("/register")
def register(user: UserCreate, db:Session= Depends(get_db)):
    existing = db.query(User).filter(User.email==user.email).first()

    if existing:
        raise HTTPException(status_code=400 ,detail="Email exists, Use another")

    new_user = User(
        name= user.name,
        email= user.email,
        password_hash=hash_password(user.password),
        role=user.role
    )    
    db.add(new_user)
    db.commit()
    return {"message":"new User created"}

@router.post("/login")
def login(user:UserLogin, db:Session=Depends(get_db)):
    db_user= db.query(User).filter(User.email == user.email).first()
    if not db_user:
        raise HTTPException(status_code=404, details="User not Found")
    if not verify_password(user.password, db_user.password_hash):
        raise HTTPException(status=401, details="invalid Password")
    
    token=create_access_token({
        "user_id":str(db_user.id),
        "role": db_user.role
    })

    return {
      "access_token":token,
      "token_type": "bearer"
    }

@router.get("/me")
def get_me(user = Depends(get_current_user)):
    return {
        "id": str(user.id),
        "email": user.email,
        "role": user.role
    }