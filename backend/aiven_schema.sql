-- HFA Database Schema for Aiven (PostgreSQL)
-- Run this in the Aiven SQL console to create all tables

CREATE TABLE IF NOT EXISTS branches (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    phone VARCHAR(50),
    video_url TEXT,
    practice_days TEXT
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    password_hash TEXT NOT NULL,
    role VARCHAR(50) DEFAULT 'athlete',
    approved BOOLEAN DEFAULT FALSE,
    branch_id INTEGER REFERENCES branches(id),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS athletes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS registration_requests (
    id SERIAL PRIMARY KEY,
    athlete_name VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    password_hash TEXT,
    branch_name VARCHAR(255),
    approved BOOLEAN DEFAULT FALSE,
    approved_by INTEGER REFERENCES users(id),
    submitted_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS coach_assignments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    UNIQUE(user_id, branch_id)
);

CREATE TABLE IF NOT EXISTS threads (
    id SERIAL PRIMARY KEY,
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    title VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,
    thread_id INTEGER NOT NULL REFERENCES threads(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS attendance (
    id SERIAL PRIMARY KEY,
    athlete_id INTEGER NOT NULL REFERENCES athletes(id),
    session_date DATE NOT NULL,
    status VARCHAR(20),
    branch_id INTEGER REFERENCES branches(id),
    recorded_by INTEGER REFERENCES users(id),
    UNIQUE(athlete_id, session_date)
);

CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    athlete_id INTEGER NOT NULL REFERENCES athletes(id),
    session_date DATE,
    due_date DATE NOT NULL,
    branch_id INTEGER REFERENCES branches(id),
    status VARCHAR(20) DEFAULT 'pending',
    confirmed_by_coach BOOLEAN DEFAULT FALSE,
    UNIQUE(athlete_id, due_date)
);

CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    message TEXT,
    type VARCHAR(50) DEFAULT 'info',
    read_status BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS measurement_logs (
    id SERIAL PRIMARY KEY,
    athlete_id INTEGER NOT NULL REFERENCES athletes(id),
    height DECIMAL(10,2),
    weight DECIMAL(10,2),
    arm DECIMAL(10,2),
    leg DECIMAL(10,2),
    fat DECIMAL(10,2),
    muscle DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS performance_logs (
    id SERIAL PRIMARY KEY,
    athlete_id INTEGER NOT NULL REFERENCES athletes(id),
    meet_name VARCHAR(255),
    meet_date DATE,
    event_name VARCHAR(255),
    result_time DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS coach_credentials (
    id SERIAL PRIMARY KEY,
    coach_user_id INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plain_password TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- SEED DATA (the data you had)
-- ═══════════════════════════════════════════════════════════

INSERT INTO branches (name, address, phone, practice_days) VALUES
    ('Maadi', 'Maadi, Cairo', '01000000001', 'Sat: 4-6PM, Mon: 4-6PM, Wed: 4-6PM'),
    ('Hadayek Al-Ahram', 'Hadayek Al-Ahram, Giza', '01000000002', 'Sat: 4-6PM, Mon: 4-6PM, Wed: 4-6PM'),
    ('6th October', '6th October City, Giza', '01000000003', 'Sun: 4-6PM, Tue: 4-6PM, Thu: 4-6PM'),
    ('Nasr City', 'Nasr City, Cairo', '01000000004', 'Sun: 4-6PM, Tue: 4-6PM, Thu: 4-6PM'),
    ('New Cairo', 'New Cairo, Cairo', '01000000005', 'Sat: 4-6PM, Mon: 4-6PM, Wed: 4-6PM');

-- Head Coach: h@gmail.com / password: 1234
INSERT INTO users (name, email, phone, password_hash, role, approved) VALUES
    ('Head Coach', 'h@gmail.com', '0000000000', '$2b$12$4AeVhvojCfVsHiyuNaFmguQPb8fJZCCDlk4s3tcE7jpFHdj88pOrO', 'head_coach', true);
