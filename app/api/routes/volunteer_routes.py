from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth.deps import admin_only
from app.db.database import get_db
from app.auth.hash import hash_password

from app.models.user import User
from app.models.volunteer_request import VolunteerRequest
from app.models.volunteer_profile import VolunteerProfile

router= APIRouter()

@router.post("/apply-for-volunteering")
def apply_for_volunteer(
    data:dict,
    db:Session= Depends(get_db)
):
    new_request = VolunteerRequest(
        name = data["name"],
        email = data["email"],
        phone = data.get("phone"),
        address = data.get("address"),
        government_id_proof_url = data["government_id_proof_url"],
        message = data.get("message")
    )
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return {
        "message": "Volunteer application submitted successfully.",
        "request_id": str(new_request.id)
    }

# admin only
@router.get("/requests")
def get_requests(
    db: Session = Depends(get_db),
    user = Depends(admin_only)
):
    requests = db.query(VolunteerRequest).all()
    return requests


@router.post("/approve/{request_id}")
def approve_volunteer(
    request_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(admin_only)
): 
    req = db.query(VolunteerRequest).filter(VolunteerRequest.id == request_id).first()
    if not req:
        raise HTTPException(status_code=400, detail="Request not found")

       # Prevent duplicate user creation
    existing_user = (
        db.query(User)
        .filter(User.email == req.email)
        .first()
    )

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="User already exists"
        )   
        
    # 1. Create USER
    new_user = User(
        name=req.name,
        email=req.email,
        password_hash=hash_password("volunteer@123"),
        role="volunteer"
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    profile = VolunteerProfile(
        user_id=new_user.id,
        address=req.address,
        government_id_proof_url=req.government_id_proof_url,
        approved_by=user.id
    )

    db.add(profile)
    db.delete(req)

    db.commit()

    return {
        "message": "Volunteer approved successfully",
        "volunteer_id": str(new_user.id)
    }