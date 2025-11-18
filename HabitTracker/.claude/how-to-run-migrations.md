# How to Run Database Migrations

## Current Migration Status

**Pending Migration:** `005_fix_unit_kind_enum.sql`

This migration adds missing unit types (kg, lb, minutes, hours) to the PostgreSQL `unit_kind` enum to support all measurement features.

## Migration File Location

```
HabitTracker/Supabase/migrations/005_fix_unit_kind_enum.sql
```

## Option 1: Supabase Dashboard (Recommended)

This is the easiest and safest method for applying migrations.

### Steps:

1. Go to your Supabase project dashboard: https://supabase.com/dashboard/project/wiecalnwrmnnojkvnkym

2. Navigate to **SQL Editor** in the left sidebar

3. Click **New Query**

4. Copy and paste the contents of `005_fix_unit_kind_enum.sql`:

```sql
-- Add weight units for body weight tracking, ingredient measurements, etc.
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'kg';
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'lb';

-- Add time units for activity duration tracking
-- Note: 'min' already exists in database, maps to 'minutes' in Swift via DTO conversion
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'minutes';
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'hours';
```

5. Click **Run** (or press Cmd/Ctrl + Enter)

6. Verify the migration succeeded by running this query:

```sql
SELECT unnest(enum_range(NULL::unit_kind));
```

Expected output:
- ml
- l
- oz
- count
- min
- kg
- lb
- minutes
- hours

## Option 2: PostgreSQL psql Client

If you have direct database access credentials:

### Steps:

1. Get your database password from Supabase Dashboard:
   - Go to Project Settings > Database
   - Copy the connection string or password

2. Connect to your database:

```bash
psql "postgresql://postgres:[YOUR-PASSWORD]@db.wiecalnwrmnnojkvnkym.supabase.co:5432/postgres"
```

3. Run the migration file:

```bash
\i HabitTracker/Supabase/migrations/005_fix_unit_kind_enum.sql
```

Or copy and paste the SQL directly:

```sql
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'kg';
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'lb';
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'minutes';
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'hours';
```

4. Verify:

```sql
SELECT unnest(enum_range(NULL::unit_kind));
```

5. Exit:

```
\q
```

## Option 3: Supabase CLI (If Installed)

If you have Supabase CLI installed locally:

```bash
# Navigate to project directory
cd /home/user/swift/HabitTracker

# Link to your remote project (first time only)
supabase link --project-ref wiecalnwrmnnojkvnkym

# Push migration to remote
supabase db push

# Or apply specific migration
supabase db push --include-all
```

## Verification

After running the migration, verify it worked:

### Method 1: SQL Query

Run this in SQL Editor or psql:

```sql
SELECT unnest(enum_range(NULL::unit_kind)) AS unit_type;
```

You should see all 9 unit types listed.

### Method 2: Test in Swift

Try creating a measurement with the new unit types:

```swift
let measurement = Measurement(
    userId: userId,
    goalId: goalId,
    value: 70.5,
    unit: .kg  // New unit type
)
```

## Troubleshooting

### Error: "type already exists"

This is safe to ignore. The migration uses `IF NOT EXISTS` to make it idempotent.

### Error: "permission denied"

Make sure you're using credentials with ALTER permission. The anon key from Config.swift is for client-side operations only and cannot run DDL statements.

### Error: "cannot run inside a transaction block"

Some PostgreSQL versions don't allow `ALTER TYPE ADD VALUE` inside transactions. Run the migration outside of a transaction or one statement at a time.

## Migration History

| Number | File | Status | Description |
|--------|------|--------|-------------|
| 001 | initial_schema.sql | ✅ Applied | Initial database schema |
| 002 | rls_policies.sql | ✅ Applied | Row Level Security policies |
| 003 | triggers_and_rpcs.sql | ✅ Applied | Database triggers and functions |
| 004 | performance_indexes.sql | ✅ Applied | Performance optimization indexes |
| 005 | fix_unit_kind_enum.sql | ⏳ Pending | Fix UnitKind enum (Bug #1) |

## Next Steps After Migration

1. ✅ Verify migration succeeded (see Verification section)
2. Run test suite to ensure no regressions
3. Test measurement creation with new unit types (kg, lb, minutes, hours)
4. Verify DTO conversion works correctly ('min' ↔ 'minutes')
5. Update migration status in this document
