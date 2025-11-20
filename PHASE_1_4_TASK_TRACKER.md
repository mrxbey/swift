# PHASE 1-4 COMPREHENSIVE TASK TRACKER
## HabitTracker Bug Fix & Feature Implementation

**Created:** November 20, 2025
**Session ID:** claude/audit-context-files-01UVD2KSgx3pZUhq4UW9qAHT
**Based On:** COMPREHENSIVE_APP_AUDIT_REPORT.md + AUDIT_ACTION_PLAN.md
**Status:** In Progress

---

## CONTEXT PRESERVATION

### What We Know
- **Total Issues:** 17 (10 Critical, 3 High, 2 Medium, 2 Low)
- **Codebase:** 59 Swift files, ~14,177 LOC
- **Architecture:** Clean Architecture (4 layers)
- **Current Build Status:** ✅ Zero compilation errors (but critical runtime bugs exist)
- **Current Grade:** B+ (85/100)

### Critical Constraints
- NO database migration files found in repository
- Must verify database schema before fixing model mismatches
- Cannot assume database structure - must check actual Supabase schema
- Enterprise quality required - no quick hacks

### Success Criteria
- [ ] All 10 CRITICAL bugs verified and fixed
- [ ] Zero compilation errors maintained
- [ ] Zero runtime crashes in testing
- [ ] All fixes tested and validated
- [ ] Documentation updated

---

## PHASE 1: CRITICAL BUG FIXES (Week 1)
**Priority:** P0 - MUST FIX BEFORE RELEASE
**Estimated Time:** 8 hours
**Target Completion:** End of Week 1

### Overview
Fix 8 critical bugs that cause immediate runtime failures. Each bug will be:
1. **Deep Audited** - Verify bug actually exists
2. **Root Cause Analyzed** - Understand why it exists
3. **Solution Designed** - Enterprise-quality fix
4. **Implemented** - Write the code
5. **Tested** - Verify fix works
6. **Documented** - Update docs

---

### 🔴 BUG #1: Measurement Field Mismatch (recordedAt vs occurred_at)

**Status:** ⏳ PENDING AUDIT
**Estimated Time:** 30 minutes
**Assignee:** Backend Dev + iOS Dev

#### Bug Description
- **Claim:** MeasurementDTO maps `recordedAt` to `recorded_at` but database has `occurred_at`
- **Impact:** Water tracking completely broken - cannot load measurements
- **Files:**
  - `Domain/Models/Measurement.swift:15` (property: recordedAt)
  - `Data/DTOs/MeasurementDTO.swift:26` (CodingKey: recorded_at)

#### Audit Checklist
- [ ] Read Measurement.swift - confirm property name
- [ ] Read MeasurementDTO.swift - confirm CodingKey mapping
- [ ] Check if database migration files exist (already know: NO)
- [ ] Search codebase for "occurred_at" references
- [ ] Search codebase for "recorded_at" references
- [ ] Verify SupabaseMeasurementRepository queries
- [ ] Determine actual database column name

#### Root Cause Analysis
_To be filled after audit_

#### Solution Design
_To be filled after audit_

#### Implementation Steps
_To be filled after solution design_

#### Test Plan
- [ ] Create test measurement
- [ ] Verify saves without error
- [ ] Verify loads without decoding error
- [ ] Verify displays correct timestamp

#### Pass Conditions
- [ ] Measurement DTO maps to correct database column
- [ ] Water tracking saves measurements successfully
- [ ] No decoding errors when loading measurements
- [ ] All tests pass

#### Deliverables
- [ ] Fixed MeasurementDTO.swift
- [ ] Unit tests for Measurement DTO mapping
- [ ] Updated documentation

---

### 🔴 BUG #2: GoalStatus Missing .completed Case

**Status:** ⏳ PENDING AUDIT
**Estimated Time:** 1 hour
**Assignee:** iOS Dev

#### Bug Description
- **Claim:** GoalStatus enum missing `.completed` case but SupabaseGoalRepository uses it
- **Impact:** Compilation error or runtime crash when calling complete()
- **Files:**
  - `Domain/Models/Goal.swift:120-138` (GoalStatus enum)
  - `Data/Repositories/Supabase/SupabaseGoalRepository.swift:328-369` (complete() method)

#### Audit Checklist
- [ ] Read Goal.swift - verify GoalStatus cases
- [ ] Read SupabaseGoalRepository.swift - find complete() method
- [ ] Check if complete() actually sets status to .completed
- [ ] Search codebase for all .completed references
- [ ] Verify database enum has 'completed' value
- [ ] Check if complete() method is actually used anywhere
- [ ] Determine if goals should have completed status (or just occurrences)

#### Root Cause Analysis
_To be filled after audit_

#### Solution Design
**Option A:** Remove complete() method (goals don't complete, occurrences do)
**Option B:** Add .completed case to enum + database migration

_Decision to be made after audit_

#### Implementation Steps
_To be filled after solution design_

#### Test Plan
- [ ] Verify no compilation errors
- [ ] Test goal lifecycle (create → active → paused → archived)
- [ ] Verify occurrences handle completion
- [ ] All repository tests pass

#### Pass Conditions
- [ ] Zero compilation errors
- [ ] Goal completion logic removed or properly implemented
- [ ] Database enum matches Swift enum (if using Option B)
- [ ] All tests pass

#### Deliverables
- [ ] Fixed Goal.swift OR SupabaseGoalRepository.swift
- [ ] Database migration (if Option B)
- [ ] Updated tests
- [ ] Updated documentation

---

### 🔴 BUG #3: Profile Model/Database Schema Mismatch

**Status:** ⏳ PENDING AUDIT
**Estimated Time:** 2 hours
**Assignee:** Full Stack

#### Bug Description
- **Claim:** Profile model has 9 fields that may not exist in database
- **Impact:** Cannot save/load user profiles - ProfileSetupFeature broken
- **Files:**
  - `Domain/Models/Profile.swift:10-17` (12 properties)
  - `Data/DTOs/ProfileDTO.swift:8-18` (12 properties)

#### Suspected Missing Fields
- avatarURL (maps to avatar_url)
- weekStartsOn (maps to week_starts_on)
- dailyReminderEnabled (maps to daily_reminder_enabled)
- dailyReminderTime (maps to daily_reminder_time)
- totalPoints (maps to total_points)
- currentStreak (maps to current_streak)
- longestStreak (maps to longest_streak)

#### Audit Checklist
- [ ] Read Profile.swift - list all properties
- [ ] Read ProfileDTO.swift - list all CodingKeys
- [ ] Search codebase for database schema references
- [ ] Check ProfileSetupFeature - what fields does it save?
- [ ] Search for any Supabase profile queries
- [ ] **CRITICAL:** Need actual database schema verification
- [ ] Check if ProfileRepository exists (audit found: NO)

#### Root Cause Analysis
_To be filled after audit - CANNOT COMPLETE without database access_

#### Solution Design
**Cannot finalize without database schema verification**

**Option A:** Database has all fields → No fix needed
**Option B:** Database missing fields → Create migration to add them
**Option C:** Redesign Profile model to match actual schema

_Decision requires database access_

#### Implementation Steps
_To be filled after database verification_

#### Test Plan
- [ ] Create new profile
- [ ] Save all fields
- [ ] Load profile
- [ ] Verify all fields present
- [ ] Profile setup flow works end-to-end

#### Pass Conditions
- [ ] Profile model matches database schema exactly
- [ ] ProfileDTO maps all fields correctly
- [ ] Profile setup flow works without errors
- [ ] No decoding errors

#### Deliverables
- [ ] Fixed Profile.swift (if needed)
- [ ] Fixed ProfileDTO.swift (if needed)
- [ ] Database migration (if needed)
- [ ] Updated tests
- [ ] Documentation

#### ⚠️ BLOCKER
**This bug CANNOT be fully fixed without database schema access.**
**Action:** Document required verification steps for team with DB access.

---

### 🔴 BUG #4: UnitKind Enum Database Type Mismatch

**Status:** ⏳ PENDING AUDIT
**Estimated Time:** 1 hour
**Assignee:** Backend Dev

#### Bug Description
- **Claim:** Swift UnitKind has 8 cases but database enum missing 4 values
- **Impact:** Cannot save measurements with kg, lb, minutes, hours
- **Files:**
  - `Domain/Models/Measurement.swift:61-95` (UnitKind enum)
  - `Data/DTOs/MeasurementDTO.swift:45-51` (minutes ↔ min conversion)

#### Suspected Issues
- Swift has: count, ml, l, oz, kg, lb, minutes, hours
- Database may have: ml, l, oz, count, min
- Missing: kg, lb, hours (and minutes maps to min)

#### Audit Checklist
- [ ] Read Measurement.swift - list all UnitKind cases
- [ ] Read MeasurementDTO.swift - check conversion logic
- [ ] Search for unit_kind references in codebase
- [ ] Verify MeasurementDTO handles minutes ↔ min conversion
- [ ] **CRITICAL:** Need database enum verification
- [ ] Check if kg/lb/hours are actually used anywhere

#### Root Cause Analysis
_To be filled after audit_

#### Solution Design
_Depends on database verification_

#### Implementation Steps
_To be filled after solution design_

#### Test Plan
- [ ] Create measurement with each unit type (all 8)
- [ ] Verify all save successfully
- [ ] Verify all load correctly
- [ ] Verify unit displayed correctly

#### Pass Conditions
- [ ] Database enum has all required values OR
- [ ] DTO properly converts all units to database equivalents
- [ ] All unit types work in app
- [ ] No constraint violations

#### Deliverables
- [ ] Database migration (if needed)
- [ ] Updated MeasurementDTO (if needed)
- [ ] Tests for all unit types
- [ ] Documentation

---

### 🔴 BUG #5: Non-Existent scheduleId in GoalOccurrenceDTO

**Status:** ⏳ PENDING AUDIT
**Estimated Time:** 30 minutes
**Assignee:** iOS Dev

#### Bug Description
- **Claim:** GoalOccurrenceDTO has scheduleId field but database table doesn't
- **Impact:** Decoding errors when loading occurrences
- **Files:**
  - `Data/DTOs/GoalOccurrenceDTO.swift:10, 32`

#### Audit Checklist
- [ ] Read GoalOccurrenceDTO.swift - confirm scheduleId exists
- [ ] Read GoalOccurrence.swift - check if domain model has scheduleId
- [ ] Search for schedule_id references in codebase
- [ ] Check SupabaseOccurrenceRepository queries
- [ ] Verify if scheduleId is actually used anywhere
- [ ] Determine correct design (goals have schedules, not occurrences)

#### Root Cause Analysis
_To be filled after audit_

#### Solution Design
**Expected:** Remove scheduleId from DTO (occurrences reference goals, goals have schedules)

#### Implementation Steps
1. Delete scheduleId property from GoalOccurrenceDTO
2. Delete scheduleId CodingKey
3. Remove from init(from:) method
4. Remove from toDomain conversion
5. Verify GoalOccurrence domain model doesn't have it

#### Test Plan
- [ ] Fetch today's occurrences
- [ ] Verify no decoding errors
- [ ] Verify occurrences display correctly
- [ ] All occurrence tests pass

#### Pass Conditions
- [ ] scheduleId removed from DTO
- [ ] No compilation errors
- [ ] Occurrences load successfully
- [ ] No decoding errors

#### Deliverables
- [ ] Fixed GoalOccurrenceDTO.swift
- [ ] Updated tests
- [ ] Documentation

---

### 🔴 BUG #6: Non-Existent userId in GoalMeasureTargetDTO

**Status:** ⏳ PENDING AUDIT
**Estimated Time:** 30 minutes
**Assignee:** iOS Dev

#### Bug Description
- **Claim:** GoalMeasureTargetDTO has userId but table doesn't
- **Impact:** Cannot load measurement targets
- **Files:**
  - `Data/DTOs/MeasurementDTO.swift:92, 104, 115`

#### Audit Checklist
- [ ] Read MeasurementDTO.swift - find GoalMeasureTargetDTO
- [ ] Confirm userId property exists
- [ ] Check if domain model GoalMeasureTarget has userId
- [ ] Search for user_id in goal_measure_targets context
- [ ] Determine if userId needed (can derive from Goal)

#### Root Cause Analysis
_To be filled after audit_

#### Solution Design
**Expected:** Remove userId (derive from Goal instead)

#### Implementation Steps
1. Remove userId from GoalMeasureTargetDTO
2. Remove from CodingKeys
3. Remove from init and toDomain
4. Verify GoalMeasureTarget domain model

#### Test Plan
- [ ] Fetch measurement targets for water goal
- [ ] Verify targets load successfully
- [ ] Verify no decoding errors
- [ ] All measurement tests pass

#### Pass Conditions
- [ ] userId removed from DTO
- [ ] Measurement targets load successfully
- [ ] No compilation errors

#### Deliverables
- [ ] Fixed MeasurementDTO.swift
- [ ] Updated tests
- [ ] Documentation

---

### 🔴 BUG #7: fatalError in Production Code

**Status:** ⏳ PENDING AUDIT
**Estimated Time:** 2 hours
**Assignee:** iOS Dev

#### Bug Description
- **Claim:** SupabaseService uses fatalError on init failure
- **Impact:** App crashes completely on config error
- **Files:**
  - `Infrastructure/Network/SupabaseService.swift:27, 32`

#### Audit Checklist
- [ ] Read SupabaseService.swift
- [ ] Confirm fatalError usage
- [ ] Check where SupabaseService is initialized
- [ ] Verify if errors can be caught
- [ ] Design graceful error handling

#### Root Cause Analysis
_To be filled after audit_

#### Solution Design
1. Make SupabaseService init throwing
2. Add new error cases to SupabaseError
3. Handle errors in AppFeature
4. Show error UI with retry

#### Implementation Steps
1. Update SupabaseService init to throw
2. Add configurationError and invalidURL to SupabaseError
3. Update AppFeature to handle init errors
4. Create ConfigErrorView
5. Add retry mechanism

#### Test Plan
- [ ] Test with invalid config
- [ ] Verify error UI shows
- [ ] Test retry mechanism
- [ ] Verify no crashes
- [ ] Test with valid config

#### Pass Conditions
- [ ] No fatalError in production code
- [ ] Configuration errors show UI
- [ ] Retry works
- [ ] No crashes on config errors

#### Deliverables
- [ ] Fixed SupabaseService.swift
- [ ] Updated SupabaseError.swift
- [ ] Updated AppFeature.swift
- [ ] New ConfigErrorView.swift
- [ ] Tests
- [ ] Documentation

---

### 🔴 BUG #8: Duplicate UnitKind Enum

**Status:** ⏳ PENDING AUDIT
**Estimated Time:** 15 minutes
**Assignee:** iOS Dev

#### Bug Description
- **Claim:** UnitKind enum defined twice (domain + TodayFeature)
- **Impact:** Type confusion
- **Files:**
  - `Domain/Models/Measurement.swift:61`
  - `Features/Today/TodayFeature.swift:297`

#### Audit Checklist
- [ ] Confirm domain UnitKind exists
- [ ] Confirm TodayFeature UnitKind exists
- [ ] Compare cases in both
- [ ] Find all references to TodayFeature version
- [ ] Verify deletion won't break anything

#### Root Cause Analysis
_To be filled after audit_

#### Solution Design
Delete duplicate from TodayFeature, use domain version

#### Implementation Steps
1. Delete enum from TodayFeature.swift
2. Update any references to use domain enum
3. Verify compilation
4. Test water tracking

#### Test Plan
- [ ] Verify compilation
- [ ] Test water tracking
- [ ] Verify no type errors

#### Pass Conditions
- [ ] Only one UnitKind enum exists
- [ ] No compilation errors
- [ ] Water tracking functional

#### Deliverables
- [ ] Fixed TodayFeature.swift
- [ ] Tests
- [ ] Documentation

---

### Phase 1 Summary Dashboard

| Bug # | Description | Status | Time | Pass |
|-------|-------------|--------|------|------|
| 1 | Measurement field | ⏳ Audit | 30m | ❌ |
| 2 | GoalStatus .completed | ⏳ Audit | 1h | ❌ |
| 3 | Profile mismatch | ⏳ Audit | 2h | ❌ |
| 4 | UnitKind enum | ⏳ Audit | 1h | ❌ |
| 5 | scheduleId field | ⏳ Audit | 30m | ❌ |
| 6 | userId field | ⏳ Audit | 30m | ❌ |
| 7 | fatalError | ⏳ Audit | 2h | ❌ |
| 8 | Duplicate enum | ⏳ Audit | 15m | ❌ |

**Total Progress:** 0/8 bugs fixed
**Total Time Spent:** 0 hours
**Estimated Remaining:** 8 hours

---

## PHASE 2: HIGH PRIORITY FIXES (Week 2)
**Status:** 🔒 BLOCKED - Waiting for Phase 1 completion

_Will be detailed after Phase 1 completion_

---

## PHASE 3: FEATURE COMPLETION (Weeks 3-4)
**Status:** 🔒 BLOCKED - Waiting for Phase 2 completion

_Will be detailed after Phase 2 completion_

---

## PHASE 4: TESTING & QUALITY (Week 5)
**Status:** 🔒 BLOCKED - Waiting for Phase 3 completion

_Will be detailed after Phase 3 completion_

---

## CONTEXT LOG

### Session Events
- **2025-11-20 11:50** - Created COMPREHENSIVE_APP_AUDIT_REPORT.md (17 issues found)
- **2025-11-20 11:52** - Created AUDIT_ACTION_PLAN.md (5-week roadmap)
- **2025-11-20 12:00** - Created this task tracker
- **2025-11-20 12:00** - Starting Phase 1 deep audit

### Key Decisions
_To be logged as decisions are made_

### Blockers
1. **Database Schema Unknown** - No migration files, need actual database access for Profile/UnitKind verification

### Questions for Team
1. What is the actual profiles table schema?
2. What are the actual values in unit_kind enum?
3. Does goal_occurrences table have schedule_id column?
4. Does goal_measure_targets table have user_id column?

---

**Last Updated:** 2025-11-20 12:00
**Next Update:** After Phase 1 audit completion
