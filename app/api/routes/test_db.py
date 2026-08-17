from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text 

from app.db.database import get_db

router = APIRouter()
@router.get("/test-db")
def test_db(db:Session = Depends(get_db)):
    result = db.execute(text("SELECT 1")).fetchone()
    return{"db_response": result[0]}
