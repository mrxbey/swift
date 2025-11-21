-- ============================================================================
-- Migration 006: Fix Profiles Table Schema
-- ============================================================================
-- Description: Adds missing columns to profiles table to match Swift domain model
-- Author: Claude
-- Date: 2025-11-21
--
-- Changes:
--   1. Rename 'tz' column to 'timezone' for consistency with Swift model
--   2. Add avatar_url column for user profile pictures
--   3. Add week_starts_on column for calendar customization (1=Monday, 7=Sunday)
--   4. Add daily_reminder_enabled flag for notifications
--   5. Add daily_reminder_time for scheduled reminders
--   6. Add gamification columns: total_points, current_streak, longest_streak
--
-- Reason: Profile model in Swift has 12 properties but database only has 6 columns.
--         This causes JSON decoding failures when loading user profiles.
-- ============================================================================

-- Step 1: Rename 'tz' to 'timezone' for consistency with Swift model
ALTER TABLE profiles RENAME COLUMN tz TO timezone;

-- Step 2: Add missing profile columns
ALTER TABLE profiles
    ADD COLUMN IF NOT EXISTS avatar_url TEXT,
    ADD COLUMN IF NOT EXISTS week_starts_on INTEGER NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS daily_reminder_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS daily_reminder_time TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS total_points INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS current_streak INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS longest_streak INTEGER NOT NULL DEFAULT 0;

-- Step 3: Add constraints for data integrity
ALTER TABLE profiles
    ADD CONSTRAINT chk_week_starts_on CHECK (week_starts_on BETWEEN 1 AND 7),
    ADD CONSTRAINT chk_total_points CHECK (total_points >= 0),
    ADD CONSTRAINT chk_current_streak CHECK (current_streak >= 0),
    ADD CONSTRAINT chk_longest_streak CHECK (longest_streak >= 0),
    ADD CONSTRAINT chk_longest_ge_current CHECK (longest_streak >= current_streak);

-- Step 4: Add helpful comments
COMMENT ON COLUMN profiles.timezone IS 'User timezone for date calculations (e.g., UTC, America/New_York)';
COMMENT ON COLUMN profiles.avatar_url IS 'URL or path to user profile picture';
COMMENT ON COLUMN profiles.week_starts_on IS 'Day week starts on (1=Monday, 7=Sunday) per ISO 8601';
COMMENT ON COLUMN profiles.daily_reminder_enabled IS 'Whether daily reminders are enabled';
COMMENT ON COLUMN profiles.daily_reminder_time IS 'Time to send daily reminder notifications';
COMMENT ON COLUMN profiles.total_points IS 'Total gamification points earned all time';
COMMENT ON COLUMN profiles.current_streak IS 'Current consecutive days of goal completion';
COMMENT ON COLUMN profiles.longest_streak IS 'Longest streak ever achieved';

-- ============================================================================
-- Migration Complete
-- ============================================================================
-- Next Steps:
--   1. Apply this migration to your Supabase instance
--   2. Update ProfileDTO Swift model to use 'timezone' instead of 'tz'
--   3. Verify ProfileSetupFeature can save and load all fields
--   4. Test profile creation flow end-to-end
-- ============================================================================
