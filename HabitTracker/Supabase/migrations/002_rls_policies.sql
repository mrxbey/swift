-- HabitTracker Database Schema
-- Migration 002: Row Level Security Policies
-- Created: 2025-11-18
--
-- This migration implements comprehensive RLS policies for data security.
-- Performance: Indexes for auth.uid() lookups created in migration 004.

-- ============================================================================
-- ENABLE RLS ON ALL TABLES
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

-- ============================================================================
-- PROFILES
-- ============================================================================

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

-- ============================================================================
-- AREAS
-- ============================================================================

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

-- ============================================================================
-- GOALS
-- ============================================================================

-- Owner can do everything
CREATE POLICY "Goal owners have full access"
    ON goals FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Members can view shared goals
CREATE POLICY "Goal members can view"
    ON goals FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM goal_members m
            WHERE m.goal_id = goals.id
            AND m.user_id = auth.uid()
        )
    );

-- ============================================================================
-- GOAL MEMBERS
-- ============================================================================

-- Goal owner can manage members
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

-- Members can view their membership
CREATE POLICY "Members can view own membership"
    ON goal_members FOR SELECT
    USING (user_id = auth.uid());

-- ============================================================================
-- GOAL SCHEDULES
-- ============================================================================

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

-- Members can view schedules
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

-- ============================================================================
-- GOAL REMINDERS
-- ============================================================================

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

-- ============================================================================
-- GOAL OCCURRENCES
-- ============================================================================

-- Owner and members can view and update occurrences
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

-- ============================================================================
-- OCCURRENCE MEMBER STATUS
-- ============================================================================

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

-- ============================================================================
-- GOAL EVENTS
-- ============================================================================

-- Owner and members can view and insert events
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

-- ============================================================================
-- MEASURE TARGETS
-- ============================================================================

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

-- ============================================================================
-- MEASUREMENTS
-- ============================================================================

-- Owner can manage measurements
CREATE POLICY "Users can manage own measurements"
    ON measurements FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Members can view shared goal measurements
CREATE POLICY "Members can view shared measurements"
    ON measurements FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM goal_members m
            WHERE m.goal_id = measurements.goal_id
            AND m.user_id = auth.uid()
        )
    );

-- ============================================================================
-- POINTS LEDGER
-- ============================================================================

CREATE POLICY "Users can view own points"
    ON points_ledger FOR SELECT
    USING (user_id = auth.uid());

-- ============================================================================
-- DAILY ACTIVITY & SUMMARIES
-- ============================================================================

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

-- ============================================================================
-- REFLECTIONS
-- ============================================================================

-- Public templates visible to all authenticated users
CREATE POLICY "Public templates visible to authenticated users"
    ON reflection_templates FOR SELECT
    TO authenticated
    USING (visibility = 'public');

-- Users own their reflections
CREATE POLICY "Users can manage own reflections"
    ON reflections FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- MOOD ENTRIES
-- ============================================================================

CREATE POLICY "Users can manage own mood entries"
    ON mood_entries FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- TAGS & TAGGINGS
-- ============================================================================

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

-- ============================================================================
-- SESSIONS
-- ============================================================================

CREATE POLICY "Users can manage own sessions"
    ON sessions FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- PROGRAMS (Public catalog)
-- ============================================================================

CREATE POLICY "Public programs visible to authenticated users"
    ON programs FOR SELECT
    TO authenticated
    USING (visibility = 'public');

CREATE POLICY "All authenticated users can view program items"
    ON program_items FOR SELECT
    TO authenticated
    USING (true);

-- ============================================================================
-- USER PROGRAMS
-- ============================================================================

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
-- COMMENTS
-- ============================================================================

COMMENT ON POLICY "Users can view own profile" ON profiles IS
    'Users can only access their own profile data';

COMMENT ON POLICY "Goal owners have full access" ON goals IS
    'Goal creators have complete CRUD access to their goals';

COMMENT ON POLICY "Goal members can view" ON goals IS
    'Buddy system: members can view shared goals';

COMMENT ON POLICY "Owner and members can manage occurrences" ON goal_occurrences IS
    'Both owner and shared members can complete/skip occurrences';

COMMENT ON POLICY "Public templates visible to authenticated users" ON reflection_templates IS
    'Reflection templates are available to all logged-in users';

COMMENT ON POLICY "Public programs visible to authenticated users" ON programs IS
    'Program catalog is browseable by all authenticated users';
