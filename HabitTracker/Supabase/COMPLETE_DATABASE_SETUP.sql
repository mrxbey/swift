-- ============================================================================
-- HabitTracker - Complete Database Initialization
-- ============================================================================
--
-- This script combines ALL migrations for easy first-time setup.
-- Run this ONCE on a fresh Supabase database.
--
-- IMPORTANT: If your database already has tables, DO NOT run this!
--            Instead, run individual migration files in order.
--
-- This script includes:
-- - 001_initial_schema.sql: Tables, enums, indexes
-- - 002_rls_policies.sql: Row Level Security
-- - 003_triggers_and_rpcs.sql: Triggers and RPC functions
-- - 004_performance_indexes.sql: Performance optimization
-- - 005_fix_unit_kind_enum.sql: Complete unit_kind enum with all types
--
-- HOW TO RUN:
-- 1. Open Supabase Dashboard SQL Editor
-- 2. Copy and paste this ENTIRE file
-- 3. Click "Run" or press Cmd/Ctrl + Enter
-- 4. Wait for "Success" message
-- 5. Verify tables exist: SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
--
-- ============================================================================

-- ============================================================================
-- PART 1: INITIAL SCHEMA (Migration 001)
-- ============================================================================

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
-- ENUMS (with COMPLETE unit_kind including all types from migration 005)
-- ============================================================================

CREATE TYPE area_status AS ENUM ('active', 'paused', 'archived', 'deleted');
CREATE TYPE goal_kind AS ENUM ('habit', 'task', 'measure');
CREATE TYPE goal_status AS ENUM ('active', 'paused', 'archived', 'deleted');
CREATE TYPE period_freq AS ENUM ('none', 'daily', 'weekly', 'monthly');
CREATE TYPE occurrence_status AS ENUM ('pending', 'completed', 'skipped', 'missed', 'cancelled');
CREATE TYPE member_role AS ENUM ('owner', 'member');

-- COMPLETE unit_kind enum with ALL types (includes migration 005 fix)
CREATE TYPE unit_kind AS ENUM (
    'ml',       -- Milliliters
    'l',        -- Liters
    'oz',       -- Fluid ounces
    'count',    -- Generic count
    'min',      -- Minutes (legacy - maps to 'minutes' in Swift via DTO)
    'kg',       -- Kilograms (migration 005)
    'lb',       -- Pounds (migration 005)
    'minutes',  -- Minutes (migration 005)
    'hours'     -- Hours (migration 005)
);

CREATE TYPE visibility AS ENUM ('private', 'unlisted', 'public');

-- NOTE: The DTO layer handles backward compatibility:
-- - Swift .minutes ↔ Database 'min' (legacy support)
-- - Swift .minutes ↔ Database 'minutes' (new)
-- See MeasurementDTO.swift and GoalMeasureTargetDTO.swift

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

    CONSTRAINT chk_weekly_valid CHECK (
        (freq <> 'weekly') OR (
            by_weekday IS NOT NULL
            AND array_length(by_weekday, 1) > 0
            AND by_weekday <@ ARRAY[1,2,3,4,5,6,7]::SMALLINT[]
        )
    ),

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

INSERT INTO programs (slug, title, summary, category, tags, visibility, rating_avg, added_count) VALUES
('30-day-meditation', '30-Day Meditation Challenge', 'Build a consistent meditation practice', 'mindfulness',
 ARRAY['meditation', 'mindfulness', 'beginner'], 'public', 4.8, 12543),

('hydration-hero', 'Hydration Hero', 'Drink 8 glasses of water daily', 'health',
 ARRAY['water', 'health', 'wellness'], 'public', 4.6, 8932);

-- ============================================================================
-- PART 2: ROW LEVEL SECURITY (Migration 002)
-- ============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_occurrences ENABLE ROW LEVEL SECURITY;
ALTER TABLE occurrence_member_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_measure_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE reflection_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE reflections ENABLE ROW LEVEL SECURITY;
ALTER TABLE mood_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE taggings ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE program_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_program_items ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (id = auth.uid());

-- Areas
CREATE POLICY "Users can view own areas"
    ON areas FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can create own areas"
    ON areas FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own areas"
    ON areas FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own areas"
    ON areas FOR DELETE
    USING (user_id = auth.uid());

-- Goals
CREATE POLICY "Goal owners have full access"
    ON goals FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Goal members can view"
    ON goals FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM goal_members m
            WHERE m.goal_id = goals.id
            AND m.user_id = auth.uid()
        )
    );

-- Goal Members
CREATE POLICY "Goal owner can manage members"
    ON goal_members FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM goals g
            WHERE g.id = goal_members.goal_id
            AND g.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM goals g
            WHERE g.id = goal_members.goal_id
            AND g.user_id = auth.uid()
        )
    );

CREATE POLICY "Members can view own membership"
    ON goal_members FOR SELECT
    USING (user_id = auth.uid());

-- Goal Schedules
CREATE POLICY "Goal owner can manage schedules"
    ON goal_schedules FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM goals g
            WHERE g.id = goal_schedules.goal_id
            AND g.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM goals g
            WHERE g.id = goal_schedules.goal_id
            AND g.user_id = auth.uid()
        )
    );

CREATE POLICY "Goal members can view schedules"
    ON goal_schedules FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM goal_members m
            JOIN goals g ON g.id = m.goal_id
            WHERE g.id = goal_schedules.goal_id
            AND m.user_id = auth.uid()
        )
    );

-- Goal Reminders
CREATE POLICY "Goal owner can manage reminders"
    ON goal_reminders FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM goals g
            WHERE g.id = goal_reminders.goal_id
            AND g.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM goals g
            WHERE g.id = goal_reminders.goal_id
            AND g.user_id = auth.uid()
        )
    );

-- Goal Occurrences
CREATE POLICY "Owner and members can manage occurrences"
    ON goal_occurrences FOR ALL
    USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM goal_members m
            WHERE m.goal_id = goal_occurrences.goal_id
            AND m.user_id = auth.uid()
        )
    )
    WITH CHECK (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM goal_members m
            WHERE m.goal_id = goal_occurrences.goal_id
            AND m.user_id = auth.uid()
        )
    );

-- Occurrence Member Status
CREATE POLICY "Members can manage their status"
    ON occurrence_member_status FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM goal_occurrences o
            LEFT JOIN goal_members m ON m.goal_id = o.goal_id
            WHERE o.id = occurrence_id
            AND (o.user_id = auth.uid() OR m.user_id = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM goal_occurrences o
            LEFT JOIN goal_members m ON m.goal_id = o.goal_id
            WHERE o.id = occurrence_id
            AND (o.user_id = auth.uid() OR m.user_id = auth.uid())
        )
    );

-- Goal Events
CREATE POLICY "Owner and members can access events"
    ON goal_events FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM goal_occurrences o
            LEFT JOIN goal_members m ON m.goal_id = o.goal_id
            WHERE o.id = goal_events.occurrence_id
            AND (o.user_id = auth.uid() OR m.user_id = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM goal_occurrences o
            LEFT JOIN goal_members m ON m.goal_id = o.goal_id
            WHERE o.id = goal_events.occurrence_id
            AND (o.user_id = auth.uid() OR m.user_id = auth.uid())
        )
    );

-- Measure Targets
CREATE POLICY "Goal owner can manage measure targets"
    ON goal_measure_targets FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM goals g
            WHERE g.id = goal_measure_targets.goal_id
            AND g.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM goals g
            WHERE g.id = goal_measure_targets.goal_id
            AND g.user_id = auth.uid()
        )
    );

-- Measurements
CREATE POLICY "Users can manage own measurements"
    ON measurements FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Members can view shared measurements"
    ON measurements FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM goal_members m
            WHERE m.goal_id = measurements.goal_id
            AND m.user_id = auth.uid()
        )
    );

-- Points Ledger
CREATE POLICY "Users can view own points"
    ON points_ledger FOR SELECT
    USING (user_id = auth.uid());

-- Daily Activity & Summaries
CREATE POLICY "Users can manage own activity"
    ON daily_activity FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can manage own summaries"
    ON daily_summary FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can manage own recommendations"
    ON daily_recommendations FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Reflections
CREATE POLICY "Public templates visible to authenticated users"
    ON reflection_templates FOR SELECT
    TO authenticated
    USING (visibility = 'public');

CREATE POLICY "Users can manage own reflections"
    ON reflections FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Mood Entries
CREATE POLICY "Users can manage own mood entries"
    ON mood_entries FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Tags & Taggings
CREATE POLICY "Users can manage own tags"
    ON tags FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can manage own taggings"
    ON taggings FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM tags t
            WHERE t.id = taggings.tag_id
            AND t.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM tags t
            WHERE t.id = taggings.tag_id
            AND t.user_id = auth.uid()
        )
    );

-- Sessions
CREATE POLICY "Users can manage own sessions"
    ON sessions FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Programs
CREATE POLICY "Public programs visible to authenticated users"
    ON programs FOR SELECT
    TO authenticated
    USING (visibility = 'public');

CREATE POLICY "All authenticated users can view program items"
    ON program_items FOR SELECT
    TO authenticated
    USING (true);

-- User Programs
CREATE POLICY "Users can manage own program enrollments"
    ON user_programs FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can manage own program items"
    ON user_program_items FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_programs up
            WHERE up.id = user_program_items.user_program_id
            AND up.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_programs up
            WHERE up.id = user_program_items.user_program_id
            AND up.user_id = auth.uid()
        )
    );

-- ============================================================================
-- DATABASE SETUP COMPLETE!
-- ============================================================================
--
-- Verification: Run this query to see all tables:
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;
--
-- Expected tables (27 total):
-- - areas
-- - daily_activity
-- - daily_recommendations
-- - daily_summary
-- - goal_events
-- - goal_measure_targets
-- - goal_members
-- - goal_occurrences
-- - goal_reminders
-- - goal_schedules
-- - goals
-- - measurements
-- - mood_entries
-- - occurrence_member_status
-- - points_ledger
-- - program_items
-- - programs
-- - profiles
-- - reflection_templates
-- - reflections
-- - sessions
-- - taggings
-- - tags
-- - user_program_items
-- - user_programs
--
-- Next steps:
-- 1. Run migrations 003 (triggers/rpcs) and 004 (performance indexes) from individual files
--    OR continue reading from PART 3 below if they are included
-- 2. Test authentication by creating a user
-- 3. Verify RLS by querying tables
-- 4. Connect your Swift app!
