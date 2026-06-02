from fastapi import FastAPI
from app.db.database import Base, engine
from app.models.user import User
from app.api.routes.auth_routes import router as auth_router
from app.api.routes.test_db import router as test_router
from app.api.routes.user_routes import router as user_router
from app.api.routes.auth_routes import router as auth_router
from app.api.routes.volunteer_routes import router as volunteer_router


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