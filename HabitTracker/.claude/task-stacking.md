# Task Stacking - Critical Bug Fixes

**Status**: In Progress
**Start Date**: 2025-11-18
**Estimated Completion**: 1 business day (6-9 hours)
**Confidence Target**: 95%+ for each task before applying fix

---

## Overview

Systematic plan to fix all 5 bugs identified in the codebase audit. Each task includes research, validation, confidence check, implementation, and testing phases.

---

## 🔴 TASK 1: Fix UnitKind Schema Mismatch (CRITICAL)

**Priority**: HIGHEST - Blocks entire measurement feature
**Estimated Time**: 2-3 hours
**Confidence**: 0% → Target: 95%+

### Problem Summary
Database schema has: `'ml', 'l', 'oz', 'count', 'min'`
Swift enum has: `count, ml, l, oz, kg, lb, minutes, hours`

**Missing in DB**: kg, lb, minutes, hours
**Mismatch**: DB has 'min' but Swift expects 'minutes'

### Subtasks

#### 1.1 Research Phase ✓
- [ ] Read current database schema (001_initial_schema.sql)
- [ ] Verify current Swift UnitKind enum definition
- [ ] Check all usages of UnitKind in codebase
- [ ] Search for any hardcoded unit strings
- [ ] Check PostgreSQL enum documentation for ALTER TYPE syntax
- [ ] Verify if Supabase has any restrictions on enum modifications

**Validation Criteria**:
- Understand all unit types used in app
- Confirm migration approach is safe
- Verify no breaking changes to existing data

#### 1.2 Design Solution ✓
- [ ] Decide: Add to database OR change Swift enum
- [ ] Design migration script
- [ ] Plan rollback strategy
- [ ] Document why this approach is chosen

**Decision Matrix**:
- Option A: Add kg, lb, minutes, hours to database (RECOMMENDED)
  - Pros: Supports user needs, no Swift changes
  - Cons: Database migration required
- Option B: Remove kg, lb, minutes, hours from Swift
  - Pros: No migration
  - Cons: Limits user features (BAD)

**Chosen**: Option A - Add to database

#### 1.3 Create Migration Script ✓
- [ ] Create `002_fix_unit_kind_enum.sql`
- [ ] Add ALTER TYPE statements for each missing unit
- [ ] Add validation checks
- [ ] Test migration on sample database
- [ ] Document migration in README

**Migration Script Template**:
```sql
-- Migration: 002_fix_unit_kind_enum.sql
-- Purpose: Add missing unit types to support all measurement features
-- Date: 2025-11-18

-- Add weight units
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'kg';
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'lb';

-- Add time units
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'minutes';
ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'hours';

-- Note: 'min' in database maps to 'minutes' in Swift (DTO handles conversion)
```

#### 1.4 Handle 'min' vs 'minutes' Mismatch ✓
- [ ] Check MeasurementDTO conversion logic
- [ ] Verify DTO handles 'min' ↔ 'minutes' correctly
- [ ] Update DTO if needed to map values
- [ ] Add tests for this conversion

**Conversion Strategy**:
```swift
// In MeasurementDTO
public init(from measurement: Measurement) {
    // Convert Swift 'minutes' to DB 'min' if needed
    let dbUnit = measurement.unit == .minutes ? "min" : measurement.unit.rawValue
    self.unit = dbUnit
}

public var toDomain: Measurement {
    // Convert DB 'min' to Swift 'minutes'
    let swiftUnit = unit == "min" ? .minutes : UnitKind(rawValue: unit) ?? .count
    // ...
}
```

#### 1.5 Update Tests ✓
- [ ] Update SupabaseMeasurementRepositoryTests to test all units
- [ ] Verify TestFixtures.makeMeasurement supports all units
- [ ] Add specific tests for kg, lb, minutes, hours
- [ ] Test 'min' ↔ 'minutes' conversion

#### 1.6 Confidence Check
- [ ] 95%+ confident migration is safe
- [ ] Verified no data loss
- [ ] Tested on sample data
- [ ] Rollback plan documented

#### 1.7 Apply Fix ✓
- [ ] Create migration file
- [ ] Update MeasurementDTO if needed
- [ ] Update tests
- [ ] Commit changes
- [ ] Run migration on dev database

#### 1.8 Testing ✓
- [ ] Run full test suite
- [ ] Create measurement with kg
- [ ] Create measurement with lb
- [ ] Create measurement with minutes
- [ ] Create measurement with hours
- [ ] Verify sync to database works
- [ ] Check database enum values

**Success Criteria**: All tests pass, all unit types work

---

## 🔴 TASK 2: Fix SyncEngine SwiftData Mutations (CRITICAL)

**Priority**: HIGH - Data corruption risk
**Estimated Time**: 1-2 hours
**Confidence**: 0% → Target: 95%+

### Problem Summary
SyncEngine directly mutates SwiftData model properties outside ModelContext, violating thread-safety.

**Locations**:
- Line 84: `cached.syncState = SyncState.synced.rawValue`
- Line 85: `cached.lastSyncedAt = Date()`
- Lines 89, 108, 112, 131, 135, 154, 158: Similar mutations

### Subtasks

#### 2.1 Research Phase ✓
- [ ] Read SwiftData documentation on thread-safety
- [ ] Review SyncEngine.swift completely
- [ ] Check CacheService methods for proper ModelContext usage
- [ ] Verify @MainActor annotations are correct
- [ ] Search for all instances of direct mutation

**Research Questions**:
- Why are models being mutated directly?
- Is there a reason for this pattern?
- Are mutations redundant with subsequent save calls?

#### 2.2 Analyze Current Flow ✓
```swift
// Current (WRONG):
cached.syncState = SyncState.synced.rawValue  // ❌ Direct mutation
cached.lastSyncedAt = Date()                  // ❌ Direct mutation
try cacheService.saveArea(area, syncState: .synced)  // Then saves again

// This is:
// 1. Mutating outside ModelContext (unsafe)
// 2. Redundant (save will update anyway)
// 3. Creates race condition potential
```

#### 2.3 Design Solution ✓
**Approach**: Remove all direct mutations, use only CacheService

**New Flow**:
```swift
// Correct:
try cacheService.saveArea(area, syncState: .synced)  // ✅ Only this
```

**Rationale**:
- CacheService properly manages ModelContext
- No direct mutation of SwiftData models
- Thread-safe by design
- Simpler code

#### 2.4 Identify All Mutation Points ✓
- [ ] uploadPendingAreas(): Lines 84-85, 89
- [ ] uploadPendingGoals(): Lines 108, 112
- [ ] uploadPendingOccurrences(): Lines 131, 135
- [ ] uploadPendingMeasurements(): Lines 154, 158

Total: 8 mutation points to remove

#### 2.5 Plan Refactor ✓
For each upload method:
```swift
// Before:
for cached in pending {
    do {
        let entity = cached.toDomain()
        let dto = DTO(from: entity)
        try await client.from("table").upsert(dto).execute()

        cached.syncState = SyncState.synced.rawValue  // ❌ Remove
        cached.lastSyncedAt = Date()                  // ❌ Remove
        try cacheService.save(entity, syncState: .synced)
    } catch {
        cached.syncState = SyncState.failed.rawValue  // ❌ Remove
    }
}

// After:
for cached in pending {
    do {
        let entity = cached.toDomain()
        let dto = DTO(from: entity)
        try await client.from("table").upsert(dto).execute()

        // ✅ Only this
        try cacheService.save(entity, syncState: .synced)
    } catch {
        // ✅ Update through CacheService on failure too
        let failedEntity = cached.toDomain()
        try? cacheService.save(failedEntity, syncState: .failed)
        print("Failed to sync: \(error)")
    }
}
```

#### 2.6 Confidence Check
- [ ] 95%+ confident this won't break sync
- [ ] Verified CacheService handles state correctly
- [ ] No regressions in sync behavior
- [ ] Thread-safety improved

#### 2.7 Apply Fix ✓
- [ ] Update uploadPendingAreas()
- [ ] Update uploadPendingGoals()
- [ ] Update uploadPendingOccurrences()
- [ ] Update uploadPendingMeasurements()
- [ ] Remove all direct mutations
- [ ] Commit changes

#### 2.8 Testing ✓
- [ ] Run test suite
- [ ] Test sync when online
- [ ] Test sync when offline → online
- [ ] Verify pending state transitions
- [ ] Check failed state handling
- [ ] Verify no crashes

**Success Criteria**: Sync works correctly, no thread-safety violations

---

## 🔴 TASK 3: Fix Force-Unwrap in Repositories (CRITICAL)

**Priority**: HIGH - Crash risk on startup
**Estimated Time**: 1-2 hours
**Confidence**: 0% → Target: 95%+

### Problem Summary
All 4 repository convenience initializers use `try!` which will crash if CacheService fails.

**Locations**:
- SupabaseAreaRepository.swift:31
- SupabaseGoalRepository.swift:30
- SupabaseOccurrenceRepository.swift:30
- SupabaseMeasurementRepository.swift:30

### Subtasks

#### 3.1 Research Phase ✓
- [ ] Check Swift async initializer documentation
- [ ] Review CacheService initialization
- [ ] Check what errors CacheService can throw
- [ ] See if other repos use throwing init pattern
- [ ] Check dependency injection patterns

**Research Questions**:
- Can Swift async init throw?
- What happens if CacheService init fails?
- How should we handle this gracefully?

#### 3.2 Analyze Impact ✓
**Scenarios where CacheService init fails**:
1. Disk full
2. Permission denied
3. Database corruption
4. SwiftData version incompatibility

**Current behavior**: App crashes immediately
**Desired behavior**: Graceful error handling or fallback

#### 3.3 Design Solution ✓
**Option A: Throwing Initializer** (RECOMMENDED)
```swift
public init() async throws {
    self.client = await SupabaseService.shared.getClient()
    let sharedCache = try CacheService()  // ✅ Propagate error
    self.cacheService = sharedCache
    self.networkMonitor = NetworkMonitor()
    self.syncEngine = SyncEngine(
        cacheService: sharedCache,
        supabaseClient: await SupabaseService.shared.getClient()
    )
}
```

**Pros**: Clean error propagation, caller handles error
**Cons**: Callers must use try await Repository()

**Option B: In-Memory Fallback**
```swift
public init() async {
    self.client = await SupabaseService.shared.getClient()

    do {
        let sharedCache = try CacheService()
        self.cacheService = sharedCache
    } catch {
        // Fallback to in-memory only
        let inMemoryCache = try! CacheService(inMemoryOnly: true)
        self.cacheService = inMemoryCache
    }
    // ...
}
```

**Pros**: Never crashes, degrades gracefully
**Cons**: Requires CacheService to support in-memory mode

**Decision**: Option A - Throwing initializer (cleaner, more explicit)

#### 3.4 Check Callers ✓
- [ ] Find all places where repositories are initialized
- [ ] Verify callers can handle throws
- [ ] Update call sites if needed

#### 3.5 Confidence Check
- [ ] 95%+ confident this won't break existing code
- [ ] Verified all callers can handle errors
- [ ] Error handling is appropriate

#### 3.6 Apply Fix ✓
- [ ] Update SupabaseAreaRepository init
- [ ] Update SupabaseGoalRepository init
- [ ] Update SupabaseOccurrenceRepository init
- [ ] Update SupabaseMeasurementRepository init
- [ ] Update any callers to handle errors
- [ ] Commit changes

#### 3.7 Testing ✓
- [ ] Run test suite
- [ ] Test normal initialization
- [ ] Test with simulated disk full (if possible)
- [ ] Verify error propagation
- [ ] Check no crashes

**Success Criteria**: No force-unwraps, proper error handling

---

## 🟡 TASK 4: Fix TestFixtures Invalid Kind (HIGH)

**Priority**: MEDIUM - Test correctness
**Estimated Time**: 30 minutes
**Confidence**: 0% → Target: 95%+

### Problem Summary
TestFixtures uses "tick" as default kind, but valid values are "habit", "task", "measure".

**Location**: TestFixtures.swift:107

### Subtasks

#### 4.1 Research Phase ✓
- [ ] Verify valid GoalKind enum values
- [ ] Check database schema for goal_kind
- [ ] Search for any other uses of "tick"
- [ ] Review GoalDTO conversion logic

#### 4.2 Verify Fix ✓
**Current**:
```swift
kind: String = "tick",  // ❌ Invalid
```

**Fixed**:
```swift
kind: String = "habit",  // ✅ Valid default
```

#### 4.3 Search for "tick" Usage ✓
- [ ] Grep codebase for "tick"
- [ ] Check if "tick" is used elsewhere
- [ ] Verify this is the only instance

#### 4.4 Confidence Check
- [ ] 95%+ confident "habit" is correct default
- [ ] No other "tick" references found

#### 4.5 Apply Fix ✓
- [ ] Change "tick" to "habit"
- [ ] Commit change

#### 4.6 Testing ✓
- [ ] Run DTO tests
- [ ] Verify GoalDTO conversion tests pass
- [ ] Check round-trip conversion

**Success Criteria**: All GoalDTO tests pass

---

## 🟢 TASK 5: Fix MARK Comments (MEDIUM)

**Priority**: LOW - Code organization
**Estimated Time**: 15 minutes
**Confidence**: 100% (simple find/replace)

### Problem Summary
Multiple files use `/ MARK:` instead of `// MARK:`, breaking IDE navigation.

**Locations**: 10+ files

### Subtasks

#### 5.1 Find All Instances ✓
- [ ] Grep for "/ MARK:"
- [ ] Count total instances
- [ ] List affected files

#### 5.2 Apply Fix ✓
- [ ] Global find/replace: `/ MARK:` → `// MARK:`
- [ ] Verify changes
- [ ] Commit

#### 5.3 Testing ✓
- [ ] Verify IDE jump bar works
- [ ] Check code folding

**Success Criteria**: All MARK comments properly formatted

---

## 🧪 TASK 6: Full Test Suite Validation

**Priority**: CRITICAL - Verify all fixes
**Estimated Time**: 30 minutes
**Confidence**: Will achieve 100%

### Subtasks

#### 6.1 Run Full Test Suite ✓
```bash
cd HabitTracker
swift test --verbose
```

#### 6.2 Verify Results ✓
- [ ] All DTO tests pass
- [ ] All Cache tests pass
- [ ] All Repository tests pass
- [ ] No new failures introduced
- [ ] Coverage maintained at 90%+

#### 6.3 Manual Testing ✓
- [ ] Create measurement with each new unit type
- [ ] Test sync flow
- [ ] Test offline operations
- [ ] Verify repository initialization
- [ ] Check IDE navigation with MARK comments

#### 6.4 Performance Check ✓
- [ ] Test suite runs in reasonable time
- [ ] No significant performance degradation

---

## 📋 Execution Checklist

### Pre-Execution
- [x] Audit findings documented
- [x] Task stacking plan created
- [ ] Confidence targets set (95%+)
- [ ] Rollback strategy documented

### During Execution (Per Task)
- [ ] Research phase complete
- [ ] Solution designed
- [ ] Confidence check passed (95%+)
- [ ] Fix applied
- [ ] Tests run and passed
- [ ] Changes committed

### Post-Execution
- [ ] All 5 bugs fixed
- [ ] Full test suite passes
- [ ] Manual testing complete
- [ ] Documentation updated
- [ ] Changes pushed to remote

---

## 📊 Progress Tracking

### Task Status
- [ ] Task 1: UnitKind Schema (0% → 95%+)
- [ ] Task 2: SyncEngine Mutations (0% → 95%+)
- [ ] Task 3: Force-Unwraps (0% → 95%+)
- [ ] Task 4: TestFixtures (0% → 95%+)
- [ ] Task 5: MARK Comments (0% → 100%)
- [ ] Task 6: Full Testing (0% → 100%)

### Overall Progress: 0% Complete

### Time Tracking
- Estimated: 6-9 hours
- Actual: TBD
- Variance: TBD

---

## 🎯 Success Criteria

### Must Have (Blockers)
✅ All 3 critical bugs fixed (UnitKind, SyncEngine, Force-Unwraps)
✅ All tests pass (170+ tests, 0 failures)
✅ No regressions introduced
✅ Code compiles without errors

### Should Have (Important)
✅ TestFixtures bug fixed
✅ MARK comments fixed
✅ 95%+ confidence achieved for each task
✅ Manual testing complete

### Nice to Have (Optional)
✅ Performance maintained or improved
✅ Code coverage maintained at 90%+
✅ Documentation updated

---

## 🚨 Risk Mitigation

### Risk 1: Database Migration Fails
**Mitigation**: Test migration on sample database first, have rollback script ready

### Risk 2: Tests Fail After SyncEngine Fix
**Mitigation**: Run tests after each change, revert if issues found

### Risk 3: Repository Callers Don't Handle Throws
**Mitigation**: Identify all callers first, update before changing repos

### Risk 4: Time Overrun
**Mitigation**: Focus on critical bugs first (1, 2, 3), defer 4 and 5 if needed

---

## 📝 Notes and Decisions

### Decision Log
- **2025-11-18**: Chose to add units to database rather than remove from Swift (preserves features)
- **2025-11-18**: Chose throwing initializer over in-memory fallback (cleaner error handling)
- **2025-11-18**: Decided to fix all bugs in one session for atomic fix

### Lessons Learned
- TBD (will update during execution)

### Open Questions
- TBD (will update during execution)

---

**Next Action**: Begin Task 1 - Research Phase for UnitKind Schema Fix
