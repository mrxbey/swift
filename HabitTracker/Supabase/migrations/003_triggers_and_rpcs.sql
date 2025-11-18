-- HabitTracker Database Schema
-- Migration 003: Triggers and Remote Procedure Calls (RPCs)
-- Created: 2025-11-18
--
-- This migration implements business logic via database triggers and
-- provides type-safe RPC endpoints for the Swift client.

-- ============================================================================
-- TRIGGERS: Points & Daily Activity
-- ============================================================================

CREATE OR REPLACE FUNCTION award_points_on_occ_complete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_goal goals%ROWTYPE;
BEGIN
    -- Only award points when transitioning to completed
    IF NEW.status = 'completed' AND (OLD.status IS DISTINCT FROM 'completed') THEN
        -- Get goal details
        SELECT * INTO v_goal FROM goals WHERE id = NEW.goal_id;

        -- Award points
        INSERT INTO points_ledger(user_id, source, source_id, points, meta)
        VALUES (
            v_goal.user_id,
            'goal_completion',
            NEW.id,
            v_goal.points_per_completion,
            jsonb_build_object(
                'goal_title', v_goal.title,
                'goal_emoji', v_goal.emoji,
                'scheduled_date', NEW.scheduled_date
            )
        );

        -- Mark daily activity
        INSERT INTO daily_activity(user_id, day, has_completion)
        VALUES (v_goal.user_id, NEW.scheduled_date, TRUE)
        ON CONFLICT (user_id, day)
        DO UPDATE SET has_completion = TRUE;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_points_on_complete
    AFTER UPDATE ON goal_occurrences
    FOR EACH ROW
    EXECUTE FUNCTION award_points_on_occ_complete();

COMMENT ON FUNCTION award_points_on_occ_complete IS
    'Automatically awards points and tracks daily activity when occurrence is completed';

-- ============================================================================
-- TRIGGERS: Daily Summary Refresh
-- ============================================================================

CREATE OR REPLACE FUNCTION refresh_daily_summary_fn(p_user UUID, p_date DATE)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_targets INT;
    v_total_done INT;
    v_total_points INT;
    v_reflections_count INT;
BEGIN
    -- Calculate totals
    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE status = 'completed'),
        COALESCE(SUM(
            CASE
                WHEN status = 'completed' THEN
                    (SELECT points_per_completion FROM goals WHERE id = o.goal_id)
                ELSE 0
            END
        ), 0)
    INTO v_total_targets, v_total_done, v_total_points
    FROM goal_occurrences o
    WHERE o.user_id = p_user
    AND o.scheduled_date = p_date;

    -- Count reflections
    SELECT COUNT(*)
    INTO v_reflections_count
    FROM reflections r
    WHERE r.user_id = p_user
    AND r.started_at::DATE = p_date;

    -- Upsert summary
    INSERT INTO daily_summary(
        user_id,
        for_date,
        total_targets,
        total_done,
        total_points,
        reflections_count
    ) VALUES (
        p_user,
        p_date,
        v_total_targets,
        v_total_done,
        v_total_points,
        v_reflections_count
    )
    ON CONFLICT (user_id, for_date)
    DO UPDATE SET
        total_targets = EXCLUDED.total_targets,
        total_done = EXCLUDED.total_done,
        total_points = EXCLUDED.total_points,
        reflections_count = EXCLUDED.reflections_count;
END;
$$;

CREATE OR REPLACE FUNCTION refresh_summary_on_occ()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user UUID;
    v_date DATE;
BEGIN
    -- Get user and date from the affected row
    SELECT user_id, scheduled_date
    INTO v_user, v_date
    FROM goal_occurrences
    WHERE id = COALESCE(NEW.id, OLD.id);

    -- Refresh summary
    PERFORM refresh_daily_summary_fn(v_user, v_date);

    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_summary_on_occ
    AFTER INSERT OR UPDATE OR DELETE ON goal_occurrences
    FOR EACH ROW
    EXECUTE FUNCTION refresh_summary_on_occ();

COMMENT ON FUNCTION refresh_daily_summary_fn IS
    'Materializes daily statistics for fast history view queries';

-- ============================================================================
-- RPC: Ensure Occurrence
-- ============================================================================

CREATE OR REPLACE FUNCTION ensure_occurrence(p_goal UUID, p_date DATE)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_id UUID;
    v_goal goals%ROWTYPE;
    v_sched goal_schedules%ROWTYPE;
BEGIN
    -- Check if occurrence already exists
    SELECT id INTO v_id
    FROM goal_occurrences
    WHERE goal_id = p_goal
    AND scheduled_date = p_date;

    IF v_id IS NOT NULL THEN
        RETURN v_id;
    END IF;

    -- Get goal and schedule details
    SELECT * INTO v_goal FROM goals WHERE id = p_goal;
    SELECT * INTO v_sched FROM goal_schedules WHERE goal_id = p_goal;

    -- Create new occurrence
    INSERT INTO goal_occurrences(
        goal_id,
        user_id,
        scheduled_date,
        target_count,
        keep_until_complete,
        is_one_time,
        content_snapshot
    ) VALUES (
        p_goal,
        v_goal.user_id,
        p_date,
        v_goal.times_per_day,
        v_goal.keep_until_complete,
        (v_sched.freq = 'none'),
        jsonb_build_object(
            'title', v_goal.title,
            'emoji', v_goal.emoji,
            'points', v_goal.points_per_completion
        )
    )
    RETURNING id INTO v_id;

    -- Seed member statuses for shared goals
    INSERT INTO occurrence_member_status(occurrence_id, user_id, status, completed_count)
    SELECT v_id, m.user_id, 'pending', 0
    FROM goal_members m
    WHERE m.goal_id = p_goal;

    RETURN v_id;
END;
$$;

COMMENT ON FUNCTION ensure_occurrence IS
    'Creates an occurrence for a given goal and date if it doesn''t exist';

-- ============================================================================
-- RPC: Complete Tick
-- ============================================================================

CREATE OR REPLACE FUNCTION complete_tick(p_occ UUID, p_user UUID DEFAULT auth.uid())
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_occ goal_occurrences%ROWTYPE;
    v_goal goals%ROWTYPE;
    v_new_count INT;
    v_members_count INT;
    v_completed_members_count INT;
BEGIN
    -- Get occurrence and goal
    SELECT * INTO v_occ FROM goal_occurrences WHERE id = p_occ;
    SELECT * INTO v_goal FROM goals WHERE id = v_occ.goal_id;

    -- Log event
    INSERT INTO goal_events(occurrence_id, user_id, kind, delta)
    VALUES (p_occ, p_user, 'complete', 1);

    -- Increment occurrence completed_count
    UPDATE goal_occurrences
    SET completed_count = completed_count + 1
    WHERE id = p_occ
    RETURNING completed_count INTO v_new_count;

    -- Check if this is a shared goal
    SELECT COUNT(*) INTO v_members_count
    FROM goal_members
    WHERE goal_id = v_occ.goal_id;

    IF v_members_count > 0 THEN
        -- Update member-specific status
        INSERT INTO occurrence_member_status(occurrence_id, user_id, status, completed_count)
        VALUES (p_occ, p_user, 'pending', 1)
        ON CONFLICT (occurrence_id, user_id)
        DO UPDATE SET
            completed_count = occurrence_member_status.completed_count + 1,
            status = CASE
                WHEN occurrence_member_status.completed_count + 1 >= v_occ.target_count
                THEN 'completed'::occurrence_status
                ELSE 'pending'::occurrence_status
            END,
            updated_at = NOW();

        -- Check if ALL members have completed
        SELECT COUNT(*) INTO v_completed_members_count
        FROM occurrence_member_status ms
        WHERE ms.occurrence_id = p_occ
        AND ms.status = 'completed';

        -- If all members completed, mark occurrence completed
        IF v_completed_members_count = v_members_count THEN
            UPDATE goal_occurrences
            SET status = 'completed'
            WHERE id = p_occ;
        END IF;
    ELSE
        -- Solo goal: mark completed when threshold reached
        IF v_new_count >= v_occ.target_count THEN
            UPDATE goal_occurrences
            SET status = 'completed'
            WHERE id = p_occ;
        END IF;
    END IF;

    -- Refresh daily summary
    PERFORM refresh_daily_summary_fn(v_goal.user_id, v_occ.scheduled_date);
END;
$$;

COMMENT ON FUNCTION complete_tick IS
    'Increments completion count and marks as completed when threshold reached';

-- ============================================================================
-- RPC: Skip Occurrence
-- ============================================================================

CREATE OR REPLACE FUNCTION skip_occurrence(p_occ UUID, p_reason TEXT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_occ goal_occurrences%ROWTYPE;
    v_goal goals%ROWTYPE;
BEGIN
    -- Get occurrence and goal
    SELECT * INTO v_occ FROM goal_occurrences WHERE id = p_occ;
    SELECT * INTO v_goal FROM goals WHERE id = v_occ.goal_id;

    -- Log event
    INSERT INTO goal_events(occurrence_id, user_id, kind, delta, payload)
    VALUES (
        p_occ,
        v_goal.user_id,
        'skip',
        0,
        jsonb_build_object('reason', p_reason)
    );

    -- Mark as skipped
    UPDATE goal_occurrences
    SET status = 'skipped'
    WHERE id = p_occ;

    -- Refresh summary
    PERFORM refresh_daily_summary_fn(v_goal.user_id, v_occ.scheduled_date);
END;
$$;

COMMENT ON FUNCTION skip_occurrence IS
    'Marks an occurrence as skipped with optional reason';

-- ============================================================================
-- RPC: Rename Occurrence
-- ============================================================================

CREATE OR REPLACE FUNCTION rename_occurrence(
    p_occ UUID,
    p_name TEXT,
    p_emoji TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE goal_occurrences
    SET
        name_override = p_name,
        emoji_override = p_emoji
    WHERE id = p_occ;
END;
$$;

COMMENT ON FUNCTION rename_occurrence IS
    'Renames a specific occurrence without affecting the goal';

-- ============================================================================
-- RPC: Set Measure Target
-- ============================================================================

CREATE OR REPLACE FUNCTION set_measure_target(
    p_goal UUID,
    p_unit unit_kind,
    p_target NUMERIC,
    p_from DATE DEFAULT CURRENT_DATE
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Close previous target
    UPDATE goal_measure_targets
    SET effective_to = p_from - INTERVAL '1 day'
    WHERE goal_id = p_goal
    AND effective_to IS NULL;

    -- Insert new target
    INSERT INTO goal_measure_targets(goal_id, unit, target, effective_from)
    VALUES (p_goal, p_unit, p_target, p_from);
END;
$$;

COMMENT ON FUNCTION set_measure_target IS
    'Creates a new measure target with version history';

-- ============================================================================
-- RPC: Add Measurement
-- ============================================================================

CREATE OR REPLACE FUNCTION add_measurement(
    p_goal UUID,
    p_value NUMERIC,
    p_unit unit_kind,
    p_at TIMESTAMPTZ DEFAULT NOW()
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user UUID;
    v_id UUID;
BEGIN
    -- Get goal owner
    SELECT user_id INTO v_user FROM goals WHERE id = p_goal;

    -- Insert measurement
    INSERT INTO measurements(goal_id, user_id, value, unit, occurred_at)
    VALUES (p_goal, v_user, p_value, p_unit, p_at)
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;

COMMENT ON FUNCTION add_measurement IS
    'Records a measurement value for water/count goals';

-- ============================================================================
-- RPC: Get Daily Water Progress
-- ============================================================================

CREATE OR REPLACE FUNCTION get_water_progress(
    p_goal UUID,
    p_from DATE,
    p_to DATE
)
RETURNS TABLE(
    day DATE,
    consumed NUMERIC,
    target NUMERIC,
    unit unit_kind
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d::DATE AS day,
        COALESCE(
            (
                SELECT SUM(m.value)
                FROM measurements m
                WHERE m.goal_id = p_goal
                AND m.user_id = auth.uid()
                AND m.occurred_at::DATE = d::DATE
            ),
            0
        ) AS consumed,
        (
            SELECT t.target
            FROM goal_measure_targets t
            WHERE t.goal_id = p_goal
            AND t.effective_from <= d::DATE
            AND (t.effective_to IS NULL OR t.effective_to >= d::DATE)
            ORDER BY t.effective_from DESC
            LIMIT 1
        ) AS target,
        (
            SELECT t.unit
            FROM goal_measure_targets t
            WHERE t.goal_id = p_goal
            AND t.effective_from <= d::DATE
            AND (t.effective_to IS NULL OR t.effective_to >= d::DATE)
            ORDER BY t.effective_from DESC
            LIMIT 1
        ) AS unit
    FROM generate_series(p_from::DATE, p_to::DATE, '1 day') d
    ORDER BY day;
END;
$$;

COMMENT ON FUNCTION get_water_progress IS
    'Returns daily water consumption vs target for a date range';

-- ============================================================================
-- RPC: Get Current Streak
-- ============================================================================

CREATE OR REPLACE FUNCTION get_current_streak(p_user UUID DEFAULT auth.uid())
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_streak INT := 0;
    v_date DATE := CURRENT_DATE;
    v_has_completion BOOLEAN;
BEGIN
    LOOP
        SELECT has_completion
        INTO v_has_completion
        FROM daily_activity
        WHERE user_id = p_user
        AND day = v_date;

        -- If no activity or no completion, break
        IF v_has_completion IS NULL OR NOT v_has_completion THEN
            EXIT;
        END IF;

        v_streak := v_streak + 1;
        v_date := v_date - INTERVAL '1 day';
    END LOOP;

    RETURN v_streak;
END;
$$;

COMMENT ON FUNCTION get_current_streak IS
    'Calculates current consecutive days with at least one completion';

-- ============================================================================
-- RPC: Get Longest Streak
-- ============================================================================

CREATE OR REPLACE FUNCTION get_longest_streak(p_user UUID DEFAULT auth.uid())
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_max_streak INT := 0;
    v_current_streak INT := 0;
    v_record RECORD;
BEGIN
    FOR v_record IN
        SELECT day, has_completion
        FROM daily_activity
        WHERE user_id = p_user
        ORDER BY day ASC
    LOOP
        IF v_record.has_completion THEN
            v_current_streak := v_current_streak + 1;
            IF v_current_streak > v_max_streak THEN
                v_max_streak := v_current_streak;
            END IF;
        ELSE
            v_current_streak := 0;
        END IF;
    END LOOP;

    RETURN v_max_streak;
END;
$$;

COMMENT ON FUNCTION get_longest_streak IS
    'Calculates longest consecutive days streak across all history';

-- ============================================================================
-- RPC: Get Most Completed Goals (Last 30 Days)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_most_completed_goals(
    p_user UUID DEFAULT auth.uid(),
    p_days INT DEFAULT 30,
    p_limit INT DEFAULT 10
)
RETURNS TABLE(
    goal_id UUID,
    goal_title TEXT,
    goal_emoji TEXT,
    completion_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        g.id,
        g.title,
        g.emoji,
        COUNT(*) AS completion_count
    FROM goal_occurrences o
    JOIN goals g ON g.id = o.goal_id
    WHERE g.user_id = p_user
    AND o.scheduled_date >= CURRENT_DATE - p_days
    AND o.status = 'completed'
    GROUP BY g.id, g.title, g.emoji
    ORDER BY completion_count DESC
    LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION get_most_completed_goals IS
    'Returns top completed goals for insights view';

-- ============================================================================
-- RPC: Get Area Statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION get_area_statistics(
    p_area UUID,
    p_from DATE DEFAULT CURRENT_DATE - 30,
    p_to DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(
    total_goals INT,
    active_goals INT,
    total_completions BIGINT,
    completion_rate NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_goals INT;
    v_active_goals INT;
    v_total_scheduled BIGINT;
    v_total_completed BIGINT;
BEGIN
    -- Count goals
    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE status = 'active')
    INTO v_total_goals, v_active_goals
    FROM goals
    WHERE area_id = p_area;

    -- Count completions
    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE o.status = 'completed')
    INTO v_total_scheduled, v_total_completed
    FROM goal_occurrences o
    JOIN goals g ON g.id = o.goal_id
    WHERE g.area_id = p_area
    AND o.scheduled_date BETWEEN p_from AND p_to;

    RETURN QUERY
    SELECT
        v_total_goals,
        v_active_goals,
        v_total_completed,
        CASE
            WHEN v_total_scheduled > 0
            THEN ROUND((v_total_completed::NUMERIC / v_total_scheduled) * 100, 2)
            ELSE 0
        END;
END;
$$;

COMMENT ON FUNCTION get_area_statistics IS
    'Calculates comprehensive area metrics for a date range';

-- ============================================================================
-- RPC: Search by Hashtag
-- ============================================================================

CREATE OR REPLACE FUNCTION search_by_hashtag(p_tag TEXT)
RETURNS TABLE(
    entity_type TEXT,
    entity_id UUID,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        tg.entity_type,
        tg.entity_id,
        tg.created_at
    FROM tags t
    JOIN taggings tg ON tg.tag_id = t.id
    WHERE t.user_id = auth.uid()
    AND LOWER(t.name) = LOWER(p_tag)
    ORDER BY tg.created_at DESC;
END;
$$;

COMMENT ON FUNCTION search_by_hashtag IS
    'Finds all entities tagged with a specific hashtag';

-- ============================================================================
-- GRANT EXECUTE PERMISSIONS
-- ============================================================================

GRANT EXECUTE ON FUNCTION ensure_occurrence TO authenticated;
GRANT EXECUTE ON FUNCTION complete_tick TO authenticated;
GRANT EXECUTE ON FUNCTION skip_occurrence TO authenticated;
GRANT EXECUTE ON FUNCTION rename_occurrence TO authenticated;
GRANT EXECUTE ON FUNCTION set_measure_target TO authenticated;
GRANT EXECUTE ON FUNCTION add_measurement TO authenticated;
GRANT EXECUTE ON FUNCTION get_water_progress TO authenticated;
GRANT EXECUTE ON FUNCTION get_current_streak TO authenticated;
GRANT EXECUTE ON FUNCTION get_longest_streak TO authenticated;
GRANT EXECUTE ON FUNCTION get_most_completed_goals TO authenticated;
GRANT EXECUTE ON FUNCTION get_area_statistics TO authenticated;
GRANT EXECUTE ON FUNCTION search_by_hashtag TO authenticated;
