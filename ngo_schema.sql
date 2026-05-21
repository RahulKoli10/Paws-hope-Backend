-- EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext";

-- ENUMS
CREATE TYPE user_role AS ENUM ('admin', 'volunteer');
CREATE TYPE task_status AS ENUM ('pending', 'in_progress', 'completed');
CREATE TYPE blog_status AS ENUM ('draft', 'published');
CREATE TYPE priority_level AS ENUM ('low', 'medium', 'high');

CREATE TYPE rescue_status_enum AS ENUM ('pending','in_progress','completed');
CREATE TYPE adoption_status_enum AS ENUM ('pending','approved','rejected');
CREATE TYPE support_status_enum AS ENUM ('active','fulfilled','cancelled');

---------------------------------------------------
-- USERS
---------------------------------------------------
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email CITEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role user_role NOT NULL,
    permissions JSONB DEFAULT '{}'::jsonb,
    phone VARCHAR(13),
    status VARCHAR(20) DEFAULT 'active',
    is_verified BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE
);

---------------------------------------------------
-- VOLUNTEERS
---------------------------------------------------
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

CREATE TABLE volunteer_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email CITEXT NOT NULL,
    phone VARCHAR(13),
    address VARCHAR(100),
    government_id_proof_url TEXT NOT NULL,
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

---------------------------------------------------
-- TASKS
---------------------------------------------------
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

---------------------------------------------------
-- CONTENT (BLOGS / NEWS)
---------------------------------------------------
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

---------------------------------------------------
-- ANIMALS (CORE TABLE)
---------------------------------------------------
CREATE TABLE animals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    animal_code VARCHAR(70) UNIQUE NOT NULL,
    name VARCHAR(100),
    type VARCHAR(50),
    breed VARCHAR(100),
    age INT CHECK (age >= 0),
    gender VARCHAR(10) CHECK (gender IN ('male','female','unknown')),
    vaccinated BOOLEAN DEFAULT FALSE,
    sterilization BOOLEAN DEFAULT TRUE,
    description TEXT,

    -- CORE STATES
    rescue_status rescue_status_enum DEFAULT 'pending',

    adoption_status VARCHAR(20) DEFAULT 'available'
    CHECK (adoption_status IN ('available','pending','adopted')),

    virtual_adoption_status VARCHAR(20) DEFAULT 'available'
    CHECK (virtual_adoption_status IN ('available','partially_sponsored','fully_sponsored','paused')),

    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

---------------------------------------------------
-- VIRTUAL ADOPTION (TRANSACTIONS)
---------------------------------------------------
CREATE TABLE virtual_adoption_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    animal_id UUID REFERENCES animals(id) ON DELETE CASCADE,

    sponsor_name VARCHAR(100) NOT NULL,
    email CITEXT NOT NULL,
    phone VARCHAR(13),
    address VARCHAR(200),
    government_id_proof_url TEXT NOT NULL,

    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),

    message TEXT,
    payment_id VARCHAR(255),

    payment_status VARCHAR(20) DEFAULT 'pending'
    CHECK (payment_status IN ('pending','completed','failed')),

    status VARCHAR(20) DEFAULT 'active'
    CHECK (status IN ('active','cancelled','expired')),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

---------------------------------------------------
-- ADOPTION REQUESTS
---------------------------------------------------
CREATE TABLE adoption_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    animal_id UUID REFERENCES animals(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    email CITEXT NOT NULL,
    phone VARCHAR(13),
    message TEXT,
    status adoption_status_enum DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

---------------------------------------------------
-- DONATIONS
---------------------------------------------------
CREATE TABLE donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donor_name VARCHAR(100) NOT NULL,
    email CITEXT,
    phone VARCHAR(13),

    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),

    payment_id VARCHAR(255),
    payment_status VARCHAR(20)
    CHECK (payment_status IN ('pending','completed','failed')),

    payment_method VARCHAR(50),
    custom_message TEXT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

---------------------------------------------------
-- RESCUE REPORTS
---------------------------------------------------
CREATE TABLE rescue_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100),
    phone VARCHAR(13),
    location TEXT,
    description TEXT,
    image_url TEXT,
    status rescue_status_enum DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

---------------------------------------------------
-- WISHLIST / SUPPORT
---------------------------------------------------
CREATE TABLE wishlist_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(150) NOT NULL,
    description TEXT,
    category VARCHAR(50),

    quantity_needed INT CHECK (quantity_needed >= 0),
    quantity_received INT DEFAULT 0 CHECK (quantity_received >= 0),

    priority priority_level DEFAULT 'medium',

    image_url TEXT,
    status support_status_enum DEFAULT 'active',

    product_link TEXT,

    tracking_id VARCHAR(100),
    delivery_status VARCHAR(50),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

---------------------------------------------------
-- DONATED ITEMS
---------------------------------------------------
CREATE TABLE donated_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donor_name VARCHAR(100),
    phone VARCHAR(13),
    item_type VARCHAR(100),
    quantity INT CHECK (quantity >= 0),
    item_condition VARCHAR(50),
    pickup_address TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

---------------------------------------------------
-- EVENTS
---------------------------------------------------
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

---------------------------------------------------
-- EVENT REGISTRATIONS
---------------------------------------------------
CREATE TABLE event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    name VARCHAR(100),
    email CITEXT,
    phone VARCHAR(13),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

---------------------------------------------------
-- INDEXES (PERFORMANCE)
---------------------------------------------------
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_blogs_status ON blogs(status);
CREATE INDEX idx_animals_code ON animals(animal_code);
CREATE INDEX idx_animals_type ON animals(type);
CREATE INDEX idx_adoption_status ON adoption_requests(status);
CREATE INDEX idx_rescue_status ON rescue_reports(status);
CREATE INDEX idx_donations_created_at ON donations(created_at);