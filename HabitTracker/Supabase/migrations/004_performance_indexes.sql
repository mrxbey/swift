-- HabitTracker Database Schema
-- Migration 004: Performance Indexes
-- Created: 2025-11-18
--
-- This migration adds performance-critical indexes based on:
-- 1. RLS policy lookups (100x improvement for auth.uid() queries)
-- 2. Common query patterns
-- 3. Foreign key joins
-- 4. Sorting/filtering operations

-- ============================================================================
-- AUTH.UID() PERFORMANCE (Critical for RLS)
-- ============================================================================

-- These indexes dramatically improve RLS policy performance
-- Tests show 100x improvement on tables with 100k+ rows

-- Already created in migration 001, but documenting here for reference:
-- CREATE INDEX idx_goals_user_id ON goals(user_id) WHERE status = 'active';

-- Additional auth.uid() indexes
CREATE INDEX IF NOT EXISTS idx_goals_user_id_all ON goals(user_id);
CREATE INDEX IF NOT EXISTS idx_areas_user_id ON areas(user_id);
CREATE INDEX IF NOT EXISTS idx_reflections_user_id ON reflections(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_measurements_user_id ON measurements(user_id);
CREATE INDEX IF NOT EXISTS idx_mood_user_id ON mood_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_tags_user_id ON tags(user_id);
CREATE INDEX IF NOT EXISTS idx_user_programs_user_id ON user_programs(user_id);

-- ============================================================================
-- OCCURRENCE QUERIES (Hot Path)
-- ============================================================================

-- Today's occurrences query (most frequent)
CREATE INDEX IF NOT EXISTS idx_occ_user_date_status ON goal_occurrences(user_id, scheduled_date, status);

-- Upcoming occurrences
CREATE INDEX IF NOT EXISTS idx_occ_user_date_future ON goal_occurrences(user_id, scheduled_date)
    WHERE scheduled_date >= CURRENT_DATE AND status = 'pending';

-- Past occurrences for history
CREATE INDEX IF NOT EXISTS idx_occ_user_date_desc ON goal_occurrences(user_id, scheduled_date DESC);

-- ============================================================================
-- SHARED GOALS (Buddy System)
-- ============================================================================

-- Member lookups (already created in 001, but ensure it exists)
CREATE INDEX IF NOT EXISTS idx_members_user_goal ON goal_members(user_id, goal_id);
CREATE INDEX IF NOT EXISTS idx_members_goal_user ON goal_members(goal_id, user_id);

-- Member status lookups
CREATE INDEX IF NOT EXISTS idx_member_status_occ ON occurrence_member_status(occurrence_id);
CREATE INDEX IF NOT EXISTS idx_member_status_user ON occurrence_member_status(user_id);

-- ============================================================================
-- EVENTS & ANALYTICS
-- ============================================================================

-- Event timeline queries
CREATE INDEX IF NOT EXISTS idx_events_user_time_desc ON goal_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_occ_time ON goal_events(occurrence_id, created_at);

-- Points history
CREATE INDEX IF NOT EXISTS idx_points_user_occurred ON points_ledger(user_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_points_source ON points_ledger(source, source_id);

-- ============================================================================
-- WATER & MEASUREMENTS
-- ============================================================================

-- Daily measurements aggregation
CREATE INDEX IF NOT EXISTS idx_measurements_user_date ON measurements(user_id, (occurred_at::DATE));
CREATE INDEX IF NOT EXISTS idx_measurements_goal_date ON measurements(goal_id, (occurred_at::DATE));

-- Target lookups by date range
CREATE INDEX IF NOT EXISTS idx_measure_targets_dates ON goal_measure_targets(goal_id, effective_from, effective_to);

-- ============================================================================
-- DAILY SUMMARIES
-- ============================================================================

-- History view queries
CREATE INDEX IF NOT EXISTS idx_summary_user_date_desc ON daily_summary(user_id, for_date DESC);
CREATE INDEX IF NOT EXISTS idx_summary_date_range ON daily_summary(user_id, for_date)
    WHERE for_date >= CURRENT_DATE - 90; -- Last 90 days

-- Activity streak queries
CREATE INDEX IF NOT EXISTS idx_activity_user_day_desc ON daily_activity(user_id, day DESC);

-- ============================================================================
-- RECOMMENDATIONS
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_recommendations_user_date ON daily_recommendations(user_id, for_date);
CREATE INDEX IF NOT EXISTS idx_recommendations_today ON daily_recommendations(user_id, for_date)
    WHERE for_date = CURRENT_DATE;

-- ============================================================================
-- REFLECTIONS
-- ============================================================================

-- User reflections timeline
CREATE INDEX IF NOT EXISTS idx_reflections_user_started ON reflections(user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_reflections_completed ON reflections(user_id, completed_at DESC)
    WHERE completed_at IS NOT NULL;

-- Reflections by goal
CREATE INDEX IF NOT EXISTS idx_reflections_goal ON reflections(goal_id)
    WHERE goal_id IS NOT NULL;

-- Template usage
CREATE INDEX IF NOT EXISTS idx_reflections_template ON reflections(template_id);

-- ============================================================================
-- TAGS & HASHTAGS
-- ============================================================================

-- Tag name lookups (case-insensitive)
CREATE INDEX IF NOT EXISTS idx_tags_user_name_lower ON tags(user_id, LOWER(name));

-- Tagging entity lookups
CREATE INDEX IF NOT EXISTS idx_taggings_entity ON taggings(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_taggings_tag ON taggings(tag_id);

-- ============================================================================
-- PROGRAMS (Inspire)
-- ============================================================================

-- Program catalog browsing
CREATE INDEX IF NOT EXISTS idx_programs_visibility ON programs(visibility)
    WHERE visibility = 'public';

CREATE INDEX IF NOT EXISTS idx_programs_category ON programs(category, visibility)
    WHERE visibility = 'public';

CREATE INDEX IF NOT EXISTS idx_programs_rating ON programs(rating_avg DESC, added_count DESC)
    WHERE visibility = 'public';

-- Program items ordering
CREATE INDEX IF NOT EXISTS idx_program_items_order ON program_items(program_id, order_index);

-- User program enrollments
CREATE INDEX IF NOT EXISTS idx_user_programs_active ON user_programs(user_id, started_at DESC)
    WHERE completed_at IS NULL;

-- ============================================================================
-- GIN INDEXES (for array/jsonb searches)
-- ============================================================================

-- Hashtag searches on goals
CREATE INDEX IF NOT EXISTS idx_goals_hashtags_gin ON goals USING GIN(hashtags);

-- Program tags
CREATE INDEX IF NOT EXISTS idx_programs_tags_gin ON programs USING GIN(tags);

-- Reflection content search
CREATE INDEX IF NOT EXISTS idx_reflections_content_gin ON reflections USING GIN(content);

-- JSONB snapshot searches
CREATE INDEX IF NOT EXISTS idx_occ_snapshot_gin ON goal_occurrences USING GIN(content_snapshot);

-- ============================================================================
-- PARTIAL INDEXES (for specific conditions)
-- ============================================================================

-- Active goals only
CREATE INDEX IF NOT EXISTS idx_goals_active ON goals(user_id, area_id, status)
    WHERE status = 'active';

-- Active areas only
CREATE INDEX IF NOT EXISTS idx_areas_active ON areas(user_id, status)
    WHERE status = 'active';

-- Pending occurrences (most common query)
CREATE INDEX IF NOT EXISTS idx_occ_pending ON goal_occurrences(user_id, scheduled_date)
    WHERE status = 'pending';

-- Keep until complete goals
CREATE INDEX IF NOT EXISTS idx_occ_keep_pending ON goal_occurrences(goal_id, scheduled_date)
    WHERE keep_until_complete = TRUE AND status <> 'completed';

-- ============================================================================
-- EXPRESSION INDEXES
-- ============================================================================

-- Case-insensitive area name lookups
CREATE INDEX IF NOT EXISTS idx_areas_name_lower ON areas(user_id, LOWER(name));

-- Date extraction for measurements
CREATE INDEX IF NOT EXISTS idx_measurements_date ON measurements(user_id, DATE(occurred_at));

-- ============================================================================
-- STATISTICS
-- ============================================================================

-- Analyze tables to update query planner statistics
ANALYZE profiles;
ANALYZE areas;
ANALYZE goals;
ANALYZE goal_members;
ANALYZE goal_schedules;
ANALYZE goal_reminders;
ANALYZE goal_occurrences;
ANALYZE occurrence_member_status;
ANALYZE goal_events;
ANALYZE goal_measure_targets;
ANALYZE measurements;
ANALYZE points_ledger;
ANALYZE daily_activity;
ANALYZE daily_summary;
ANALYZE daily_recommendations;
ANALYZE reflection_templates;
ANALYZE reflections;
ANALYZE mood_entries;
ANALYZE tags;
ANALYZE taggings;
ANALYZE sessions;
ANALYZE programs;
ANALYZE program_items;
ANALYZE user_programs;
ANALYZE user_program_items;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON INDEX idx_occ_user_date_covering IS
    'Covering index for hot path today/week queries - includes all columns needed';

COMMENT ON INDEX idx_occ_user_date_status IS
    'Composite index for filtering by date and status simultaneously';

COMMENT ON INDEX idx_goals_active IS
    'Partial index - only indexes active goals for better performance';

COMMENT ON INDEX idx_points_user_occurred IS
    'Optimizes points history queries for gamification dashboard';

COMMENT ON INDEX idx_measurements_user_date IS
    'Expression index for fast daily water consumption aggregation';
