-- ============================================================
-- Schema: Titik Baik – Social Donation Mapping
-- Prasyarat: PostgreSQL 13+ dengan ekstensi PostGIS
-- Jalankan: psql -U postgres -d titik_baik -f database/schema.sql
-- ============================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================
-- USERS
-- users.id bertipe UUID (gen_random_uuid() built-in di PG 13+)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    name          VARCHAR(100)  NOT NULL,
    email         VARCHAR(255)  NOT NULL UNIQUE,
    password_hash VARCHAR(255)  NOT NULL,
    role          VARCHAR(20)   NOT NULL CHECK (role IN ('donatur', 'komunitas', 'admin')),
    bio           TEXT,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- DONATION POINTS
-- created_by bertipe UUID karena referensi ke users.id
-- ============================================================
CREATE TABLE IF NOT EXISTS donation_points (
    id          SERIAL  PRIMARY KEY,
    created_by  UUID    REFERENCES users(id) ON DELETE SET NULL,
    title       VARCHAR(200)  NOT NULL,
    description TEXT,
    location    GEOMETRY(Point, 4326) NOT NULL,
    urgency     VARCHAR(20)   NOT NULL DEFAULT 'Normal'
                    CHECK (urgency IN ('Mendesak', 'Normal', 'Rendah')),
    status      VARCHAR(20)   NOT NULL DEFAULT 'Open'
                    CHECK (status IN ('Open', 'On Progress', 'Completed')),
    deleted_at  TIMESTAMP WITH TIME ZONE NULL,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Spatial index (wajib untuk ST_DWithin / ST_Distance)
CREATE INDEX idx_donation_points_location ON donation_points USING GIST(location);
CREATE INDEX idx_donation_points_status   ON donation_points(status);
CREATE INDEX idx_donation_points_active   ON donation_points(deleted_at) WHERE deleted_at IS NULL;

-- ============================================================
-- DOCUMENTATION (bukti foto distribusi)
-- ============================================================
CREATE TABLE IF NOT EXISTS documentation (
    id          SERIAL  PRIMARY KEY,
    point_id    INTEGER NOT NULL REFERENCES donation_points(id) ON DELETE CASCADE,
    uploaded_by UUID    REFERENCES users(id) ON DELETE SET NULL,
    photo_url   VARCHAR(500) NOT NULL,
    caption     TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_documentation_point_id ON documentation(point_id);

-- ============================================================
-- RATINGS
-- ============================================================
CREATE TABLE IF NOT EXISTS ratings (
    id       SERIAL  PRIMARY KEY,
    point_id INTEGER NOT NULL REFERENCES donation_points(id) ON DELETE CASCADE,
    given_by UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    score    INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
    review   TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(point_id, given_by)
);

CREATE INDEX idx_ratings_point_id ON ratings(point_id);

-- ============================================================
-- REPORTS (anti-fraud)
-- ============================================================
CREATE TABLE IF NOT EXISTS reports (
    id          SERIAL  PRIMARY KEY,
    reporter_id UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    point_id    INTEGER NOT NULL REFERENCES donation_points(id) ON DELETE CASCADE,
    reason      TEXT    NOT NULL,
    status      VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'resolved', 'dismissed')),
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_reports_status   ON reports(status);
CREATE INDEX idx_reports_point_id ON reports(point_id);
