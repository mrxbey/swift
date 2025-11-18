-- HabitTracker Database Schema
-- Migration 001: Initial Schema
-- Created: 2025-11-18

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Helper function for updated_at timestamp
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- ============================================================================
-- ENUMS
-- ============================================================================

CREATE TYPE area_status AS ENUM ('active', 'paused', 'archived', 'deleted');
CREATE TYPE goal_kind AS ENUM ('habit', 'task', 'measure');
CREATE TYPE goal_status AS ENUM ('active', 'paused', 'archived', 'deleted');
CREATE TYPE period_freq AS ENUM ('none', 'daily', 'weekly', 'monthly');
CREATE TYPE occurrence_status AS ENUM ('pending', 'completed', 'skipped', 'missed', 'cancelled');
CREATE TYPE member_role AS ENUM ('owner', 'member');
CREATE TYPE unit_kind AS ENUM ('ml', 'l', 'oz', 'count', 'min');
CREATE TYPE visibility AS ENUM ('private', 'unlisted', 'public');

-- ============================================================================
-- PROFILES
-- ============================================================================

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    tz TEXT NOT NULL DEFAULT 'UTC',
    locale TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER t_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- AREAS
-- ============================================================================

CREATE TABLE areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    emoji TEXT,
    color_hex TEXT,
    status area_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, LOWER(name))
);

CREATE TRIGGER t_areas_updated_at
    BEFORE UPDATE ON areas
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_areas_user_status ON areas(user_id, status);

-- ============================================================================
-- GOALS
-- ============================================================================

CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    area_id UUID NOT NULL REFERENCES areas(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    emoji TEXT,
    kind goal_kind NOT NULL DEFAULT 'habit',
    status goal_status NOT NULL DEFAULT 'active',
    keep_until_complete BOOLEAN NOT NULL DEFAULT FALSE,
    times_per_day INT NOT NULL DEFAULT 1 CHECK (times_per_day BETWEEN 1 AND 100),
    points_per_completion INT NOT NULL DEFAULT 5 CHECK (points_per_completion >= 0),
    linked_exercise_key TEXT,
    hashtags TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER t_goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_goals_user_area ON goals(user_id, area_id);
CREATE INDEX idx_goals_user_status ON goals(user_id, status);
CREATE INDEX idx_goals_user_id ON goals(user_id) WHERE status = 'active';

-- ============================================================================
-- GOAL MEMBERSHIP (Buddy System)
-- ============================================================================

CREATE TABLE goal_members (
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role member_role NOT NULL DEFAULT 'member',
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (goal_id, user_id)
);

CREATE INDEX idx_members_lookup ON goal_members(user_id, goal_id);

-- ============================================================================
-- GOAL SCHEDULES
-- ============================================================================

CREATE TABLE goal_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID NOT NULL UNIQUE REFERENCES goals(id) ON DELETE CASCADE,
    freq period_freq NOT NULL DEFAULT 'none',
    interval INT NOT NULL DEFAULT 1 CHECK (interval >= 1),
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    by_weekday SMALLINT[],
    by_monthday SMALLINT[],
    timezone TEXT NOT NULL DEFAULT 'UTC',
    rrule TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- ISO 8601 weekdays: 1=Mon...7=Sun
    CONSTRAINT chk_weekly_valid CHECK (
        (freq <> 'weekly') OR (
            by_weekday IS NOT NULL
            AND array_length(by_weekday, 1) > 0
            AND by_weekday <@ ARRAY[1,2,3,4,5,6,7]::SMALLINT[]
        )
    ),

    -- Month days: 1..31
    CONSTRAINT chk_monthly_valid CHECK (
        (freq <> 'monthly') OR (
            by_monthday IS NOT NULL
            AND array_length(by_monthday, 1) > 0
            AND by_monthday <@ (
                SELECT array_agg(x::SMALLINT)
                FROM generate_series(1, 31) x
            )
        )
    )
);

CREATE TRIGGER t_schedules_updated_at
    BEFORE UPDATE ON goal_schedules
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- GOAL REMINDERS
-- ============================================================================

CREATE TABLE goal_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    is_on BOOLEAN NOT NULL DEFAULT FALSE,
    time_local TIME,
    timezone TEXT NOT NULL DEFAULT 'UTC',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER t_reminders_updated_at
    BEFORE UPDATE ON goal_reminders
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_reminders_goal ON goal_reminders(goal_id);

-- ============================================================================
-- GOAL OCCURRENCES
-- ============================================================================

CREATE TABLE goal_occurrences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    due_at TIMESTAMPTZ,
    status occurrence_status NOT NULL DEFAULT 'pending',
    target_count INT NOT NULL DEFAULT 1,
    completed_count INT NOT NULL DEFAULT 0,
    keep_until_complete BOOLEAN NOT NULL DEFAULT FALSE,
    rolled_from_id UUID REFERENCES goal_occurrences(id),
    rolled_into_id UUID REFERENCES goal_occurrences(id),
    name_override TEXT,
    emoji_override TEXT,
    content_snapshot JSONB,
    is_one_time BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (goal_id, scheduled_date)
);

CREATE TRIGGER t_occurrences_updated_at
    BEFORE UPDATE ON goal_occurrences
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_occ_user_date ON goal_occurrences(user_id, scheduled_date);
CREATE INDEX idx_occ_goal_date ON goal_occurrences(goal_id, scheduled_date);
CREATE INDEX idx_occ_status ON goal_occurrences(status) WHERE status = 'pending';

-- Covering index for hot path queries
CREATE INDEX idx_occ_user_date_covering ON goal_occurrences(user_id, scheduled_date)
    INCLUDE (goal_id, target_count, completed_count, status);

-- ============================================================================
-- PER-MEMBER OCCURRENCE STATUS
-- ============================================================================

CREATE TABLE occurrence_member_status (
    occurrence_id UUID NOT NULL REFERENCES goal_occurrences(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status occurrence_status NOT NULL DEFAULT 'pending',
    completed_count INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (occurrence_id, user_id)
);

-- ============================================================================
-- GOAL EVENTS (Immutable log)
-- ============================================================================

CREATE TABLE goal_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    occurrence_id UUID NOT NULL REFERENCES goal_occurrences(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    kind TEXT NOT NULL CHECK (kind IN ('complete', 'uncomplete', 'skip', 'reschedule')),
    delta INT DEFAULT 1,
    payload JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_events_occ ON goal_events(occurrence_id, created_at);
CREATE INDEX idx_events_user_date ON goal_events(user_id, created_at DESC);

-- ============================================================================
-- MEASURED GOALS (Water tracking, etc.)
-- ============================================================================

CREATE TABLE goal_measure_targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    unit unit_kind NOT NULL,
    target NUMERIC(10, 3) NOT NULL CHECK (target > 0),
    effective_from DATE NOT NULL,
    effective_to DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_measure_targets ON goal_measure_targets(goal_id, effective_from, effective_to);

CREATE TABLE measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    value NUMERIC(12, 3) NOT NULL CHECK (value >= 0),
    unit unit_kind NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_measurements_goal_time ON measurements(goal_id, occurred_at DESC);
CREATE INDEX idx_measurements_user_time ON measurements(user_id, occurred_at DESC);

-- ============================================================================
-- POINTS & GAMIFICATION
-- ============================================================================

CREATE TABLE points_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    source TEXT NOT NULL,
    source_id UUID,
    points INT NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    meta JSONB
);

CREATE INDEX idx_points_user_time ON points_ledger(user_id, occurred_at DESC);

-- ============================================================================
-- DAILY SUMMARIES
-- ============================================================================

CREATE TABLE daily_activity (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    day DATE NOT NULL,
    has_completion BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (user_id, day)
);

CREATE TABLE daily_summary (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    for_date DATE NOT NULL,
    total_targets INT NOT NULL DEFAULT 0,
    total_done INT NOT NULL DEFAULT 0,
    total_points INT NOT NULL DEFAULT 0,
    water_target NUMERIC(10, 3),
    water_consumed NUMERIC(12, 3),
    mood JSONB,
    reflections_count INT NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, for_date)
);

-- ============================================================================
-- RECOMMENDATIONS
-- ============================================================================

CREATE TABLE daily_recommendations (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    for_date DATE NOT NULL,
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    reason JSONB,
    PRIMARY KEY (user_id, for_date, goal_id)
);

-- ============================================================================
-- REFLECTIONS
-- ============================================================================

CREATE TABLE reflection_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    visibility visibility NOT NULL DEFAULT 'public',
    steps JSONB NOT NULL,
    rating_avg NUMERIC(3, 2),
    added_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER t_reflection_templates_updated_at
    BEFORE UPDATE ON reflection_templates
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE TABLE reflections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    template_id UUID REFERENCES reflection_templates(id),
    goal_id UUID REFERENCES goals(id) ON DELETE SET NULL,
    title TEXT,
    content JSONB,
    hashtags TEXT[] DEFAULT ARRAY[]::TEXT[],
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER t_reflections_updated_at
    BEFORE UPDATE ON reflections
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- MOOD TRACKING
-- ============================================================================

CREATE TABLE mood_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    mood TEXT NOT NULL,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    note TEXT,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- HASHTAGS & TAGGING
-- ============================================================================

CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, LOWER(name))
);

CREATE TABLE taggings (
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL CHECK (entity_type IN ('goal', 'completion', 'reflection', 'mood', 'session', 'program')),
    entity_id UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (tag_id, entity_type, entity_id)
);

-- ============================================================================
-- SESSIONS (Meditation, Pomodoro, etc.)
-- ============================================================================

CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    linked_goal_id UUID REFERENCES goals(id) ON DELETE SET NULL,
    kind TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    payload JSONB
);

CREATE INDEX idx_sessions_user_time ON sessions(user_id, started_at DESC);

-- ============================================================================
-- PROGRAMS (Inspire)
-- ============================================================================

CREATE TABLE programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE,
    title TEXT NOT NULL,
    summary TEXT,
    rich_text JSONB,
    category TEXT,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    thumbnail_url TEXT,
    hero_url TEXT,
    wide_url TEXT,
    rating_avg NUMERIC(3, 2),
    added_count INT NOT NULL DEFAULT 0,
    visibility visibility NOT NULL DEFAULT 'public',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER t_programs_updated_at
    BEFORE UPDATE ON programs
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE TABLE program_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    emoji TEXT,
    kind goal_kind NOT NULL DEFAULT 'habit',
    linked_exercise_key TEXT,
    default_points INT NOT NULL DEFAULT 5,
    schedule JSONB NOT NULL,
    order_index INT NOT NULL DEFAULT 0
);

CREATE TABLE user_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    program_id UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    settings JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, program_id)
);

CREATE TABLE user_program_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_program_id UUID NOT NULL REFERENCES user_programs(id) ON DELETE CASCADE,
    program_item_id UUID NOT NULL REFERENCES program_items(id) ON DELETE CASCADE,
    goal_id UUID REFERENCES goals(id) ON DELETE SET NULL,
    included BOOLEAN NOT NULL DEFAULT TRUE,
    progress JSONB,
    order_index INT NOT NULL DEFAULT 0,
    UNIQUE (user_program_id, program_item_id)
);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE profiles IS 'User profiles with timezone and locale settings';
COMMENT ON TABLE areas IS 'Life areas for organizing goals (work, health, etc.)';
COMMENT ON TABLE goals IS 'User goals - habits, one-time tasks, or measured goals';
COMMENT ON TABLE goal_members IS 'Shared goal membership (buddy system)';
COMMENT ON TABLE goal_schedules IS 'Recurrence patterns using ISO 8601 weekdays';
COMMENT ON TABLE goal_occurrences IS 'Daily instances of scheduled goals';
COMMENT ON TABLE occurrence_member_status IS 'Per-member completion status for shared goals';
COMMENT ON TABLE goal_events IS 'Immutable audit log of user actions';
COMMENT ON TABLE measurements IS 'Measured values (water intake, etc.)';
COMMENT ON TABLE points_ledger IS 'Gamification points history';
COMMENT ON TABLE daily_summary IS 'Materialized daily statistics for performance';
COMMENT ON TABLE daily_recommendations IS 'AI-generated daily goal suggestions';

-- ============================================================================
-- INITIAL DATA
-- ============================================================================

-- Sample reflection templates
INSERT INTO reflection_templates (slug, title, category, visibility, steps) VALUES
('evening-gratitude', 'Evening Gratitude', 'emotions', 'public',
 '[{"type":"info","title":"Reflect on your day","body":"Take a moment to think about what went well today."},
   {"type":"question","prompt":"What are three things you''re grateful for today?","multiline":true},
   {"type":"summary","message":"Thank you for reflecting. See you tomorrow!"}]'::jsonb),

('morning-intention', 'Morning Intention', 'connections', 'public',
 '[{"type":"info","title":"Set your intention","body":"Start your day with purpose."},
   {"type":"question","prompt":"What is your main focus for today?","multiline":true},
   {"type":"question","prompt":"How do you want to feel by the end of the day?","multiline":false},
   {"type":"summary","message":"Have a great day!"}]'::jsonb);

-- Sample programs
INSERT INTO programs (slug, title, summary, category, tags, visibility, rating_avg, added_count) VALUES
('30-day-meditation', '30-Day Meditation Challenge', 'Build a consistent meditation practice', 'mindfulness',
 ARRAY['meditation', 'mindfulness', 'beginner'], 'public', 4.8, 12543),

('hydration-hero', 'Hydration Hero', 'Drink 8 glasses of water daily', 'health',
 ARRAY['water', 'health', 'wellness'], 'public', 4.6, 8932);
