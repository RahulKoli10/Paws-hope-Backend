from fastapi import FastAPI
from app.db.database import Base, engine
from app.models.user import User
from app.api.routes.auth_routes import router as auth_router
Base.metadata.create_all(bind=engine)
app = FastAPI()
@app.get('/')
def root():
    return {"message": "NGO bakend is Runnin"}

app.include_router(auth_router, prefix="/auth")