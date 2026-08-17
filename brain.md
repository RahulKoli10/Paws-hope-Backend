# Backend Brain Map

This file is a living snapshot of what the backend can do right now, based on the code currently present in `backend/app`.

## 1) What this backend is

This is a FastAPI backend with SQLAlchemy models and JWT-based authentication.

Current implementation is centered around:
- user registration and login
- access/refresh token auth
- session tracking by refresh token
- email verification OTP
- password reset OTP
- password change
- volunteer application and approval flow
- a simple database health check

The project also contains a larger SQL schema file for future features such as animals, donations, rescues, tasks, blogs, events, and support items, but those features are not yet implemented in the active FastAPI routes/models.

## 2) Main entry point

`app/main.py` creates the FastAPI app, initializes tables with `Base.metadata.create_all(bind=engine)`, and registers routes.

Mounted routers:
- `/auth` -> authentication routes
- `/volunteer` -> volunteer workflow routes
- `/users` and `/me` from the user router are mounted at root level
- `/test-db` -> database test route

Root endpoint:
- `GET /`
- returns: `{"message": "NGO bakend is Runnin"}`

## 3) Implemented functionality

### Authentication

Auth routes live in `app/api/routes/auth_routes.py` and are mounted under `/auth/v1`.

Implemented endpoints:
- `POST /auth/v1/register`
- `POST /auth/v1/login`
- `GET /auth/v1/me`
- `POST /auth/v1/refresh-token`
- `POST /auth/v1/logout`
- `POST /auth/v1/logout-all`
- `GET /auth/v1/sessions`
- `DELETE /auth/v1/sessions/{session_id}`
- `POST /auth/v1/forgot-password`
- `POST /auth/v1/verify-otp`
- `POST /auth/v1/reset-password`
- `PUT /auth/v1/change-password`
- `POST /auth/v1/send-verification-otp`
- `POST /auth/v1/verify-email`

#### Register
- Creates a new `User`
- Hashes the password with bcrypt
- Creates both access and refresh JWTs
- Stores the refresh token in `refresh_tokens`
- Returns user details plus tokens

#### Login
- Finds user by email
- Requires `user.status == "active"`
- Verifies password
- Enforces a maximum of 3 active refresh-token sessions per user
- Creates a new access token and refresh token
- Saves the refresh token session
- Updates `last_login`

#### Current user
- `GET /auth/v1/me` returns the authenticated user profile

#### Refresh token
- Validates refresh JWT
- Checks that the refresh token exists in the database
- Issues a new access token

#### Logout
- Deletes a single stored refresh-token session

#### Logout all
- Deletes all refresh-token sessions for the current user

#### Session listing
- Lists stored sessions for the authenticated user
- Returns session id, device name, creation time, and expiry

#### Password reset
- `forgot-password` generates a 6-digit OTP and stores it for 10 minutes
- `verify-otp` marks the OTP as verified
- `reset-password` updates the password after OTP verification

#### Change password
- Requires the current password
- Replaces the password hash with a new one

#### Email verification
- `send-verification-otp` generates and stores a 6-digit OTP
- `verify-email` marks the user as verified and deletes the OTP record

### User routes

`app/api/routes/user_routes.py`

Implemented endpoints:
- `GET /users`
- `GET /me`

Behavior:
- `GET /users` returns all users in the database
- `GET /me` returns the current authenticated user’s basic info

### Volunteer workflow

`app/api/routes/volunteer_routes.py`

Implemented endpoints:
- `POST /apply-for-volunteering`
- `GET /volunteer/requests`
- `POST /volunteer/approve/{request_id}`

Behavior:
- Anyone can submit a volunteer application
- Admins can fetch all applications
- Admins can approve a request
- Approval creates a new `User` with role `volunteer`
- Approval also creates a `VolunteerProfile`
- The original request is deleted after approval

### Database test

`GET /test-db`
- runs `SELECT 1`
- returns a simple database connectivity response

## 4) Authentication and authorization model

### JWT

JWT helpers live in `app/auth/jwt.py`.

Token behavior:
- access token expires in 15 minutes
- refresh token expires in 7 days
- both use `SECRET_KEY` from environment variables
- token payload contains:
  - `user_id`
  - `role`
  - `token_type`
  - `exp`

### Current user dependency

`app/auth/deps.py` provides:
- `get_current_user`
- `admin_only`

`get_current_user`:
- reads a bearer token
- decodes JWT
- requires `token_type == "access"`
- loads the user from the database
- rejects inactive users

`admin_only`:
- allows only users whose role is `admin`

## 5) Data models currently in use

### `users`

`app/models/user.py`

Fields:
- `id`
- `name`
- `email`
- `password_hash`
- `role`
- `phone`
- `status`
- `is_verified`
- `created_at`
- `updated_at`
- `last_login`
- `is_deleted`

Notes:
- `role` is an enum with `admin` and `volunteer`
- `status` defaults to `active`
- email uniqueness is enforced

### `refresh_tokens`

`app/models/refresh_token.py`

Stores:
- user id
- refresh token string
- device name
- expiry
- created time

This is what powers session tracking and logout.

### `password_reset_otps`

Stores:
- email
- OTP
- verification flag
- expiry

### `email_verification_otps`

Stores:
- email
- OTP
- verification flag
- expiry

### `volunteer_requestes`

`app/models/volunteer_request.py`

Stores:
- name
- email
- phone
- address
- government ID proof URL
- message

Note: the table name is spelled `volunteer_requestes` in the model.

### `volunteer_profiles`

Stores:
- user id
- address
- government ID proof URL
- approved by

## 6) Schemas used by the API

`app/schemas/user_schema.py` defines request models for:
- registration
- login
- refresh token
- logout
- forgot password
- OTP verification
- password reset
- password change
- email verification OTP flows

Important detail:
- `UserLogin` requires `device_name`, and the login route uses it when storing a refresh-token session.

## 7) Utilities

### Password hashing

`app/auth/hash.py`
- uses `passlib` bcrypt
- provides `hash_password` and `verify_password`

### OTP generation

`app/utils/otp.py`
- generates a random 6-digit numeric string

## 8) Database setup

`app/db/database.py`
- reads `DATABASE_URL` from environment variables
- creates the SQLAlchemy engine
- defines `SessionLocal`
- defines `Base`
- provides `get_db` dependency

## 9) What is not implemented yet

The repository contains a large `ngo_schema.sql` describing a much bigger product, but the corresponding FastAPI models/routes are not present yet.

Not implemented in the active app:
- animals
- adoptions
- donations
- rescue reports
- wishlist/support items
- blogs/news
- events
- task management
- item donations
- event registrations

So, in practical terms, the backend currently behaves like an auth + volunteer management service, not the full NGO platform described by the SQL schema.

## 10) Known rough edges and gaps

- `app/main.py` includes `auth_router` twice.
- `user_routes.py` exposes `GET /users` without auth protection.
- `GET /users` returns raw ORM objects, which may not serialize cleanly depending on configuration.
- `apply-for-volunteering` accepts a plain `dict` instead of a typed Pydantic schema.
- Password reset and verification OTPs are printed to console instead of being sent by email/SMS.
- Some route names and model/table names have spelling inconsistencies, such as `volunteer_requestes`.
- `volunteer_routes.py` uses `user = Depends(admin_only)` in one route and `current_user = Depends(admin_only)` in another, but the same admin check is used in both.
- `get_current_user` in `app/auth/deps.py` catches `JWTError` but the import is incomplete in the current file, so that area should be reviewed before relying on it in production.

## 11) Mental model of the backend today

If you want the shortest summary:

- It can register users, log them in, issue JWTs, and manage sessions.
- It can verify emails and reset passwords using OTPs.
- It can accept volunteer applications and let admins approve them into real volunteer accounts.
- It can confirm the database is reachable.
- It does not yet implement the rest of the NGO domain promised by the SQL schema.

## 12) Suggested next step

If you want, the next useful thing would be to turn this into a more formal backend README or to build a second doc that lists:
- every endpoint with sample request/response
- which routes are public vs protected
- what still needs to be implemented from the SQL schema
