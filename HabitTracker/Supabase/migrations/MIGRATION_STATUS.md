# Migration Status

## ⏳ Pending Migration Required

**Migration:** `005_fix_unit_kind_enum.sql`
**Priority:** 🔴 CRITICAL
**Blocks:** Measurement feature (kg, lb, minutes, hours units)

### Why This Migration is Critical

The Swift `UnitKind` enum includes weight units (kg, lb) and time units (minutes, hours) that are missing from the database schema. Without this migration:

- ❌ Users cannot create measurements with kg or lb units
- ❌ Users cannot track time-based measurements (minutes, hours)
- ❌ The app will crash with constraint violations when attempting to use these units

### Migration SQL

```sql
-- Run this in Supabase Dashboard SQL Editor or psql

-- Add weight units
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'kg';
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'lb';

-- Add time units
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'minutes';
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'hours';
```

### Quick Start: Run Migration Now

**Fastest Method (2 minutes):**

1. Open: https://supabase.com/dashboard/project/wiecalnwrmnnojkvnkym/sql/new
2. Paste the SQL above
3. Click **Run** or press Cmd/Ctrl + Enter
4. Verify success with: `SELECT unnest(enum_range(NULL::unit_kind));`
5. Expected result: ml, l, oz, count, min, kg, lb, minutes, hours

### Verification Query

After running the migration, execute this to confirm success:

```sql
SELECT unnest(enum_range(NULL::unit_kind)) AS unit_type;
```

Expected output (9 rows):
```
 unit_type
-----------
 ml
 l
 oz
 count
 min
 kg        ← NEW
 lb        ← NEW
 minutes   ← NEW
 hours     ← NEW
```

### What Happens After Migration

The migration adds 4 new values to the existing `unit_kind` enum:

- **Safely adds values** - Existing data unaffected
- **Idempotent** - Safe to run multiple times (IF NOT EXISTS)
- **No downtime** - New values available immediately
- **Backward compatible** - Old code continues working

### Integration with Swift Code

The DTO layer handles conversion between database and Swift:

```swift
// Database 'min' ↔ Swift 'minutes' (backward compatibility)
// Database 'kg' ↔ Swift 'kg' (new)
// Database 'lb' ↔ Swift 'lb' (new)
// Database 'hours' ↔ Swift 'hours' (new)
```

See `MeasurementDTO.swift` and `GoalMeasureTargetDTO.swift` for implementation.

### Rollback

PostgreSQL does not support removing enum values once added. If rollback is needed:

1. Ensure no data uses new values
2. Create new enum without unwanted values
3. Update all columns to use new enum
4. Drop old enum

**Recommendation:** Verify on test database first, but this migration is safe for production.

### Current Schema vs. Required Schema

| Unit Type | Database (Current) | Swift Model | Status |
|-----------|-------------------|-------------|---------|
| ml | ✅ Exists | ✅ Defined | ✅ Working |
| l | ✅ Exists | ✅ Defined | ✅ Working |
| oz | ✅ Exists | ✅ Defined | ✅ Working |
| count | ✅ Exists | ✅ Defined | ✅ Working |
| min | ✅ Exists | ⚠️ Maps to .minutes | ✅ Working (with DTO conversion) |
| kg | ❌ Missing | ✅ Defined | ❌ **BROKEN** |
| lb | ❌ Missing | ✅ Defined | ❌ **BROKEN** |
| minutes | ❌ Missing | ✅ Defined | ⚠️ Uses 'min' via DTO |
| hours | ❌ Missing | ✅ Defined | ❌ **BROKEN** |

### Migration History

| # | File | Status | Applied | Description |
|---|------|--------|---------|-------------|
| 001 | `initial_schema.sql` | ✅ | Unknown | Initial database schema with tables, enums, constraints |
| 002 | `rls_policies.sql` | ✅ | Unknown | Row Level Security policies for multi-tenancy |
| 003 | `triggers_and_rpcs.sql` | ✅ | Unknown | Database triggers (updated_at) and RPC functions |
| 004 | `performance_indexes.sql` | ✅ | Unknown | Indexes for query optimization |
| **005** | `fix_unit_kind_enum.sql` | **⏳ PENDING** | **NOT YET** | **Fix UnitKind enum mismatch (Bug #1)** |

### Dependencies

**This migration must be applied before:**
- ✅ Testing measurement features with kg/lb/hours
- ✅ Running full test suite (some tests may fail without it)
- ✅ Deploying to production
- ✅ User acceptance testing

**Safe to apply:**
- ✅ During development
- ✅ During staging/testing
- ✅ During production (zero downtime)

---

## 📋 Action Required

**Human intervention needed** - This migration cannot be applied automatically because:

1. ❌ Supabase CLI not installed in this environment
2. ❌ Direct database credentials not available (only anon key)
3. ✅ Migration SQL prepared and validated
4. ✅ Instructions documented above

**Next step:** Run the migration manually using Supabase Dashboard SQL Editor (see Quick Start above).

**After migration:** Update this file to mark migration 005 as ✅ Applied with timestamp.
