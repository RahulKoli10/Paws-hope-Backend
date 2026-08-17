/*

 NGO MANAGEMENT SYSTEM
 Production Schema - Part 1
 PostgreSQL 16+

*/


-- EXTENSIONS


CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext";


-- ENUMS


CREATE TYPE user_role AS ENUM (
    'admin',
    'volunteer'
);

CREATE TYPE account_status AS ENUM (
    'active',
    'inactive',
    'suspended',
    'blocked'
);

CREATE TYPE notification_type AS ENUM (
    'info',
    'success',
    'warning',
    'error'
);


-- USERS


CREATE TABLE users (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    ------------------------------------------------------
    -- Basic Information
    ------------------------------------------------------

    name VARCHAR(100) NOT NULL,

    email CITEXT NOT NULL UNIQUE,

    phone VARCHAR(20),

    avatar_url TEXT,

    ------------------------------------------------------
    -- Authentication
    ------------------------------------------------------

    password_hash TEXT NOT NULL,

    role user_role NOT NULL,

    permissions JSONB NOT NULL
        DEFAULT '{}'::jsonb,

    ------------------------------------------------------
    -- Account Status
    ------------------------------------------------------

    status account_status NOT NULL
        DEFAULT 'active',

    is_verified BOOLEAN NOT NULL
        DEFAULT FALSE,

    email_verified_at TIMESTAMPTZ,

    ------------------------------------------------------
    -- Login Security
    ------------------------------------------------------

    failed_login_attempts INTEGER NOT NULL
        DEFAULT 0,

    locked_until TIMESTAMPTZ,

    last_login TIMESTAMPTZ,

    last_password_changed_at TIMESTAMPTZ,

    ------------------------------------------------------
    -- Audit
    ------------------------------------------------------

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    created_by UUID
        REFERENCES users(id),

    updated_by UUID
        REFERENCES users(id),

    ------------------------------------------------------
    -- Soft Delete
    ------------------------------------------------------

    is_deleted BOOLEAN NOT NULL
        DEFAULT FALSE,

    deleted_at TIMESTAMPTZ
);


-- REFRESH TOKENS


CREATE TABLE refresh_tokens (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    token TEXT NOT NULL UNIQUE,

    device_name VARCHAR(255) NOT NULL,

    device_type VARCHAR(50),

    browser VARCHAR(100),

    operating_system VARCHAR(100),

    ip_address INET,

    user_agent TEXT,

    last_used_at TIMESTAMPTZ,

    expires_at TIMESTAMPTZ NOT NULL,

    revoked_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


-- PASSWORD RESET OTP


CREATE TABLE password_reset_otps (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    user_id UUID
        REFERENCES users(id)
        ON DELETE CASCADE,

    email CITEXT NOT NULL,

    otp VARCHAR(6) NOT NULL,

    attempts INTEGER NOT NULL
        DEFAULT 0,

    is_verified BOOLEAN NOT NULL
        DEFAULT FALSE,

    expires_at TIMESTAMPTZ NOT NULL,

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


-- EMAIL VERIFICATION OTP


CREATE TABLE email_verification_otps (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    user_id UUID
        REFERENCES users(id)
        ON DELETE CASCADE,

    email CITEXT NOT NULL,

    otp VARCHAR(6) NOT NULL,

    expires_at TIMESTAMPTZ NOT NULL,

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


-- AUDIT LOGS


CREATE TABLE audit_logs (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    user_id UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    action VARCHAR(100) NOT NULL,

    entity VARCHAR(100) NOT NULL,

    entity_id UUID,

    ip_address INET,

    user_agent TEXT,

    metadata JSONB
        DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


-- NOTIFICATIONS


CREATE TABLE notifications (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    title VARCHAR(200) NOT NULL,

    message TEXT NOT NULL,

    type notification_type NOT NULL
        DEFAULT 'info',

    is_read BOOLEAN NOT NULL
        DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


-- MEDIA FILES


CREATE TABLE media_files (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    file_name VARCHAR(255) NOT NULL,

    original_name VARCHAR(255),

    file_url TEXT NOT NULL,

    mime_type VARCHAR(100),

    file_size BIGINT,

    uploaded_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


-- INDEXES


CREATE INDEX idx_users_email
ON users(email);

CREATE INDEX idx_users_status
ON users(status);

CREATE INDEX idx_users_role
ON users(role);

CREATE INDEX idx_refresh_tokens_user
ON refresh_tokens(user_id);

CREATE INDEX idx_refresh_tokens_expiry
ON refresh_tokens(expires_at);

CREATE INDEX idx_password_reset_email
ON password_reset_otps(email);

CREATE INDEX idx_email_verification_email
ON email_verification_otps(email);

CREATE INDEX idx_notifications_user
ON notifications(user_id);

CREATE INDEX idx_notifications_read
ON notifications(is_read);

CREATE INDEX idx_audit_logs_user
ON audit_logs(user_id);

CREATE INDEX idx_audit_logs_entity
ON audit_logs(entity, entity_id);

/*

PART 2
VOLUNTEER & OPERATIONS MODULE

*/


-- ENUMS


CREATE TYPE volunteer_request_status AS ENUM (
    'pending',
    'approved',
    'rejected',
    'withdrawn'
);

CREATE TYPE task_status AS ENUM (
    'pending',
    'assigned',
    'accepted',
    'in_progress',
    'on_hold',
    'completed',
    'cancelled'
);

CREATE TYPE priority_level AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);

CREATE TYPE task_type AS ENUM (
    'rescue',
    'adoption',
    'event',
    'donation_pickup',
    'medical',
    'transport',
    'general'
);


-- VOLUNTEER REQUESTS


CREATE TABLE volunteer_requests (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    ------------------------------------------------------

    name VARCHAR(100) NOT NULL,

    email CITEXT NOT NULL,

    phone VARCHAR(20),

    ------------------------------------------------------

    address TEXT,

    city VARCHAR(100),

    state VARCHAR(100),

    pincode VARCHAR(10),

    ------------------------------------------------------

    government_id_proof_url TEXT NOT NULL,

    message TEXT,

    ------------------------------------------------------

    status volunteer_request_status
        DEFAULT 'pending',

    reviewed_by UUID
        REFERENCES users(id),

    reviewed_at TIMESTAMPTZ,

    rejection_reason TEXT,

    ------------------------------------------------------

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- VOLUNTEER PROFILE


CREATE TABLE volunteer_profiles (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    user_id UUID UNIQUE NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    ------------------------------------------------------

    address TEXT,

    city VARCHAR(100),

    state VARCHAR(100),

    pincode VARCHAR(10),

    ------------------------------------------------------

    emergency_contact_name VARCHAR(100),

    emergency_contact_phone VARCHAR(20),

    ------------------------------------------------------

    skills TEXT[],

    availability TEXT[],

    experience TEXT,

    ------------------------------------------------------

    government_id_proof_url TEXT NOT NULL,

    approved_by UUID
        REFERENCES users(id),

    approved_at TIMESTAMPTZ,

    ------------------------------------------------------

    total_tasks_completed INT
        DEFAULT 0,

    total_hours_served INT
        DEFAULT 0,

    ------------------------------------------------------

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- TASKS


CREATE TABLE tasks (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    ------------------------------------------------------

    title VARCHAR(200) NOT NULL,

    description TEXT,

    task_type task_type NOT NULL,

    priority priority_level
        DEFAULT 'medium',

    status task_status
        DEFAULT 'pending',

    ------------------------------------------------------

    assigned_to UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    assigned_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    ------------------------------------------------------

    due_date TIMESTAMPTZ,

    accepted_at TIMESTAMPTZ,

    started_at TIMESTAMPTZ,

    completed_at TIMESTAMPTZ,

    ------------------------------------------------------

    location TEXT,

    latitude DECIMAL(10,7),

    longitude DECIMAL(10,7),

    ------------------------------------------------------

    remarks TEXT,

    ------------------------------------------------------

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- TASK COMMENTS


CREATE TABLE task_comments (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    task_id UUID NOT NULL
        REFERENCES tasks(id)
        ON DELETE CASCADE,

    user_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    comment TEXT NOT NULL,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- TASK ATTACHMENTS


CREATE TABLE task_attachments (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    task_id UUID NOT NULL
        REFERENCES tasks(id)
        ON DELETE CASCADE,

    uploaded_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    media_id UUID
        REFERENCES media_files(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- TASK ACTIVITY LOG


CREATE TABLE task_activity_logs (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    task_id UUID NOT NULL
        REFERENCES tasks(id)
        ON DELETE CASCADE,

    user_id UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    action VARCHAR(100) NOT NULL,

    previous_value TEXT,

    new_value TEXT,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- INDEXES

CREATE INDEX idx_volunteer_requests_status
ON volunteer_requests(status);

CREATE INDEX idx_volunteer_requests_email
ON volunteer_requests(email);

CREATE INDEX idx_tasks_status
ON tasks(status);

CREATE INDEX idx_tasks_priority
ON tasks(priority);

CREATE INDEX idx_tasks_assigned_to
ON tasks(assigned_to);

CREATE INDEX idx_tasks_due_date
ON tasks(due_date);

CREATE INDEX idx_task_comments_task
ON task_comments(task_id);

CREATE INDEX idx_task_activity_logs_task
ON task_activity_logs(task_id);


/*

PART 3A
ANIMAL CORE MODULE

*/


-- ENUMS


CREATE TYPE animal_gender AS ENUM (
    'male',
    'female',
    'unknown'
);

CREATE TYPE animal_status AS ENUM (
    'active',
    'adopted',
    'deceased',
    'missing'
);

CREATE TYPE rescue_status AS ENUM (
    'pending',
    'reported',
    'assigned',
    'in_progress',
    'rescued',
    'closed'
);

CREATE TYPE adoption_status AS ENUM (
    'available',
    'pending',
    'adopted',
    'rejected'
);

CREATE TYPE sponsorship_status AS ENUM (
    'available',
    'partial',
    'fully_sponsored',
    'paused'
);


-- ANIMALS


CREATE TABLE animals (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    ------------------------------------------------------
    -- Identity
    ------------------------------------------------------

    animal_code VARCHAR(70) NOT NULL UNIQUE,

    name VARCHAR(100),

    species VARCHAR(80) NOT NULL,

    breed VARCHAR(120),

    gender animal_gender
        DEFAULT 'unknown',

    estimated_age_months INTEGER,

    weight_kg NUMERIC(5,2),

    color VARCHAR(120),

    ------------------------------------------------------
    -- Medical
    ------------------------------------------------------

    vaccinated BOOLEAN
        DEFAULT FALSE,

    sterilized BOOLEAN
        DEFAULT FALSE,

    microchip_number VARCHAR(100),

    medical_notes TEXT,

    ------------------------------------------------------
    -- Current State
    ------------------------------------------------------

    status animal_status
        DEFAULT 'active',

    rescue_status rescue_status
        DEFAULT 'pending',

    adoption_status adoption_status
        DEFAULT 'available',

    sponsorship_status sponsorship_status
        DEFAULT 'available',

    ------------------------------------------------------
    -- Location
    ------------------------------------------------------

    current_location TEXT,

    ------------------------------------------------------
    -- Description
    ------------------------------------------------------

    description TEXT,

    ------------------------------------------------------
    -- Primary Image
    ------------------------------------------------------

    primary_media_id UUID
        REFERENCES media_files(id)
        ON DELETE SET NULL,

    ------------------------------------------------------
    -- Audit
    ------------------------------------------------------

    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    updated_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP,

    ------------------------------------------------------
    -- Soft Delete
    ------------------------------------------------------

    is_deleted BOOLEAN
        DEFAULT FALSE,

    deleted_at TIMESTAMPTZ
);


-- ANIMAL GALLERY


CREATE TABLE animal_gallery (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    animal_id UUID NOT NULL
        REFERENCES animals(id)
        ON DELETE CASCADE,

    media_id UUID NOT NULL
        REFERENCES media_files(id)
        ON DELETE CASCADE,

    caption TEXT,

    display_order INTEGER
        DEFAULT 1,

    uploaded_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- ANIMAL DOCUMENTS


CREATE TABLE animal_documents (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    animal_id UUID NOT NULL
        REFERENCES animals(id)
        ON DELETE CASCADE,

    title VARCHAR(200),

    document_type VARCHAR(100),

    media_id UUID NOT NULL
        REFERENCES media_files(id)
        ON DELETE CASCADE,

    uploaded_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- ANIMAL ACTIVITY LOG


CREATE TABLE animal_activity_logs (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    animal_id UUID NOT NULL
        REFERENCES animals(id)
        ON DELETE CASCADE,

    user_id UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    action VARCHAR(100) NOT NULL,

    metadata JSONB
        DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- INDEXES


CREATE INDEX idx_animals_code
ON animals(animal_code);

CREATE INDEX idx_animals_species
ON animals(species);

CREATE INDEX idx_animals_status
ON animals(status);

CREATE INDEX idx_animals_rescue_status
ON animals(rescue_status);

CREATE INDEX idx_animals_adoption_status
ON animals(adoption_status);

CREATE INDEX idx_animals_created_at
ON animals(created_at);

CREATE INDEX idx_gallery_animal
ON animal_gallery(animal_id);

CREATE INDEX idx_documents_animal
ON animal_documents(animal_id);

CREATE INDEX idx_activity_animal
ON animal_activity_logs(animal_id);

/*

PART 3B
RESCUE MANAGEMENT

*/


-- ENUMS


CREATE TYPE rescue_priority AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);

CREATE TYPE rescue_report_status AS ENUM (
    'reported',
    'verified',
    'assigned',
    'in_progress',
    'rescued',
    'cancelled',
    'closed'
);


-- RESCUE REPORTS


CREATE TABLE rescue_reports (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    ------------------------------------------------------
    -- Reporter Information
    ------------------------------------------------------

    reporter_name VARCHAR(100),

    reporter_email CITEXT,

    reporter_phone VARCHAR(20),

    ------------------------------------------------------
    -- Rescue Details
    ------------------------------------------------------

    title VARCHAR(200),

    description TEXT NOT NULL,

    priority rescue_priority
        DEFAULT 'medium',

    status rescue_report_status
        DEFAULT 'reported',

    ------------------------------------------------------
    -- Location
    ------------------------------------------------------

    address TEXT,

    latitude DECIMAL(10,7),

    longitude DECIMAL(10,7),

    landmark TEXT,

    ------------------------------------------------------
    -- Assignment
    ------------------------------------------------------

    assigned_to UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    assigned_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    assigned_at TIMESTAMPTZ,

    ------------------------------------------------------
    -- Animal
    ------------------------------------------------------

    animal_id UUID
        REFERENCES animals(id)
        ON DELETE SET NULL,

    ------------------------------------------------------
    -- Related Task
    ------------------------------------------------------

    task_id UUID
        REFERENCES tasks(id)
        ON DELETE SET NULL,

    ------------------------------------------------------
    -- Closure
    ------------------------------------------------------

    closed_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    closed_at TIMESTAMPTZ,

    closing_notes TEXT,

    ------------------------------------------------------
    -- Audit
    ------------------------------------------------------

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- RESCUE TIMELINE


CREATE TABLE rescue_timelines (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    rescue_report_id UUID NOT NULL
        REFERENCES rescue_reports(id)
        ON DELETE CASCADE,

    performed_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    action VARCHAR(150) NOT NULL,

    description TEXT,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- RESCUE MEDIA


CREATE TABLE rescue_media (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    rescue_report_id UUID NOT NULL
        REFERENCES rescue_reports(id)
        ON DELETE CASCADE,

    media_id UUID NOT NULL
        REFERENCES media_files(id)
        ON DELETE CASCADE,

    uploaded_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    caption TEXT,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- RESCUE VOLUNTEERS


CREATE TABLE rescue_volunteers (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    rescue_report_id UUID NOT NULL
        REFERENCES rescue_reports(id)
        ON DELETE CASCADE,

    volunteer_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    role VARCHAR(100),

    joined_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(rescue_report_id, volunteer_id)
);


-- INDEXES


CREATE INDEX idx_rescue_status
ON rescue_reports(status);

CREATE INDEX idx_rescue_priority
ON rescue_reports(priority);

CREATE INDEX idx_rescue_assigned_to
ON rescue_reports(assigned_to);

CREATE INDEX idx_rescue_animal
ON rescue_reports(animal_id);

CREATE INDEX idx_rescue_task
ON rescue_reports(task_id);

CREATE INDEX idx_rescue_created
ON rescue_reports(created_at);

CREATE INDEX idx_timeline_rescue
ON rescue_timelines(rescue_report_id);

CREATE INDEX idx_rescue_media
ON rescue_media(rescue_report_id);

CREATE INDEX idx_rescue_volunteers
ON rescue_volunteers(rescue_report_id);

/*

PART 3C
MEDICAL + ADOPTION + SPONSORSHIP

*/


-- ENUMS


CREATE TYPE medical_record_type AS ENUM (
    'checkup',
    'treatment',
    'surgery',
    'vaccination',
    'deworming',
    'emergency'
);

CREATE TYPE adoption_request_status AS ENUM (
    'pending',
    'under_review',
    'approved',
    'rejected',
    'cancelled'
);

CREATE TYPE sponsorship_payment_status AS ENUM (
    'pending',
    'paid',
    'failed',
    'refunded'
);


-- ANIMAL MEDICAL RECORDS


CREATE TABLE animal_medical_records (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    animal_id UUID NOT NULL
        REFERENCES animals(id)
        ON DELETE CASCADE,

    record_type medical_record_type NOT NULL,

    veterinarian_name VARCHAR(150),

    clinic_name VARCHAR(150),

    diagnosis TEXT,

    treatment TEXT,

    medications TEXT,

    weight_kg NUMERIC(5,2),

    next_visit_date DATE,

    notes TEXT,

    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- ANIMAL VACCINATIONS


CREATE TABLE animal_vaccinations (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    animal_id UUID NOT NULL
        REFERENCES animals(id)
        ON DELETE CASCADE,

    vaccine_name VARCHAR(150) NOT NULL,

    batch_number VARCHAR(100),

    administered_by VARCHAR(150),

    vaccination_date DATE NOT NULL,

    next_due_date DATE,

    notes TEXT,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- ADOPTION REQUESTS


CREATE TABLE adoption_requests (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    animal_id UUID NOT NULL
        REFERENCES animals(id)
        ON DELETE RESTRICT,

    ------------------------------------------------------

    applicant_name VARCHAR(120) NOT NULL,

    email CITEXT NOT NULL,

    phone VARCHAR(20),

    address TEXT,

    city VARCHAR(100),

    state VARCHAR(100),

    pincode VARCHAR(10),

    ------------------------------------------------------

    occupation VARCHAR(150),

    family_members INTEGER,

    has_other_pets BOOLEAN,

    experience_with_animals TEXT,

    reason_for_adoption TEXT,

    ------------------------------------------------------

    government_id_media_id UUID
        REFERENCES media_files(id)
        ON DELETE SET NULL,

    ------------------------------------------------------

    status adoption_request_status
        DEFAULT 'pending',

    reviewed_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    reviewed_at TIMESTAMPTZ,

    rejection_reason TEXT,

    ------------------------------------------------------

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- VIRTUAL ADOPTIONS


CREATE TABLE virtual_adoptions (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    animal_id UUID NOT NULL
        REFERENCES animals(id)
        ON DELETE CASCADE,

    user_id UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    sponsor_name VARCHAR(120),

    sponsor_email CITEXT,

    sponsor_phone VARCHAR(20),

    monthly_amount NUMERIC(10,2) NOT NULL,

    payment_status sponsorship_payment_status
        DEFAULT 'pending',

    payment_reference VARCHAR(255),

    start_date DATE NOT NULL,

    end_date DATE,

    notes TEXT,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- INDEXES


CREATE INDEX idx_medical_records_animal
ON animal_medical_records(animal_id);

CREATE INDEX idx_vaccinations_animal
ON animal_vaccinations(animal_id);

CREATE INDEX idx_adoption_requests_status
ON adoption_requests(status);

CREATE INDEX idx_adoption_requests_animal
ON adoption_requests(animal_id);

CREATE INDEX idx_virtual_adoptions_animal
ON virtual_adoptions(animal_id);

CREATE INDEX idx_virtual_adoptions_user
ON virtual_adoptions(user_id);

/*

PART 4
DONATIONS & SUPPORT

*/


-- ENUMS


CREATE TYPE donor_type AS ENUM (
    'guest',
    'registered'
);

CREATE TYPE donation_type AS ENUM (
    'one_time',
    'monthly',
    'yearly'
);

CREATE TYPE payment_status AS ENUM (
    'pending',
    'paid',
    'failed',
    'refunded'
);

CREATE TYPE donated_item_status AS ENUM (
    'pending',
    'accepted',
    'rejected',
    'picked_up',
    'completed'
);

CREATE TYPE wishlist_status AS ENUM (
    'active',
    'fulfilled',
    'cancelled'
);

-- DONORS

CREATE TABLE donors (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    user_id UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    full_name VARCHAR(120) NOT NULL,

    email CITEXT,

    phone VARCHAR(20),

    address TEXT,

    city VARCHAR(100),

    state VARCHAR(100),

    pincode VARCHAR(10),

    anonymous BOOLEAN
        DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- DONATIONS


CREATE TABLE donations (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    donor_id UUID
        REFERENCES donors(id)
        ON DELETE SET NULL,

    donation_type donation_type
        DEFAULT 'one_time',

    amount NUMERIC(10,2) NOT NULL,

    currency VARCHAR(10)
        DEFAULT 'INR',

    payment_status payment_status
        DEFAULT 'pending',

    payment_reference VARCHAR(255),

    payment_gateway VARCHAR(100),

    receipt_number VARCHAR(100),

    notes TEXT,

    donated_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP,

    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL
);


-- DONATION PAYMENTS


CREATE TABLE donation_payments (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    donation_id UUID NOT NULL
        REFERENCES donations(id)
        ON DELETE CASCADE,

    gateway_transaction_id VARCHAR(255),

    gateway_name VARCHAR(100),

    amount NUMERIC(10,2) NOT NULL,

    payment_status payment_status
        DEFAULT 'pending',

    payment_date TIMESTAMPTZ,

    raw_response JSONB,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- WISHLIST ITEMS


CREATE TABLE wishlist_items (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    title VARCHAR(200) NOT NULL,

    description TEXT,

    category VARCHAR(100),

    quantity_required INTEGER NOT NULL,

    quantity_received INTEGER
        DEFAULT 0,

    priority priority_level
        DEFAULT 'medium',

    status wishlist_status
        DEFAULT 'active',

    image_media_id UUID
        REFERENCES media_files(id)
        ON DELETE SET NULL,

    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- DONATED ITEMS


CREATE TABLE donated_items (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    donor_id UUID
        REFERENCES donors(id)
        ON DELETE SET NULL,

    item_name VARCHAR(150) NOT NULL,

    category VARCHAR(100),

    quantity INTEGER NOT NULL,

    condition VARCHAR(100),

    pickup_address TEXT,

    pickup_date DATE,

    status donated_item_status
        DEFAULT 'pending',

    notes TEXT,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- WISHLIST DONATIONS


CREATE TABLE wishlist_donations (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    wishlist_item_id UUID NOT NULL
        REFERENCES wishlist_items(id)
        ON DELETE CASCADE,

    donated_item_id UUID
        REFERENCES donated_items(id)
        ON DELETE SET NULL,

    quantity INTEGER NOT NULL,

    received_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    received_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- INDEXES


CREATE INDEX idx_donors_email
ON donors(email);

CREATE INDEX idx_donations_donor
ON donations(donor_id);

CREATE INDEX idx_donations_status
ON donations(payment_status);

CREATE INDEX idx_donation_payments_donation
ON donation_payments(donation_id);

CREATE INDEX idx_wishlist_status
ON wishlist_items(status);

CREATE INDEX idx_donated_items_status
ON donated_items(status);

CREATE INDEX idx_wishlist_donations_item
ON wishlist_donations(wishlist_item_id);


/*

PART 5
CONTENT & PUBLIC ENGAGEMENT

*/


-- ENUMS


CREATE TYPE content_status AS ENUM (
    'draft',
    'review',
    'published',
    'archived'
);

CREATE TYPE event_status AS ENUM (
    'draft',
    'published',
    'completed',
    'cancelled'
);

CREATE TYPE registration_status AS ENUM (
    'registered',
    'attended',
    'cancelled'
);


-- BLOGS


CREATE TABLE blogs (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    title VARCHAR(255) NOT NULL,

    slug VARCHAR(255) UNIQUE NOT NULL,

    summary TEXT,

    content TEXT NOT NULL,

    featured_media_id UUID
        REFERENCES media_files(id)
        ON DELETE SET NULL,

    status content_status
        DEFAULT 'draft',

    published_at TIMESTAMPTZ,

    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    updated_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP,

    is_deleted BOOLEAN
        DEFAULT FALSE
);


-- BLOG TAGS


CREATE TABLE blog_tags (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    name VARCHAR(100) UNIQUE NOT NULL
);


-- BLOG TAG MAPPING


CREATE TABLE blog_tag_mappings (

    blog_id UUID
        REFERENCES blogs(id)
        ON DELETE CASCADE,

    tag_id UUID
        REFERENCES blog_tags(id)
        ON DELETE CASCADE,

    PRIMARY KEY(blog_id, tag_id)
);


-- NEWS


CREATE TABLE news (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    title VARCHAR(255) NOT NULL,

    slug VARCHAR(255) UNIQUE NOT NULL,

    summary TEXT,

    content TEXT NOT NULL,

    featured_media_id UUID
        REFERENCES media_files(id)
        ON DELETE SET NULL,

    status content_status
        DEFAULT 'draft',

    published_at TIMESTAMPTZ,

    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    updated_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- EVENTS


CREATE TABLE events (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    title VARCHAR(255) NOT NULL,

    description TEXT,

    banner_media_id UUID
        REFERENCES media_files(id)
        ON DELETE SET NULL,

    venue TEXT,

    latitude DECIMAL(10,7),

    longitude DECIMAL(10,7),

    start_datetime TIMESTAMPTZ NOT NULL,

    end_datetime TIMESTAMPTZ NOT NULL,

    registration_deadline TIMESTAMPTZ,

    max_participants INTEGER,

    status event_status
        DEFAULT 'draft',

    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- EVENT REGISTRATIONS


CREATE TABLE event_registrations (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    event_id UUID NOT NULL
        REFERENCES events(id)
        ON DELETE CASCADE,

    user_id UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    name VARCHAR(120),

    email CITEXT,

    phone VARCHAR(20),

    registration_status registration_status
        DEFAULT 'registered',

    registered_at TIMESTAMPTZ
        DEFAULT CURRENT_TIMESTAMP
);


-- INDEXES


CREATE INDEX idx_blog_slug
ON blogs(slug);

CREATE INDEX idx_blog_status
ON blogs(status);

CREATE INDEX idx_blog_publish
ON blogs(published_at);

CREATE INDEX idx_news_slug
ON news(slug);

CREATE INDEX idx_news_status
ON news(status);

CREATE INDEX idx_event_status
ON events(status);

CREATE INDEX idx_event_start
ON events(start_datetime);

CREATE INDEX idx_event_registration_event
ON event_registrations(event_id);