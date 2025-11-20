# AUDIT ACTION PLAN
## HabitTracker iOS Application - Issue Resolution Roadmap

**Created:** November 20, 2025
**Based On:** COMPREHENSIVE_APP_AUDIT_REPORT.md
**Total Issues:** 17 (10 Critical, 3 High, 2 Medium, 2 Low)
**Estimated Total Time:** ~92 hours (5 weeks)

---

## EXECUTIVE SUMMARY

This action plan provides a systematic, prioritized approach to resolving all 17 issues identified in the comprehensive application audit. Issues are organized into 4 phases over 5 weeks, with **Phase 1 (Critical Fixes) being mandatory before any release**.

### Timeline Overview

```
Week 1: Critical Bug Fixes (P0)           [MANDATORY - NO RELEASE WITHOUT THIS]
Week 2: High Priority Fixes (P1)          [REQUIRED FOR PUBLIC BETA]
Week 3-4: Feature Completion (P2)         [REQUIRED FOR v1.0]
Week 5: Testing & Quality (P3)            [POLISH & QA]
```

### Success Criteria

- [ ] All 10 CRITICAL bugs fixed and tested
- [ ] All 3 HIGH severity issues resolved
- [ ] Feature parity achieved (all tabs functional)
- [ ] Test coverage ≥ 60%
- [ ] Zero compilation errors
- [ ] Zero runtime crashes in QA testing

---

## PHASE 1: CRITICAL BUG FIXES (Week 1)
**Priority:** P0 - MUST FIX IMMEDIATELY
**Estimated Time:** 8 hours
**Team:** iOS Dev + Backend Dev + Full Stack

### Overview

These 10 bugs will cause **immediate runtime failures** - the app is currently **not functional** in production. DO NOT RELEASE until all are fixed.

---

### 🔴 BUG #1: Measurement `recordedAt` → `occurred_at` Field Mismatch

**File:** `Sources/HabitTracker/Data/DTOs/MeasurementDTO.swift:26`
**Time:** 30 minutes
**Assignee:** Backend Dev
**Severity:** CRITICAL - Water tracking completely broken

#### Steps to Fix:

1. **Update MeasurementDTO.swift:**
   ```swift
   // Line 26 - Change CodingKey
   // BEFORE:
   case recordedAt = "recorded_at"

   // AFTER:
   case recordedAt = "occurred_at"
   ```

2. **Verify database column name:**
   ```sql
   -- Check actual column in measurements table
   SELECT column_name FROM information_schema.columns
   WHERE table_name = 'measurements';
   ```

3. **Test:**
   - Create test measurement
   - Verify it saves successfully
   - Verify it loads without decoding errors

#### Acceptance Criteria:
- [ ] Measurement DTO maps to correct database column
- [ ] Water tracking saves measurements successfully
- [ ] No decoding errors when loading measurements

---

### 🔴 BUG #2: GoalStatus Missing `.completed` Case

**File:** `Sources/HabitTracker/Domain/Models/Goal.swift:120-138`
**Used in:** `Sources/HabitTracker/Data/Repositories/Supabase/SupabaseGoalRepository.swift:328-369`
**Time:** 1 hour
**Assignee:** iOS Dev
**Severity:** CRITICAL - Compilation error or runtime crash

#### Steps to Fix:

**Option A (Recommended): Remove `complete()` method**
```swift
// SupabaseGoalRepository.swift - DELETE entire method (lines 328-369)
// Goals stay `.active` when completed - occurrences track completion

public func complete(id: UUID) async throws {  // ❌ DELETE THIS METHOD
    // ...
}
```

**Option B: Add `.completed` case**
```swift
// Goal.swift line 120 - Add new case
public enum GoalStatus: String, Codable, Sendable, CaseIterable {
    case active
    case paused
    case archived
    case completed  // ✅ ADD THIS
    case deleted
}

// Update database enum:
ALTER TYPE goal_status ADD VALUE 'completed';
```

#### Decision: Use Option A
- Goals should not complete (they're ongoing or paused)
- Occurrences represent completion state
- Simpler model

#### Acceptance Criteria:
- [ ] No compilation errors
- [ ] Goal completion logic removed or properly implemented
- [ ] Database enum matches Swift enum

---

### 🔴 BUG #3: Profile Model/Database Schema Mismatch

**File:** `Sources/HabitTracker/Domain/Models/Profile.swift:10-17`
**DTO:** `Sources/HabitTracker/Data/DTOs/ProfileDTO.swift`
**Time:** 2 hours
**Assignee:** Full Stack
**Severity:** CRITICAL - Cannot save/load profiles

#### Steps to Fix:

1. **Verify actual database schema:**
   ```sql
   \d profiles  -- Show table structure
   ```

2. **Add missing columns (if needed):**
   ```sql
   ALTER TABLE public.profiles
   ADD COLUMN IF NOT EXISTS avatar_url TEXT,
   ADD COLUMN IF NOT EXISTS week_starts_on INT DEFAULT 1,
   ADD COLUMN IF NOT EXISTS daily_reminder_enabled BOOLEAN DEFAULT false,
   ADD COLUMN IF NOT EXISTS daily_reminder_time TIMESTAMPTZ,
   ADD COLUMN IF NOT EXISTS total_points INT DEFAULT 0,
   ADD COLUMN IF NOT EXISTS current_streak INT DEFAULT 0,
   ADD COLUMN IF NOT EXISTS longest_streak INT DEFAULT 0;
   ```

3. **OR: Update Profile model to match existing schema:**
   ```swift
   // If database only has: id, display_name, tz, locale, created_at, updated_at
   // Then simplify Profile.swift to match:

   public final class Profile {
       public let id: UUID
       public var displayName: String?
       public var timezone: String        // Maps to "tz"
       public var locale: String?
       public let createdAt: Date
       public var updatedAt: Date

       // Move other fields to separate tables/models:
       // - UserPreferences (reminder settings, week start)
       // - UserStats (points, streaks)
   }
   ```

4. **Update ProfileDTO to match:**
   ```swift
   enum CodingKeys: String, CodingKey {
       case id
       case displayName = "display_name"
       case timezone = "tz"  // ✅ Map correctly
       case locale
       case createdAt = "created_at"
       case updatedAt = "updated_at"
   }
   ```

5. **Test:**
   - Create new profile
   - Verify save succeeds
   - Verify load succeeds

#### Acceptance Criteria:
- [ ] Profile model matches database schema exactly
- [ ] ProfileDTO maps all fields correctly
- [ ] Profile setup flow works end-to-end
- [ ] No decoding errors

---

### 🔴 BUG #4: UnitKind Enum Database Type Mismatch

**File:** `Sources/HabitTracker/Domain/Models/Measurement.swift:61-95`
**Time:** 1 hour
**Assignee:** Backend Dev
**Severity:** CRITICAL - Cannot save kg, lb, minutes, hours measurements

#### Steps to Fix:

1. **Check current database enum:**
   ```sql
   SELECT unnest(enum_range(NULL::unit_kind));
   ```

2. **Add missing values:**
   ```sql
   ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'kg';
   ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'lb';
   ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'minutes';
   ALTER TYPE unit_kind ADD VALUE IF NOT EXISTS 'hours';
   ```

3. **Verify DTO handles `minutes` ↔ `min` conversion:**
   ```swift
   // MeasurementDTO.swift lines 45-51 - Already implemented ✅
   // Verify this code exists and works
   ```

4. **Test all units:**
   - Create measurement with each unit type
   - Verify all save successfully
   - Verify correct unit displayed on load

#### Acceptance Criteria:
- [ ] Database enum has all 8 unit types
- [ ] Swift enum matches database exactly
- [ ] DTO converts minutes ↔ min correctly
- [ ] All unit types work in app

---

### 🔴 BUG #5: Remove Non-Existent `scheduleId` from GoalOccurrenceDTO

**File:** `Sources/HabitTracker/Data/DTOs/GoalOccurrenceDTO.swift:10, 32`
**Time:** 30 minutes
**Assignee:** iOS Dev
**Severity:** CRITICAL - Decoding errors when loading occurrences

#### Steps to Fix:

1. **Delete `scheduleId` field:**
   ```swift
   // GoalOccurrenceDTO.swift
   // DELETE line 10:
   public let scheduleId: UUID?  // ❌ DELETE THIS

   // DELETE from CodingKeys (line 32):
   case scheduleId = "schedule_id"  // ❌ DELETE THIS

   // DELETE from init (line ~60):
   scheduleId: occurrence.scheduleId,  // ❌ DELETE THIS

   // DELETE from toDomain (line ~90):
   // (scheduleId not used in domain model, so nothing to delete here)
   ```

2. **Verify GoalOccurrence model doesn't have scheduleId:**
   ```swift
   // GoalOccurrence.swift - confirm no scheduleId property exists
   ```

3. **Test:**
   - Fetch today's occurrences
   - Verify no decoding errors
   - Verify occurrences display correctly

#### Acceptance Criteria:
- [ ] scheduleId removed from DTO
- [ ] No compilation errors
- [ ] Occurrences load successfully

---

### 🔴 BUG #6: Remove Non-Existent `userId` from GoalMeasureTargetDTO

**File:** `Sources/HabitTracker/Data/DTOs/MeasurementDTO.swift:92, 104, 115`
**Time:** 30 minutes
**Assignee:** iOS Dev
**Severity:** CRITICAL - Cannot load measurement targets

#### Steps to Fix:

1. **Delete `userId` from GoalMeasureTargetDTO:**
   ```swift
   // MeasurementDTO.swift line 92
   // DELETE:
   public let userId: UUID  // ❌ DELETE THIS

   // DELETE from CodingKeys (line 104):
   case userId = "user_id"  // ❌ DELETE THIS

   // DELETE from init (line ~115):
   userId: target.userId,  // ❌ DELETE THIS
   ```

2. **Update GoalMeasureTarget domain model:**
   ```swift
   // Check if userId exists in domain model
   // If yes, derive it from Goal instead of storing separately
   ```

3. **Test:**
   - Fetch measurement targets for water goal
   - Verify targets load successfully
   - Verify no decoding errors

#### Acceptance Criteria:
- [ ] userId removed from DTO
- [ ] Measurement targets load successfully
- [ ] No compilation errors

---

### 🔴 BUG #7: Replace fatalError with Error Handling

**File:** `Sources/HabitTracker/Infrastructure/Network/SupabaseService.swift:27, 32`
**Time:** 2 hours
**Assignee:** iOS Dev
**Severity:** CRITICAL - App crashes on config error

#### Steps to Fix:

1. **Make SupabaseService init throwing:**
   ```swift
   // SupabaseService.swift
   private init() throws {  // ✅ Add throws
       do {
           try Config.validate()
       } catch {
           throw SupabaseError.configurationError(error.localizedDescription)
       }

       guard let parsedURL = URL(string: Config.supabaseURL) else {
           throw SupabaseError.invalidURL(Config.supabaseURL)
       }

       self.client = try SupabaseClient(
           supabaseURL: parsedURL,
           supabaseKey: Config.supabaseAnonKey,
           options: SupabaseClientOptions(
               auth: .init(
                   autoRefreshToken: true,
                   persistSession: true,
                   storage: SupabaseKeychainStorage(),
                   flowType: .pkce
               )
           )
       )
   }
   ```

2. **Add new error cases:**
   ```swift
   // SupabaseError.swift
   public enum SupabaseError {
       // ...
       case configurationError(String)
       case invalidURL(String)
   }
   ```

3. **Handle in AppFeature:**
   ```swift
   // AppFeature.swift
   @Reducer
   public struct AppFeature {
       @ObservableState
       public struct State {
           var configError: String?  // ✅ Add this
           // ...
       }

       public enum Action {
           case appStarted
           case configurationFailed(String)  // ✅ Add this
           case retryConfiguration  // ✅ Add this
       }

       public var body: some ReducerOf<Self> {
           Reduce { state, action in
               switch action {
               case .appStarted:
                   do {
                       _ = try SupabaseService.shared
                       return .none
                   } catch {
                       return .send(.configurationFailed(error.localizedDescription))
                   }

               case .configurationFailed(let error):
                   state.configError = error
                   return .none

               case .retryConfiguration:
                   state.configError = nil
                   return .send(.appStarted)
               }
           }
       }
   }
   ```

4. **Add error UI:**
   ```swift
   // AppView.swift
   if let error = store.configError {
       ConfigErrorView(error: error) {
           store.send(.retryConfiguration)
       }
   }
   ```

#### Acceptance Criteria:
- [ ] No fatalError calls in production code
- [ ] Configuration errors show user-friendly UI
- [ ] Retry button allows recovery
- [ ] No app crashes on config issues

---

### 🔴 BUG #8: Delete Duplicate UnitKind Enum

**File:** `Sources/HabitTracker/Features/Today/TodayFeature.swift:297`
**Time:** 15 minutes
**Assignee:** iOS Dev
**Severity:** HIGH - Type confusion

#### Steps to Fix:

1. **Delete duplicate enum from TodayFeature:**
   ```swift
   // TodayFeature.swift line ~297
   // DELETE entire enum:
   enum UnitKind: String {  // ❌ DELETE THIS ENTIRE ENUM
       case ml, l, oz
   }
   ```

2. **Import domain model:**
   ```swift
   // TodayFeature.swift - Add at top if not already there:
   // (Domain models should already be accessible)
   ```

3. **Update any references:**
   - Replace `UnitKind.ml` with correct domain enum reference

4. **Compile and test:**
   - Verify no compilation errors
   - Verify water tracking still works

#### Acceptance Criteria:
- [ ] Duplicate enum deleted
- [ ] Only domain UnitKind enum exists
- [ ] No compilation errors
- [ ] Water tracking functional

---

### 🔴 BUG #9: Fix Program Model/Database Schema Mismatch

**File:** `Sources/HabitTracker/Domain/Models/Program.swift`
**Time:** 3 hours (MOVED TO PHASE 2 - non-critical for MVP)
**Assignee:** Full Stack
**Severity:** CRITICAL - But Programs tab is placeholder, can wait for Phase 2

**Action:** DEFER TO PHASE 2 (Programs feature is incomplete anyway)

---

### 🔴 BUG #10: Fix RPC Return Type Mismatches

**Files:** `SupabaseAreaRepository.swift`, `SupabaseGoalRepository.swift`
**Time:** 2 hours (MOVED TO PHASE 2)
**Assignee:** Full Stack
**Severity:** HIGH - But Insights tab is placeholder, can wait for Phase 2

**Action:** DEFER TO PHASE 2 (Insights feature is incomplete anyway)

---

### Phase 1 Summary

| # | Bug | Time | Status |
|---|-----|------|--------|
| 1 | Measurement recordedAt field | 30 min | ⏳ Pending |
| 2 | GoalStatus .completed | 1 hour | ⏳ Pending |
| 3 | Profile model mismatch | 2 hours | ⏳ Pending |
| 4 | UnitKind enum | 1 hour | ⏳ Pending |
| 5 | Remove scheduleId | 30 min | ⏳ Pending |
| 6 | Remove userId | 30 min | ⏳ Pending |
| 7 | Replace fatalError | 2 hours | ⏳ Pending |
| 8 | Delete duplicate UnitKind | 15 min | ⏳ Pending |

**Total Time:** ~8 hours
**Target Completion:** End of Week 1
**Dependencies:** None - all can be done in parallel

---

## PHASE 2: HIGH PRIORITY FIXES (Week 2)
**Priority:** P1 - FIX BEFORE PUBLIC BETA
**Estimated Time:** 14 hours
**Team:** Full Stack + iOS Dev

### Overview

These issues don't cause immediate crashes but are required for core features to work properly.

---

### 🟡 ISSUE #9 (continued): Fix Program Model/Database Mismatch

**Time:** 3 hours
**Assignee:** Full Stack

#### Steps to Fix:

1. **Audit actual database schema:**
   ```sql
   \d programs
   SELECT column_name, data_type FROM information_schema.columns
   WHERE table_name = 'programs';
   ```

2. **Update Program model to match:**
   - Add missing fields (slug, summary, urls, ratings, visibility)
   - Remove non-existent fields
   - Update ProgramDTO accordingly

3. **Test program loading:**
   - Fetch programs from database
   - Verify all fields map correctly

---

### 🟡 ISSUE #10 (continued): Fix RPC Return Type Mismatches

**Time:** 2 hours
**Assignee:** Full Stack

#### Steps to Fix:

1. **Fix get_area_statistics RPC:**
   ```swift
   // Create simplified DTO matching RPC output
   struct AreaStatisticsDTO: Decodable {
       let total_goals: Int
       let active_goals: Int
       let total_completions: Int
       let completion_rate: Double

       var toDomain: AreaStatistics {
           AreaStatistics(
               totalGoals: total_goals,
               activeGoals: active_goals,
               totalCompletions: total_completions,
               completionRate: completion_rate
           )
       }
   }
   ```

2. **Fix get_most_completed_goals RPC:**
   ```swift
   // Create stats-specific DTO
   struct GoalStatsDTO: Decodable {
       let goal_id: UUID
       let goal_title: String
       let goal_emoji: String?
       let completion_count: Int
   }
   ```

---

### 🟡 ISSUE #11: Implement Proper Logging Framework

**Time:** 3 hours
**Assignee:** iOS Dev

#### Steps to Fix:

1. **Create Logger.swift:**
   ```swift
   import OSLog

   public struct Logger {
       private static let subsystem = "com.habittracker.app"

       public enum Category: String {
           case sync, network, repository, cache, general
       }

       private let logger: os.Logger

       public init(category: Category) {
           self.logger = os.Logger(subsystem: Self.subsystem, category: category.rawValue)
       }

       public func debug(_ message: String) {
           logger.debug("\(message)")
       }

       public func info(_ message: String) {
           logger.info("\(message)")
       }

       public func warning(_ message: String) {
           logger.warning("\(message)")
       }

       public func error(_ message: String) {
           logger.error("\(message)")
       }

       public func critical(_ message: String) {
           logger.critical("\(message)")
       }
   }
   ```

2. **Replace all print() statements (15 locations):**
   ```swift
   // BEFORE:
   print("Failed to sync area: \(error)")

   // AFTER:
   let logger = Logger(category: .sync)
   logger.error("Failed to sync area \(cached.id): \(error.localizedDescription)")
   ```

3. **Add logging to key points:**
   - Repository operations
   - Sync start/complete
   - Network errors
   - Cache operations

---

### 🟡 ISSUE #12: Create Database Migration Files

**Time:** 4 hours
**Assignee:** Backend Dev

#### Steps to Fix:

1. **Create migration directory:**
   ```bash
   mkdir -p Supabase/migrations
   ```

2. **Export current schema:**
   ```bash
   pg_dump --schema-only habittracker > Supabase/migrations/001_initial_schema.sql
   ```

3. **Create separate migrations:**
   - `001_initial_schema.sql` - All tables
   - `002_rls_policies.sql` - RLS policies
   - `003_triggers_and_rpcs.sql` - Functions and triggers
   - `004_performance_indexes.sql` - Indexes

4. **Create README:**
   ```markdown
   # Database Migrations

   ## Running Migrations

   1. Install Supabase CLI
   2. Run: `supabase db push`

   ## Migration Order

   Migrations run in order:
   1. 001_initial_schema.sql
   2. 002_rls_policies.sql
   3. 003_triggers_and_rpcs.sql
   4. 004_performance_indexes.sql
   ```

---

### 🟡 ISSUE #13: Fix Inconsistent Error Handling

**Time:** 2 hours
**Assignee:** iOS Dev

#### Steps to Fix:

1. **Audit all `try?` usage:**
   ```bash
   grep -rn "try?" Sources/HabitTracker --include="*.swift"
   ```

2. **Replace silent failures:**
   ```swift
   // BEFORE:
   if let result = try? await operation() {
       // success
   }
   // ❌ Error silently lost

   // AFTER:
   do {
       let result = try await operation()
       // success
   } catch {
       logger.error("Operation failed: \(error)")
       // Decide: propagate, show UI, or use fallback
   }
   ```

3. **Add error surfaces to UI:**
   - Show sync errors in status bar
   - Show offline indicator when network unavailable

---

### Phase 2 Summary

| # | Issue | Time | Status |
|---|-------|------|--------|
| 9 | Program model mismatch | 3 hours | ⏳ Pending |
| 10 | RPC return types | 2 hours | ⏳ Pending |
| 11 | Logging framework | 3 hours | ⏳ Pending |
| 12 | Database migrations | 4 hours | ⏳ Pending |
| 13 | Error handling | 2 hours | ⏳ Pending |

**Total Time:** ~14 hours
**Target Completion:** End of Week 2

---

## PHASE 3: FEATURE COMPLETION (Weeks 3-4)
**Priority:** P2 - REQUIRED FOR v1.0
**Estimated Time:** 36 hours

### Feature #14: Implement AreasFeature Reducer
**Time:** 6 hours | **Assignee:** iOS Dev

- Create AreasFeature.swift with TCA reducer
- Implement CRUD actions (create, update, archive, delete areas)
- Wire to AreaRepository dependency
- Update AreasView to use store
- Add area creation/editing views

### Feature #15: Implement InsightsFeature Reducer
**Time:** 8 hours | **Assignee:** iOS Dev

- Create InsightsFeature.swift
- Implement analytics queries (stats, trends, charts)
- Wire to repositories for data
- Create chart components
- Update InsightsView with live data

### Feature #16: Implement ProgramsFeature + Adoption
**Time:** 8 hours | **Assignee:** iOS Dev

- Create ProgramsFeature.swift
- Implement program browsing (categories, search)
- Implement adoption flow (preview → select area → create goals)
- Wire to ProgramRepository
- Update ProgramsView

### Feature #17: Implement SettingsFeature
**Time:** 6 hours | **Assignee:** iOS Dev

- Create SettingsFeature.swift
- Implement export functionality (CSV/JSON)
- Implement sign out flow
- Implement account deletion with confirmation
- Update SettingsView

### Feature #18: Add Profile/Program/Reflection Caching
**Time:** 4 hours | **Assignee:** iOS Dev

- Create CachedProfile.swift
- Create CachedProgram.swift
- Create CachedReflection.swift
- Update CacheService with CRUD
- Update SyncEngine to sync these entities

### Feature #19: Wire Up Realtime Subscriptions
**Time:** 4 hours | **Assignee:** iOS Dev

- Subscribe to goal_occurrences table in TodayFeature
- Handle INSERT/UPDATE/DELETE events
- Implement optimistic updates
- Handle conflict resolution

---

## PHASE 4: TESTING & QUALITY (Week 5)
**Priority:** P3 - QUALITY ASSURANCE
**Estimated Time:** 34 hours

### Testing #20: Write TCA Feature Tests
**Time:** 12 hours | **Assignee:** iOS Dev

- AuthenticationFeature tests (login, signup, validation)
- TodayFeature tests (occurrence completion, sync)
- ProfileSetupFeature tests
- AreasFeature tests
- Target: 100% feature test coverage

### Testing #21: Write Integration Tests
**Time:** 8 hours | **Assignee:** QA

- Repository integration tests (with test database)
- Sync engine integration tests
- End-to-end user flows
- Offline/online scenarios

### Testing #22: Write UI Tests
**Time:** 8 hours | **Assignee:** QA

- Authentication flow
- Today view completion flow
- Area creation flow
- Program adoption flow
- Settings flows

### Quality #23: Fix Weak Self Redundancy
**Time:** 1 hour | **Assignee:** iOS Dev

- Fix SyncCoordinator.swift weak self duplication

### Quality #24: Consolidate Date Extensions
**Time:** 1 hour | **Assignee:** iOS Dev

- Create shared Date+Extensions.swift
- Remove duplicate extensions

### Quality #25: Code Review & Cleanup
**Time:** 4 hours | **Assignee:** Team

- Review all fixes
- Check for regressions
- Update documentation
- Final QA pass

---

## ISSUE TRACKING CHECKLIST

### Critical Bugs (P0) - Must Fix Week 1
- [ ] #1: Measurement recordedAt field (30 min)
- [ ] #2: GoalStatus .completed (1 hour)
- [ ] #3: Profile model mismatch (2 hours)
- [ ] #4: UnitKind enum (1 hour)
- [ ] #5: Remove scheduleId (30 min)
- [ ] #6: Remove userId (30 min)
- [ ] #7: Replace fatalError (2 hours)
- [ ] #8: Delete duplicate UnitKind (15 min)

### High Priority (P1) - Must Fix Week 2
- [ ] #9: Program model mismatch (3 hours)
- [ ] #10: RPC return types (2 hours)
- [ ] #11: Logging framework (3 hours)
- [ ] #12: Database migrations (4 hours)
- [ ] #13: Error handling (2 hours)

### Feature Completion (P2) - Weeks 3-4
- [ ] #14: AreasFeature (6 hours)
- [ ] #15: InsightsFeature (8 hours)
- [ ] #16: ProgramsFeature (8 hours)
- [ ] #17: SettingsFeature (6 hours)
- [ ] #18: Caching expansion (4 hours)
- [ ] #19: Realtime subscriptions (4 hours)

### Testing & Quality (P3) - Week 5
- [ ] #20: TCA tests (12 hours)
- [ ] #21: Integration tests (8 hours)
- [ ] #22: UI tests (8 hours)
- [ ] #23: Fix weak self (1 hour)
- [ ] #24: Consolidate extensions (1 hour)
- [ ] #25: Code review (4 hours)

---

## RISK MITIGATION

### High Risk Items

1. **Profile Schema Mismatch (#3)**
   - **Risk:** Database may have completely different schema
   - **Mitigation:** Verify schema first before code changes
   - **Fallback:** Create migration to add all fields

2. **Program Model Mismatch (#9)**
   - **Risk:** Model and DB may be fundamentally incompatible
   - **Mitigation:** Complete redesign may be needed
   - **Fallback:** Use simplified program model, move advanced features to v2.0

3. **RPC Mismatches (#10)**
   - **Risk:** RPCs may not exist or return completely different data
   - **Mitigation:** Write new RPCs if needed
   - **Fallback:** Compute statistics client-side

### Dependencies

```
Profile Fix (#3) ← ProfileSetupFeature
Program Fix (#9) ← ProgramsFeature (#16)
RPC Fixes (#10) ← InsightsFeature (#15)
Logging (#11) ← Better debugging for all other fixes
```

---

## TESTING STRATEGY

### Phase 1 Testing
After each critical fix:
1. Unit test the fix
2. Integration test the feature
3. Manual QA test the user flow
4. ✅ Sign off before moving to next fix

### Phase 2 Testing
After all P1 fixes:
1. Full regression test suite
2. Performance testing
3. Security audit
4. ✅ Sign off before Phase 3

### Phase 3 Testing
After each feature:
1. Feature-specific tests
2. Integration with existing features
3. Manual QA
4. ✅ Sign off before next feature

### Phase 4 Testing
Final QA:
1. Complete E2E test suite
2. Performance benchmarks
3. Security penetration testing
4. Beta tester feedback
5. ✅ Sign off for release

---

## SUCCESS METRICS

### Code Quality
- [ ] Zero fatalError in production code
- [ ] Zero print() statements (replaced with Logger)
- [ ] Zero force unwraps (!)
- [ ] Zero unsafe try!
- [ ] Zero compilation warnings

### Functionality
- [ ] All 7 tabs functional
- [ ] All CRUD operations working
- [ ] Offline mode works
- [ ] Sync works reliably
- [ ] No data loss scenarios

### Testing
- [ ] ≥ 60% test coverage
- [ ] All critical paths tested
- [ ] Zero crashes in QA testing
- [ ] Performance benchmarks met

### Documentation
- [ ] All TODOs resolved
- [ ] Migration guide created
- [ ] API documentation updated
- [ ] User guide written

---

## ROLLOUT PLAN

### Week 1: Internal Testing
- Fix all P0 bugs
- Internal team testing
- Fix any regressions

### Week 2: Alpha Testing
- Fix all P1 issues
- Deploy to TestFlight (internal testers)
- Gather feedback

### Week 3-4: Beta Testing
- Complete all features
- Deploy to TestFlight (public beta)
- Monitor crash reports

### Week 5: Release Candidate
- Complete all testing
- Final QA pass
- Submit to App Store

---

## COMMUNICATION PLAN

### Daily Standups
- Progress on assigned bugs
- Blockers identified
- Help needed

### Weekly Reviews
- Demo completed fixes
- Update status dashboard
- Adjust timeline if needed

### Phase Gates
- After each phase: team review meeting
- Demo all fixes to stakeholders
- Get sign-off before next phase

---

## CONTINGENCY PLAN

### If Week 1 Runs Over
- Extend Week 1, push other phases back
- DO NOT SKIP CRITICAL FIXES

### If Database Schema Drastically Different
- Emergency meeting with backend team
- Redesign models to match actual schema
- Update timeline (may add 1-2 weeks)

### If Testing Reveals More Critical Bugs
- Stop feature development
- Fix new critical bugs first
- Reassess timeline

---

**Action Plan Created By:** Claude Code (Sonnet 4.5)
**Last Updated:** November 20, 2025
**Review Schedule:** Weekly
**Contact:** Development Team Lead

---

**END OF ACTION PLAN**
