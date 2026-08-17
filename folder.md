
uvicorn app.main:app --reload
ngo-backend/
│
├── app/
│   ├── main.py                # Entry point (FastAPI app)
│
│   ├── core/                 # Core configs
│   │   ├── config.py         # env variables
│   │   ├── security.py       # JWT config (later)
│
│   ├── db/                   # Database layer
│   │   ├── database.py       # DB connection
│   │   ├── base.py           # Base model (optional)
│
│   ├── models/               # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── animal.py
│   │   ├── adoption.py
│   │   ├── donation.py
│   │   ├── volunteer.py
│   │   ├── blog.py
│   │   ├── event.py
│
│   ├── schemas/              # Pydantic schemas
│   │   ├── user_schema.py
│   │   ├── animal_schema.py
│   │   ├── adoption_schema.py
│   │   ├── donation_schema.py
│   │   ├── volunteer_schema.py
│
│   ├── auth/                 # Auth system
│   │   ├── hash.py           # password hashing
│   │   ├── jwt.py            # token creation
│   │   ├── deps.py           # current user + admin check
│
│   ├── api/                  # Routes layer
│   │   ├── routes/
│   │   │   ├── auth_routes.py
│   │   │   ├── user_routes.py
│   │   │   ├── animal_routes.py
│   │   │   ├── donation_routes.py
│   │   │   ├── adoption_routes.py
│   │   │   ├── volunteer_routes.py
│   │   │   ├── blog_routes.py
│   │   │   ├── event_routes.py
│
│   ├── services/             # Business logic (VERY IMPORTANT)
│   │   ├── user_service.py
│   │   ├── animal_service.py
│   │   ├── donation_service.py
│   │   ├── adoption_service.py
│
│   ├── utils/                # Helpers
│   │   ├── generate_id.py    # animal_code generator
│   │   ├── validators.py
│
│   ├── constants/            # static values
│   │   ├── roles.py
│   │   ├── status.py
│
│
├── alembic/                  # migrations (later)
│
├── .env                      # environment variables
├── .gitignore
├── requirements.txt
└── README.md