-- HabitTracker Database Schema
-- Migration 002: Fix unit_kind Enum to Match Swift Model
-- Created: 2025-11-18
-- Purpose: Add missing unit types (kg, lb, minutes, hours) to support all measurement features

-- ============================================================================
-- PROBLEM STATEMENT
-- ============================================================================
-- The Swift UnitKind enum includes weight units (kg, lb) and time units
-- (minutes, hours) that were missing from the original database schema.
-- This causes constraint violations when users try to create measurements
-- with these unit types.
--
-- Original enum: ('ml', 'l', 'oz', 'count', 'min')
-- Required enum: ('ml', 'l', 'oz', 'count', 'min', 'kg', 'lb', 'hours')

-- ============================================================================
-- ENUM MODIFICATIONS
-- ============================================================================

-- Add weight units for body weight tracking, ingredient measurements, etc.
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'kg';
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'lb';

-- Add time unit for activity duration tracking
-- Note: 'min' already exists in database and is the canonical value for minutes.
--       Swift .minutes enum case maps to database 'min' via DTO conversion.
--       DO NOT add 'minutes' as it would create ambiguity with 'min'.
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'hours';

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- After running this migration, verify with:
-- SELECT unnest(enum_range(NULL::unit_kind));
--
-- Expected output:
-- ml
-- l
-- oz
-- count
-- min
-- kg
-- lb
-- hours

-- ============================================================================
-- ROLLBACK STRATEGY
-- ============================================================================
-- Note: PostgreSQL does not support removing enum values once added.
-- If rollback is required, you would need to:
-- 1. Ensure no data uses the new values
-- 2. Rename the old enum type
-- 3. Create a new enum type without the new values
-- 4. Update all columns to use the new type
-- 5. Drop the old enum type
--
-- This is complex and should be avoided. Instead, verify this migration
-- on a test database before applying to production.

-- ============================================================================
-- SAFETY NOTES
-- ============================================================================
-- - ALTER TYPE ADD VALUE is safe and does not affect existing data
-- - IF NOT EXISTS makes this migration idempotent (safe to run multiple times)
-- - New values are added at the end of the enum (order doesn't matter for our use case)
-- - No transaction conflicts as we're only adding values, not modifying/deleting
