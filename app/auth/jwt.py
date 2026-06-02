from datetime import datetime, timedelta
from jose import jwt
from dotenv import load_dotenv
import os

load_dotenv()
SECRET_KEY= os.getenv("SECRET_KEY")
ALGORITHM = "HS256"

def create_access_token(data: dict):
    to_encode = data.copy()
    
    expire = datetime.utcnow() + timedelta(hours=24)
    
    # convert datetime to timestamp
    to_encode.update({"exp": expire.timestamp()})
    
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)