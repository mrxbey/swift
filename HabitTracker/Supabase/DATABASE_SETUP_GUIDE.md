# 🔴 CRITICAL: Database Not Initialized

## Problem

Your Supabase database has **NO TABLES**. The database is completely uninitialized.

This means migrations 001-004 were never run. The app will not work without the database schema.

## Root Cause

Possible reasons:
1. **New Supabase project** - Fresh project that was never set up
2. **Wrong project** - Connected to a different database than intended
3. **Database was reset** - Tables were dropped or database was recreated

## Solution: Initialize Database Now (5 minutes)

### Option 1: Quick Setup (Recommended)

Use the combined setup script for fastest initialization.

#### Steps:

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard/project/wiecalnwrmnnojkvnkym
   - Click **SQL Editor** in left sidebar
   - Click **New Query**

2. **Open the Complete Setup Script**
   ```bash
   # On your local machine
   cat HabitTracker/Supabase/COMPLETE_DATABASE_SETUP.sql
   ```

3. **Copy and Paste**
   - Copy the ENTIRE contents of `COMPLETE_DATABASE_SETUP.sql`
   - Paste into Supabase SQL Editor

4. **Run the Script**
   - Click **Run** (or press Cmd/Ctrl + Enter)
   - Wait for "Success. No rows returned" message
   - This will take 5-10 seconds

5. **Verify Success**

   Run this verification query:
   ```sql
   SELECT table_name
   FROM information_schema.tables
   WHERE table_schema = 'public'
   ORDER BY table_name;
   ```

   You should see **27 tables**:
   - areas
   - daily_activity
   - daily_recommendations
   - daily_summary
   - goal_events
   - goal_measure_targets
   - goal_members
   - goal_occurrences
   - goal_reminders
   - goal_schedules
   - goals
   - measurements
   - mood_entries
   - occurrence_member_status
   - points_ledger
   - program_items
   - programs
   - profiles
   - reflection_templates
   - reflections
   - sessions
   - taggings
   - tags
   - user_program_items
   - user_programs
   - (plus 2 audit tables: schema_migrations, supabase_migrations)

6. **Verify Enums**

   Check unit_kind enum has all values:
   ```sql
   SELECT unnest(enum_range(NULL::unit_kind)) AS unit_type;
   ```

   Expected output (9 values):
   ```
   ml
   l
   oz
   count
   min
   kg
   lb
   minutes
   hours
   ```

7. **Next Steps After Success**
   - Run migrations 003 and 004 (triggers/RPCs and performance indexes)
   - Test authentication
   - Connect your Swift app
   - Run test suite

### Option 2: Manual Migration (Step-by-Step)

If you prefer to run migrations individually:

1. **Migration 001: Initial Schema**
   ```bash
   # Copy contents of 001_initial_schema.sql
   # Paste in SQL Editor
   # Run
   ```

2. **Migration 002: RLS Policies**
   ```bash
   # Copy contents of 002_rls_policies.sql
   # Paste in SQL Editor
   # Run
   ```

3. **Migration 003: Triggers and RPCs**
   ```bash
   # Copy contents of 003_triggers_and_rpcs.sql
   # Paste in SQL Editor
   # Run
   ```

4. **Migration 004: Performance Indexes**
   ```bash
   # Copy contents of 004_performance_indexes.sql
   # Paste in SQL Editor
   # Run
   ```

5. **Migration 005: Fix UnitKind Enum**
   ```bash
   # Copy contents of 005_fix_unit_kind_enum.sql
   # Paste in SQL Editor
   # Run
   ```

## What the Setup Includes

### Database Schema (Migration 001)

**Enums:**
- `area_status`: active, paused, archived, deleted
- `goal_kind`: habit, task, measure
- `goal_status`: active, paused, archived, deleted
- `period_freq`: none, daily, weekly, monthly
- `occurrence_status`: pending, completed, skipped, missed, cancelled
- `member_role`: owner, member
- `unit_kind`: ml, l, oz, count, min, kg, lb, minutes, hours ✅ (includes migration 005 fix)
- `visibility`: private, unlisted, public

**Core Tables:**
- `profiles` - User profiles
- `areas` - Life areas (work, health, etc.)
- `goals` - User goals (habits, tasks, measured goals)
- `goal_members` - Buddy system for shared goals
- `goal_schedules` - Recurrence patterns
- `goal_reminders` - Reminder settings
- `goal_occurrences` - Daily instances of goals
- `occurrence_member_status` - Per-member completion tracking
- `goal_events` - Immutable audit log

**Measurement Tables:**
- `goal_measure_targets` - Versioned targets (e.g., change water goal from 2L to 3L)
- `measurements` - Recorded values (water intake, weight, etc.)

**Gamification:**
- `points_ledger` - Points history
- `daily_activity` - Activity tracking
- `daily_summary` - Materialized daily stats
- `daily_recommendations` - AI-generated suggestions

**Wellness Features:**
- `reflection_templates` - Guided reflection prompts
- `reflections` - User reflections
- `mood_entries` - Mood tracking
- `sessions` - Meditation, Pomodoro, etc.

**Social & Organization:**
- `tags` - User-created tags
- `taggings` - Tag associations
- `programs` - Curated programs (30-Day Meditation, etc.)
- `program_items` - Program content
- `user_programs` - User enrollments
- `user_program_items` - User progress in programs

**Sample Data:**
- 2 reflection templates (Evening Gratitude, Morning Intention)
- 2 sample programs (30-Day Meditation, Hydration Hero)

### Row Level Security (Migration 002)

**Security Features:**
- ✅ RLS enabled on all 27 tables
- ✅ Users can only access their own data
- ✅ Buddy system: members can view/complete shared goals
- ✅ Public content: reflection templates and programs
- ✅ Audit logging: immutable event history

**Performance:**
- Indexes on `user_id` columns for auth.uid() lookups
- Covering indexes for hot-path queries
- Partial indexes for filtered queries

### What's NOT Included Yet

**Still need to run separately:**
- Migration 003: Triggers and RPC functions (for advanced features)
- Migration 004: Additional performance indexes

**Why separate?**
- Keeps initial setup fast and simple
- Triggers/RPCs are for advanced features you may not need yet
- Can add later as needed

## Verification Checklist

After running the setup, verify:

- [ ] 27 tables exist in public schema
- [ ] unit_kind enum has 9 values (including kg, lb, minutes, hours)
- [ ] RLS is enabled on all tables
- [ ] Sample reflection templates exist (2 rows in reflection_templates)
- [ ] Sample programs exist (2 rows in programs)
- [ ] Can create a test user via Supabase Auth
- [ ] Can create a profile for that user
- [ ] Can create an area for that user
- [ ] Can create a goal in that area

## Testing After Setup

### 1. Test Authentication

Create a test user:
```sql
-- This will fail - use Supabase Dashboard > Authentication > Add User
-- Or use the Swift app signup flow
```

### 2. Test RLS

Try to query as unauthenticated (should return empty):
```sql
SELECT * FROM profiles;  -- Should return nothing (RLS blocks)
```

With authenticated user (should work):
```sql
-- Your Swift app will automatically be authenticated via Supabase client
```

### 3. Test Basic Workflow

Via SQL Editor (replace UUIDs with real ones):
```sql
-- 1. Create profile (after user signup)
INSERT INTO profiles (id, display_name)
VALUES ('your-user-id-from-auth', 'Test User');

-- 2. Create area
INSERT INTO areas (user_id, name, emoji)
VALUES ('your-user-id', 'Health', '💪');

-- 3. Create goal
INSERT INTO goals (user_id, area_id, title, emoji, kind)
VALUES ('your-user-id', 'area-id-from-step-2', 'Drink Water', '💧', 'measure');

-- 4. Add measurement
INSERT INTO measurements (user_id, goal_id, value, unit)
VALUES ('your-user-id', 'goal-id-from-step-3', 250, 'ml');
```

### 4. Test from Swift App

Once database is initialized:

```swift
// Test connection
let service = await SupabaseService.shared
let isConnected = try await service.testConnection()
print("Connected: \(isConnected)")

// Test creating an area
@Dependency(\.areaRepository) var areaRepository
let area = Area(userId: userId, name: "Test", emoji: "🎯")
let created = try await areaRepository.create(area)
print("Created area: \(created.name)")
```

## Troubleshooting

### Error: "relation already exists"

**Cause:** Tables partially created, script failed midway

**Fix:**
```sql
-- Drop all tables and start over
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- Then run COMPLETE_DATABASE_SETUP.sql again
```

### Error: "permission denied"

**Cause:** Using anon key instead of service role key

**Fix:**
- Make sure you're using the Supabase Dashboard SQL Editor
- SQL Editor uses service role key automatically
- Do NOT try to run DDL statements from Swift app (only anon key available)

### Error: "enum value already exists"

**Cause:** Script run multiple times

**Fix:**
- This is harmless, script is idempotent
- The `IF NOT EXISTS` clauses prevent duplicates
- Just ignore this error

### No tables visible after running script

**Cause:** Wrong schema or project

**Fix:**
1. Verify you're looking at the `public` schema
2. Check you're in the correct Supabase project
3. Verify the URL in Config.swift matches your dashboard URL

### Swift app can't connect

**Cause:** Incorrect credentials or project URL

**Fix:**
1. Check `Config.swift` has correct Supabase URL
2. Check `Config.swift` has correct anon key
3. Get latest credentials from Supabase Dashboard > Project Settings > API
4. Rebuild Swift app after updating Config.swift

## Migration History After Setup

After running COMPLETE_DATABASE_SETUP.sql, your migration status should be:

| # | File | Status | Description |
|---|------|--------|-------------|
| 001 | `initial_schema.sql` | ✅ Applied | Database schema, enums, tables |
| 002 | `rls_policies.sql` | ✅ Applied | Row Level Security policies |
| 003 | `triggers_and_rpcs.sql` | ⏳ Manual | Triggers and RPC functions (optional) |
| 004 | `performance_indexes.sql` | ⏳ Manual | Additional performance indexes (optional) |
| 005 | `fix_unit_kind_enum.sql` | ✅ Applied | Unit types already included in 001 |

## Next Steps

1. ✅ Run COMPLETE_DATABASE_SETUP.sql
2. ✅ Verify all 27 tables exist
3. ✅ Verify unit_kind enum has 9 values
4. ⏳ (Optional) Run migration 003 for triggers/RPCs
5. ⏳ (Optional) Run migration 004 for performance indexes
6. ✅ Test Swift app connection
7. ✅ Run Swift test suite
8. ✅ Test creating goals and measurements
9. ✅ Deploy to production

## Support

If you encounter issues:
1. Check Supabase logs: Dashboard > Logs > Postgres Logs
2. Verify project URL matches Config.swift
3. Try dropping and recreating public schema
4. Open GitHub issue with error details

## Files Reference

- `COMPLETE_DATABASE_SETUP.sql` - Combined setup script (recommended)
- `001_initial_schema.sql` - Individual migration (tables, enums)
- `002_rls_policies.sql` - Individual migration (security)
- `003_triggers_and_rpcs.sql` - Individual migration (advanced features)
- `004_performance_indexes.sql` - Individual migration (optimization)
- `005_fix_unit_kind_enum.sql` - Individual migration (already included in combined script)
- `MIGRATION_STATUS.md` - Migration tracking document
- `how-to-run-migrations.md` - General migration guide
- `DATABASE_SETUP_GUIDE.md` - This file

## Estimated Time

- Option 1 (Combined script): **5 minutes**
- Option 2 (Individual migrations): **10-15 minutes**
- Verification: **2 minutes**
- Testing: **5 minutes**

**Total: 10-20 minutes to full functionality**
