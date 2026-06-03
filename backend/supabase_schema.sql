-- HFA Database Schema for Supabase (PostgreSQL)
-- Run this in the Supabase SQL Editor to create all tables

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

CREATE TABLE IF NOT EXISTS parent_access_codes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    code VARCHAR(10) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
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
