
-- Animal NGO Advanced Database Schema (PostgreSQL)

-- This schema is designed for an animal NGO management system, covering various aspects such as user management, task management, blog management, animal management, adoption requests, donations, rescue reports, direct support, donated items, event management, and event registrations.
-- The schema includes advanced features such as ENUM types for roles and statuses, JSONB for permissions, and various constraints to ensure data integrity.
-- Note: This schema assumes the use of PostgreSQL and may require adjustments for other database systems.
-- Ensure that the pgcrypto extension is enabled for UUID generation and secure password hashing.
-- To create the database, run this SQL script in your PostgreSQL environment. Make sure to adjust any configurations as needed for your specific use case.
-- Remember to implement appropriate security measures for handling sensitive data such as user passwords and personal information.
-- This schema is a starting point and can be further expanded or modified based on the specific requirements of the animal NGO management system.
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ENUM Types
CREATE TYPE user_role AS ENUM ('admin', 'volunteer');
CREATE TYPE task_status AS ENUM ('pending', 'in_progress', 'completed');
CREATE TYPE blog_status AS ENUM ('draft', 'published');
CREATE TYPE priority_level AS ENUM ('low', 'medium', 'high');

-- Admin and Volunteer Management
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email CITEXT(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role user_role NOT NULL,
    permissions JSONB DEFAULT '{}' ::jsonb,
    phone VARCHAR(13),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    is_verified BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- Volunteer Profiles
CREATE TABLE volunteer_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    address VARCHAR(100),
    skills TEXT[],
    availability TEXT[],
    government_id_proof_url TEXT NOT NULL,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Volunteers Requests
CREATE TABLE volunteers_request (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email CITEXT(50) NOT NULL,
    phone VARCHAR(13),
    address VARCHAR(100),
    government_id_proof_url TEXT NOT NULL,
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Task Management
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(150) NOT NULL,
    description TEXT,
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    status task_status DEFAULT 'pending',
    priority priority_level DEFAULT 'medium',
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Blog Management
CREATE TABLE blogs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    created_by UUID REFERENCES users(id),
    status blog_status DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- News Management
CREATE TABLE news (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    created_by UUID REFERENCES users(id),
    status blog_status DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Animal Management
CREATE TABLE animals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    animal_id VARCHAR(70) UNIQUE NOT NULL,
    name VARCHAR(100),
    type VARCHAR(50),
    breed VARCHAR(100),
    age INT CHECK (age >= 0),
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'unknown')),
    vaccinated BOOLEAN DEFAULT FALSE,
    sterilization BOOLEAN DEFAULT TRUE,
    description TEXT,
    rescue_status rescue_status DEFAULT 'rescued' CHECK (rescue_status IN ('rescued', 'in_care', 'adopted')),
    virtual_adoption_status DEFAULT 'available' CHECK (virtual_adoption_status IN ('available', 'sponsored', 'paused')),
    virtual_adoption_amount NUMERIC(10,2),
    adoption_status VARCHAR(50) DEFAULT 'available',
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Adoption Requests
CREATE TABLE adoption_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    animal_id UUID REFERENCES animals(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    email CITEXT NOT NULL,
    phone VARCHAR(13),
    message TEXT,
    status adoption_status DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Adopted Animal Details
CREATE TABLE adoption_record (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    adoption_request_id UUID UNIQUE REFERENCES adoption_requests(id) ON DELETE SET NULL,
    owner_name VARCHAR(100) NOT NULL,
    phone VARCHAR(13),
    address VARCHAR(200),
    government_id_proof_url TEXT NOT NULL,
    adoption_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'returned', 'closed')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Virtual Adoption Request
CREATE TABLE virtual_adoption_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    animal_id UUID REFERENCES animals(id) ON DELETE CASCADE,
    sponsor_name VARCHAR(100) NOT NULL,
    email CITEXT NOT NULL,
    phone VARCHAR(13),
    address VARCHAR(200),
    government_id_proof_url TEXT NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    message TEXT,
    payment_id VARCHAR(255),
    payment_status VARCHAR(50) DEFAULT 'pending',
    status VARCHAR(50) DEFAULT 'active'
    CHECK (status IN ('active', 'cancelled', 'expired')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Donation Management
CREATE TABLE donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donor_name VARCHAR(100) NOT NULL,
    email CITEXT,
    phone VARCHAR(13),
    amount NUMERIC(10, 2) NOT NULL CHECK (amount > 0),
    payment_id VARCHAR(255),
    payment_status VARCHAR(50) CHECK (payment_status IN ('pending', 'completed', 'failed')),
    payment_method VARCHAR(50),
    custom_message TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Rescue Reports
CREATE TABLE rescue_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100),
    phone VARCHAR(13),
    location TEXT,
    description TEXT,
    image_url TEXT,
    status rescue_status DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Direct Support and Donations
CREATE TABLE direct_support (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(150) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    quantity_needed INT CHECK (quantity_needed >= 0),
    quantity_received INT DEFAULT 0 check (quantity_received >= 0),
    priority priority_level DEFAULT 'medium',
    image_url TEXT,
    status support_status DEFAULT 'active' CHECK (status IN ('active', 'fulfilled', 'cancelled')),
    product_link TEXT,
    tracking_id UUID,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Donated Items Management
CREATE TABLE donated_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donor_name VARCHAR(100),
    phone VARCHAR(13),
    item_type VARCHAR(100),
    quantity INT CHECK (quantity >= 0),
    condition VARCHAR(50),
    pickup_address TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Event Management
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(150) NOT NULL,
    description TEXT,
    event_date DATE,
    event_time TIME,
    venue TEXT,
    map_link TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Event Registrations
CREATE TABLE event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    name VARCHAR(100),
    email CITEXT,
    phone VARCHAR(13),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for Performance Optimization
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_blogs_status ON blogs(status);
CREATE INDEX idx_donations_created_at ON donations(created_at);
CREATE INDEX idx_animals_type ON animals(type);
