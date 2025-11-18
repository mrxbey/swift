# HabitTracker - Production Roadmap & Task Tracker

**Created:** 2025-11-18
**Branch:** `claude/swiftui-app-planning-01Fxme8XNSYDtz7acgPdxC8i`
**Status:** 🔴 NOT PRODUCTION READY
**Target:** Production-ready app with core features complete

---

## Executive Summary

**Current State:**
- ✅ 12 critical bugs fixed (previous session)
- ❌ 23 new bugs discovered (comprehensive audit)
- ⚠️ 4 core features missing/incomplete
- 📊 Overall Completion: ~40%

**Path to Production:**
1. **Phase 1:** Fix all P0/P1 bugs (17 bugs, ~7-8 days)
2. **Phase 2:** Implement Goals Management (P0 feature, ~7 days)
3. **Phase 3:** Implement Water Tracking (P1 feature, ~4 days)
4. **Phase 4:** Implement Buddy System (P2 feature, ~10 days)
5. **Phase 5:** Implement Reflections (P3 feature, ~5 days)
6. **Phase 6:** Testing & Polish (~5 days)

**Total Estimated Time:** 38-40 days (6-8 weeks with focused development)

---

## Table of Contents

1. [Bug Fixes (Phase 1)](#phase-1-critical-bug-fixes)
2. [Goals Management (Phase 2)](#phase-2-goals-management-implementation)
3. [Water Tracking (Phase 3)](#phase-3-water-tracking-implementation)
4. [Buddy System (Phase 4)](#phase-4-buddy-system-implementation)
5. [Reflections (Phase 5)](#phase-5-reflections-implementation)
6. [Testing & Polish (Phase 6)](#phase-6-testing--polish)
7. [Progress Tracking](#progress-tracking)
8. [Risk Management](#risk-management)

---

# Phase 1: Critical Bug Fixes

**Duration:** 7-8 days
**Priority:** P0 - BLOCKING
**Goal:** Fix all production-blocking bugs

## P0 - Critical Bugs (11 bugs)

### Bug 1.1: Force Unwrap Crashes in RecurrenceEngine

**File:** `RecurrenceEngine.swift`
**Lines:** 189, 230, 232, 244, 246, 247, 249, 250, 279
**Severity:** P0
**Impact:** App crashes when generating occurrences

**Current Code:**
```swift
// Line 189
let endDate = calendar.date(byAdding: .day, value: 14, to: today)!

// Line 230
return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
```

**Fix:**
```swift
// Line 189
guard let endDate = calendar.date(byAdding: .day, value: 14, to: today) else {
    return []  // Return empty array on date calculation failure
}

// Line 230
guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
    return now  // Fallback to now if calculation fails
}
```

**Steps:**
1. [ ] Read RecurrenceEngine.swift
2. [ ] Replace all force unwraps with guard statements
3. [ ] Add appropriate fallback logic
4. [ ] Test with edge dates (leap years, DST boundaries)
5. [ ] Verify occurrence generation works

**Acceptance Criteria:**
- [ ] No force unwraps in RecurrenceEngine
- [ ] Occurrence generation never crashes
- [ ] Edge cases handled gracefully

---

### Bug 1.2: Force Unwrap Crashes in SyncEngine

**File:** `SyncEngine.swift`
**Lines:** 250, 273, 321
**Severity:** P0
**Impact:** Sync crashes when downloading historical data

**Current Code:**
```swift
// Line 250
let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
```

**Fix:**
```swift
guard let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else {
    throw SyncError.dateCalculationFailed
}
```

**Steps:**
1. [ ] Read SyncEngine.swift
2. [ ] Replace force unwraps with guard/throws
3. [ ] Add SyncError.dateCalculationFailed error type
4. [ ] Test sync with date edge cases
5. [ ] Verify error handling works

**Acceptance Criteria:**
- [ ] No force unwraps in SyncEngine
- [ ] Sync never crashes on date calculations
- [ ] Errors logged for debugging

---

### Bug 1.3: Force Unwrap Crashes in CacheService

**File:** `CacheService.swift`
**Lines:** 164, 295, 306, 317, 328
**Severity:** P0
**Impact:** Cache operations crash

**Current Code:**
```swift
// Line 164
let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

// Lines 295, 306, 317, 328
area.lastSyncedAt! < date  // Force unwrap after nil check
```

**Fix:**
```swift
// Line 164
guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
    throw CacheError.dateCalculationFailed
}

// Lines 295, 306, 317, 328
area.lastSyncedAt.map { $0 < date } ?? false
```

**Steps:**
1. [ ] Read CacheService.swift
2. [ ] Replace force unwraps with safe optional handling
3. [ ] Use optional chaining where appropriate
4. [ ] Test cache operations
5. [ ] Verify cleanup methods work

**Acceptance Criteria:**
- [ ] No force unwraps in CacheService
- [ ] Cache operations never crash
- [ ] Cleanup methods handle nil dates

---

### Bug 1.4: State Mutation in TCA Reducer

**File:** `TodayFeature.swift`
**Lines:** 178, 199
**Severity:** P0
**Impact:** Violates TCA principles, unpredictable state

**Current Code:**
```swift
// Line 178
state.occurrences[id: id]?.incrementCompletion()  // DIRECT MUTATION!

// Line 199
state.occurrences[id: id]?.markSkipped()  // DIRECT MUTATION!
```

**Fix:**
```swift
case let .completeTickResponse(id, .success):
    if var occurrence = state.occurrences[id: id] {
        occurrence.completedCount += 1
        if occurrence.completedCount >= occurrence.targetCount {
            occurrence.status = .completed
        }
        state.occurrences[id: id] = occurrence
    }
    return .send(.refresh)
```

**Steps:**
1. [ ] Read TodayFeature.swift
2. [ ] Remove direct mutation calls
3. [ ] Use value semantics (create new, assign)
4. [ ] Test state updates in SwiftUI
5. [ ] Verify view updates correctly

**Acceptance Criteria:**
- [ ] No direct mutations in reducer
- [ ] All state updates use value semantics
- [ ] SwiftUI views update correctly

---

### Bug 1.5: Mock Repository Field Mismatch

**File:** `DependencyValues+Repositories.swift`
**Lines:** 343, 357, 377-384
**Severity:** P0
**Impact:** Tests and previews crash

**Current Code:**
```swift
// Line 343
occurrence.lastCompletedAt = Date()  // FIELD DOESN'T EXIST

// Line 357
occurrence.renameOverride = newName  // WRONG FIELD NAME

// Lines 377-384
let newOccurrence = GoalOccurrence(
    ...
    scheduleId: nil,  // NOT IN CONSTRUCTOR
    renameOverride: nil,  // WRONG FIELD
    lastCompletedAt: nil,  // DOESN'T EXIST
    ...
)
```

**Fix:**
```swift
// Line 343 - DELETE THIS LINE

// Line 357
occurrence.nameOverride = newName  // CORRECT

// Lines 377-384
let newOccurrence = GoalOccurrence(
    id: UUID(),
    goalId: goalId,
    userId: UUID(),
    scheduledDate: date,
    status: .pending,
    targetCount: 1,
    completedCount: 0,
    nameOverride: nil,
    contentSnapshot: nil,
    createdAt: Date(),
    updatedAt: Date()
)
```

**Steps:**
1. [ ] Read DependencyValues+Repositories.swift
2. [ ] Read GoalOccurrence domain model for correct fields
3. [ ] Fix all field name mismatches
4. [ ] Remove non-existent field references
5. [ ] Test previews compile
6. [ ] Test unit tests compile

**Acceptance Criteria:**
- [ ] All field names match domain model
- [ ] Previews compile and run
- [ ] Unit tests compile and pass

---

### Bug 1.6: Silent Sync Failures

**File:** `SupabaseOccurrenceRepository.swift`
**Lines:** 60, 142, 285, 316, 342
**Severity:** P0
**Impact:** Sync errors never reported, stale data

**Current Code:**
```swift
// Line 60
try? await syncEngine.performFullSync(userId: userId)  // SILENT FAILURE

// Line 285
if let updated = try? await fetchOccurrenceFromSupabase(id, userId: userId) {
    // SILENT FAILURE if fetch fails
}
```

**Fix:**
```swift
// Line 60
do {
    try await syncEngine.performFullSync(userId: userId)
} catch {
    logger.error("Sync failed: \(error)")
}

// Line 285
do {
    let updated = try await fetchOccurrenceFromSupabase(id, userId: userId)
    try cacheService.saveOccurrence(updated, syncState: .synced)
} catch {
    logger.error("Failed to refresh cache after RPC: \(error)")
}
```

**Steps:**
1. [ ] Read SupabaseOccurrenceRepository.swift
2. [ ] Replace all `try?` with `do-catch` blocks
3. [ ] Add logger.error() calls
4. [ ] Test error logging
5. [ ] Verify errors appear in console

**Acceptance Criteria:**
- [ ] No silent `try?` for sync operations
- [ ] All errors logged
- [ ] Cache staleness visible in logs

---

### Bug 1.7: Duplicate Reducer Definitions

**File:** `HabitTrackerApp.swift`
**Lines:** 345-383
**Severity:** P0
**Impact:** Compiler ambiguity, wrong reducers used

**Current Code:**
```swift
// HabitTrackerApp.swift - Lines 345-383
@Reducer
struct SettingsFeature {  // DUPLICATE!
    @ObservableState
    struct State: Equatable {}
    enum Action: Sendable {}
    var body: some ReducerOf<Self> { Reduce { _, _ in .none } }
}

@Reducer
struct InsightsFeature {  // DUPLICATE!
    ...
}
```

**Fix:**
- Delete placeholder definitions from HabitTrackerApp.swift
- Use actual implementations from feature files

**Steps:**
1. [ ] Read HabitTrackerApp.swift lines 345-383
2. [ ] Identify all placeholder reducers
3. [ ] Verify actual implementations exist in Features/
4. [ ] Delete placeholders
5. [ ] Test app compiles
6. [ ] Test Settings and Insights tabs work

**Acceptance Criteria:**
- [ ] No duplicate reducer definitions
- [ ] App compiles without ambiguity warnings
- [ ] Settings and Insights tabs functional

---

### Bug 1.8: Password Validation Inconsistency

**Files:** `AuthenticationFeature.swift`, `AuthService.swift`
**Lines:** 35 (AuthFeature), 220-236 (AuthService)
**Severity:** P1 (borderline P0)
**Impact:** Poor UX, users confused by validation

**Current Code:**
```swift
// AuthenticationFeature.swift - Line 35
public var isPasswordValid: Bool {
    password.count >= 6  // WEAK
}

// AuthService.swift - Lines 220-236
guard password.count >= 8 else {  // STRICT
    throw AuthError.passwordTooShort(...)
}
```

**Fix:**
```swift
// AuthenticationFeature.swift
public var isPasswordValid: Bool {
    guard password.count >= 8 else { return false }
    guard password.rangeOfCharacter(from: .uppercaseLetters) != nil else { return false }
    guard password.rangeOfCharacter(from: .lowercaseLetters) != nil else { return false }
    guard password.rangeOfCharacter(from: .decimalDigits) != nil else { return false }
    return true
}
```

**Steps:**
1. [ ] Read AuthenticationFeature.swift
2. [ ] Copy validation logic from AuthService
3. [ ] Update isPasswordValid computed property
4. [ ] Test form validation matches backend
5. [ ] Verify error messages consistent

**Acceptance Criteria:**
- [ ] Client and server validation match
- [ ] Form prevents invalid submissions
- [ ] User gets clear feedback

---

### Bug 1.9: Force Unwrapped URLs in SettingsView

**File:** `SettingsView.swift`
**Lines:** 96-98
**Severity:** P2
**Impact:** Potential crash (unlikely), placeholder URLs

**Current Code:**
```swift
Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
Link("Support", destination: URL(string: "https://example.com/support")!)
```

**Fix:**
```swift
private enum ExternalLinks {
    static let privacyURL = URL(string: "https://yourapp.com/privacy")!  // Crash at startup if invalid
    static let termsURL = URL(string: "https://yourapp.com/terms")!
    static let supportURL = URL(string: "https://yourapp.com/support")!
}

// In view:
if let url = ExternalLinks.privacyURL {
    Link("Privacy Policy", destination: url)
}
```

**Steps:**
1. [ ] Read SettingsView.swift
2. [ ] Create ExternalLinks enum
3. [ ] Replace force unwraps with if-let
4. [ ] Update placeholder URLs to real ones
5. [ ] Test links work

**Acceptance Criteria:**
- [ ] No force unwrapped URLs in view body
- [ ] Links point to real URLs
- [ ] Links open correctly

---

### Bug 1.10: Force Unwrap in InsightsView Preview

**File:** `InsightsView.swift`
**Line:** 390
**Severity:** P2
**Impact:** Preview crashes

**Current Code:**
```swift
completionData: (0..<7).map { days in
    CompletionDataPoint(
        date: Calendar.current.date(byAdding: .day, value: -days, to: Date())!,
        completionRate: Double.random(in: 0.5...1.0)
    )
}
```

**Fix:**
```swift
completionData: (0..<7).compactMap { days in
    guard let date = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
        return nil
    }
    return CompletionDataPoint(date: date, completionRate: Double.random(in: 0.5...1.0))
}
```

**Steps:**
1. [ ] Read InsightsView.swift line 390
2. [ ] Replace map with compactMap
3. [ ] Add guard statement
4. [ ] Test preview in Xcode
5. [ ] Verify renders correctly

**Acceptance Criteria:**
- [ ] Preview renders without crash
- [ ] Chart displays correctly

---

### Bug 1.11: Unsafe Repository Initialization with try!

**File:** `DependencyValues+Repositories.swift`
**Lines:** 71, 79, 87, 95, 119-149
**Severity:** P1
**Impact:** App crashes at startup if init fails

**Current Code:**
```swift
static let testValue: CacheService = try! CacheService()  // CRASH!
static let previewValue: CacheService = try! CacheService()  // CRASH!
```

**Fix:**
```swift
static let liveValue: CacheService = {
    do {
        return try CacheService()
    } catch {
        logger.critical("Failed to initialize CacheService: \(error)")
        fatalError("Critical: Cannot initialize CacheService - \(error)")
    }
}()
```

**Steps:**
1. [ ] Read DependencyValues+Repositories.swift
2. [ ] Replace try! with do-catch
3. [ ] Add logging before fatalError
4. [ ] Test app launch
5. [ ] Verify error messages helpful

**Acceptance Criteria:**
- [ ] No try! for repository initialization
- [ ] Error messages helpful for debugging
- [ ] Graceful failure with logging

---

## P1 - High Priority Bugs (6 bugs)

### Bug 1.12: @MainActor on SyncEngine

**File:** `SyncEngine.swift`
**Line:** 8
**Severity:** P1
**Impact:** Main thread blocking during sync

**Fix:**
```swift
// Before:
@MainActor
public final class SyncEngine {

// After:
public actor SyncEngine {  // Use actor for thread safety
```

**Steps:**
1. [ ] Remove @MainActor annotation
2. [ ] Change class to actor
3. [ ] Test sync operations
4. [ ] Verify no UI blocking
5. [ ] Measure performance improvement

**Acceptance Criteria:**
- [ ] No @MainActor on SyncEngine
- [ ] UI responsive during sync
- [ ] Thread safety maintained

---

### Bug 1.13-1.17: Remaining P1 Bugs

*(Continue similar format for remaining 5 P1 bugs)*

---

# Phase 2: Goals Management Implementation

**Duration:** 7 days
**Priority:** P0 - BLOCKING
**Goal:** Complete goal CRUD functionality
**Design Doc:** See `FEATURE_DESIGNS_COMPREHENSIVE.md`

## Task 2.1: Template Selection

**Day 1**
**Files to Create:**
- `Sources/HabitTracker/Domain/Models/GoalTemplate.swift`
- `Sources/HabitTracker/Features/Goals/TemplateSelectionView.swift`

**Implementation:**
1. [ ] Create GoalTemplate model
   ```swift
   public struct GoalTemplate: Identifiable, Equatable {
       public let id: String
       public let name: String
       public let emoji: String
       public let category: TemplateCategory
       public let frequency: PeriodFrequency
       public let timesPerDay: Int
       public let points: Int
   }
   ```

2. [ ] Add popular templates
   - Morning Meditation
   - Drink Water
   - Exercise
   - Read Book
   - Practice Gratitude
   - (10 total templates)

3. [ ] Create TemplateSelectionView
   - Grid layout
   - Category filtering
   - Search
   - Tap to select → navigate to form

4. [ ] Wire up navigation

**Acceptance Criteria:**
- [ ] User can browse 10+ templates
- [ ] Tapping template navigates to goal form
- [ ] Template data pre-fills form

---

## Task 2.2: Goal Form (Basic)

**Days 2-3**
**Files to Create:**
- `Sources/HabitTracker/Features/Goals/GoalFormFeature.swift`
- `Sources/HabitTracker/Features/Goals/GoalFormView.swift`

**Implementation:**

**Day 2: Feature & State**
1. [ ] Create GoalFormFeature
2. [ ] Define State (name, emoji, area, frequency, times, points)
3. [ ] Define Actions (all form events)
4. [ ] Define Reducer skeleton

**Day 3: View & Validation**
5. [ ] Create GoalFormView
6. [ ] Name text field
7. [ ] Emoji picker button
8. [ ] Area selector
9. [ ] Frequency picker (Daily/Weekly/Monthly)
10. [ ] Times-per-day slider
11. [ ] Points slider
12. [ ] Form validation
13. [ ] Save button (enabled when valid)

**Acceptance Criteria:**
- [ ] Form displays all fields
- [ ] Validation prevents invalid saves
- [ ] Template pre-fills form correctly
- [ ] User can modify all fields

---

## Task 2.3: Advanced Options

**Day 4**
**Files to Modify:**
- `GoalFormView.swift`

**Implementation:**
1. [ ] Collapsible "Advanced Options" section
2. [ ] Weekday selector (for weekly goals)
   - M T W T F S S checkboxes
3. [ ] Month day selector (for monthly goals)
   - 1-31 multi-select
4. [ ] Keep-until-complete toggle
5. [ ] Linked exercise picker
6. [ ] Hashtag input field

**Acceptance Criteria:**
- [ ] Advanced section collapsed by default
- [ ] Weekday selector works for weekly
- [ ] Month day selector works for monthly
- [ ] All options save correctly

---

## Task 2.4: Save Logic

**Day 5**
**Files to Modify:**
- `GoalFormFeature.swift`

**Implementation:**
1. [ ] Wire up goal repository dependency
2. [ ] Implement save action
   - Create new goal
   - Call repository.create()
   - Handle success/error
3. [ ] Implement update action
   - Update existing goal
   - Call repository.update()
4. [ ] Add haptic feedback on success
5. [ ] Dismiss sheet on success
6. [ ] Show error banner on failure

**Acceptance Criteria:**
- [ ] Create goal saves to Supabase
- [ ] Update goal modifies existing
- [ ] Offline creates queue for sync
- [ ] Haptic feedback on success
- [ ] Error messages shown clearly

---

## Task 2.5: Goal Detail View

**Day 6**
**Files to Create:**
- `Sources/HabitTracker/Features/Goals/GoalDetailFeature.swift`
- `Sources/HabitTracker/Features/Goals/GoalDetailView.swift`

**Implementation:**
1. [ ] Create GoalDetailFeature
2. [ ] Fetch goal data
3. [ ] Calculate current streak
4. [ ] Fetch recent occurrences
5. [ ] Create GoalDetailView
   - Display streak
   - Show goal details
   - This week completion grid
   - Recent activity list
6. [ ] "Edit" button → navigate to form

**Acceptance Criteria:**
- [ ] Goal detail displays all info
- [ ] Streak calculation correct
- [ ] Recent activity list works
- [ ] Edit button opens form

---

## Task 2.6: Edit & Delete

**Day 7**
**Files to Modify:**
- `GoalFormFeature.swift`
- `GoalFormView.swift`

**Implementation:**
1. [ ] Load existing goal into form
2. [ ] "Delete Goal" button (destructive style)
3. [ ] Delete confirmation alert
4. [ ] Delete via repository
5. [ ] Navigate back on delete
6. [ ] "Pause Goal" toggle

**Acceptance Criteria:**
- [ ] Editing pre-fills form with current values
- [ ] Delete shows confirmation
- [ ] Delete removes goal from all views
- [ ] Pause changes goal status

---

## Task 2.7: Integration

**Day 7 (continued)**
**Files to Modify:**
- `TodayView.swift`
- `AreaDetailView.swift`

**Implementation:**
1. [ ] Add "+" button to Today view → template selection
2. [ ] Add "+" button to Area detail → form with area pre-selected
3. [ ] Tap goal in Today → goal detail
4. [ ] Test full flow: Template → Create → Today → Detail → Edit → Delete

**Acceptance Criteria:**
- [ ] User can create goal from Today view
- [ ] User can create goal from Area view
- [ ] User can view goal details
- [ ] User can edit goals
- [ ] User can delete goals
- [ ] All flows work end-to-end

---

# Phase 3: Water Tracking Implementation

**Duration:** 4 days
**Priority:** P1
**Goal:** Functional water tracking feature
**Design Doc:** See `FEATURE_DESIGNS_COMPREHENSIVE.md`

## Task 3.1: Enhanced Today Widget

**Day 1**
**Files to Modify:**
- `TodayView.swift`

**Implementation:**
1. [ ] Update existing water card
2. [ ] Add quick-add buttons (+100, +250, +500, +1L)
3. [ ] Wire up to measurement repository
4. [ ] Add progress bar animation
5. [ ] Haptic feedback on tap
6. [ ] "View Details" navigation

**Acceptance Criteria:**
- [ ] Quick-add buttons work
- [ ] Progress updates immediately
- [ ] Haptic feedback feels good
- [ ] Navigation to detail view works

---

## Task 3.2: Water Detail View

**Day 2**
**Files to Create:**
- `Sources/HabitTracker/Features/Water/WaterTrackingFeature.swift`
- `Sources/HabitTracker/Features/Water/WaterDetailView.swift`

**Implementation:**
1. [ ] Create WaterTrackingFeature
2. [ ] Define State (target, measurements, progress)
3. [ ] Define Actions (add, delete, refresh)
4. [ ] Implement reducer logic
5. [ ] Create WaterDetailView
   - Progress ring
   - Quick-add buttons
   - Today's log (list)
   - Delete measurements
6. [ ] Wire up to repository

**Acceptance Criteria:**
- [ ] Detail view displays progress
- [ ] Today's log shows all measurements
- [ ] Delete measurement works
- [ ] Progress calculation correct

---

## Task 3.3: Custom Entry & Weekly Chart

**Day 3**
**Files to Create:**
- `Sources/HabitTracker/Features/Water/CustomWaterEntryView.swift`

**Files to Modify:**
- `WaterDetailView.swift`

**Implementation:**
1. [ ] Custom amount input sheet
2. [ ] Time picker (now vs. earlier today)
3. [ ] Validation (amount > 0)
4. [ ] Save custom measurement
5. [ ] Weekly bar chart
   - Fetch last 7 days
   - Display as bars
   - Show average

**Acceptance Criteria:**
- [ ] Custom entry validates input
- [ ] User can backdate measurements
- [ ] Weekly chart displays correctly
- [ ] Average calculation correct

---

## Task 3.4: Settings

**Day 4**
**Files to Create:**
- `Sources/HabitTracker/Features/Water/WaterSettingsFeature.swift`
- `Sources/HabitTracker/Features/Water/WaterSettingsView.swift`

**Implementation:**
1. [ ] Create WaterSettingsFeature
2. [ ] Daily target slider (500mL - 4L)
3. [ ] Unit toggle (mL vs. oz)
4. [ ] Quick-add button customization
5. [ ] Save to UserDefaults
6. [ ] Load settings on launch

**Acceptance Criteria:**
- [ ] User can set custom target
- [ ] Unit conversion works correctly
- [ ] Quick-add buttons customizable
- [ ] Settings persist across launches

---

# Phase 4: Buddy System Implementation

**Duration:** 10 days
**Priority:** P2
**Goal:** Social accountability feature
**Design Doc:** See `FEATURE_DESIGNS_COMPREHENSIVE.md`

## Task 4.1: Domain Models & DTOs

**Days 1-2**
**Files to Create:**
- `Sources/HabitTracker/Domain/Models/GoalMember.swift`
- `Sources/HabitTracker/Domain/Models/OccurrenceMemberStatus.swift`
- `Sources/HabitTracker/Data/DTOs/GoalMemberDTO.swift`
- `Sources/HabitTracker/Data/DTOs/OccurrenceMemberStatusDTO.swift`

**Implementation:**
1. [ ] Create GoalMember model
2. [ ] Create OccurrenceMemberStatus model
3. [ ] Create corresponding DTOs
4. [ ] Add toDomain() conversions
5. [ ] Add validation

**Acceptance Criteria:**
- [ ] Models compile
- [ ] DTOs match database schema
- [ ] Conversions work correctly

---

## Task 4.2: Repositories

**Days 3-4**
**Files to Create:**
- `Sources/HabitTracker/Data/Repositories/Supabase/SupabaseBuddyRepository.swift`

**Implementation:**
1. [ ] Create repository protocol
2. [ ] Implement Supabase repository
3. [ ] invite(goalId, userId) method
4. [ ] accept(inviteId) method
5. [ ] fetchBuddies(userId) method
6. [ ] fetchMemberStatuses(occurrenceId) method
7. [ ] updateMemberStatus() method
8. [ ] leaveGoal() method
9. [ ] Add to dependency injection

**Acceptance Criteria:**
- [ ] All repository methods work
- [ ] Invitations save to database
- [ ] Member statuses fetch correctly

---

## Task 4.3: Buddy List UI

**Day 5**
**Files to Create:**
- `Sources/HabitTracker/Features/Buddy/BuddySystemFeature.swift`
- `Sources/HabitTracker/Features/Buddy/BuddyListView.swift`

**Implementation:**
1. [ ] Create BuddySystemFeature
2. [ ] Fetch buddies
3. [ ] Display active buddies list
4. [ ] Display pending invites
5. [ ] Cancel invite action

**Acceptance Criteria:**
- [ ] Buddy list displays
- [ ] Pending invites shown
- [ ] Cancel invite works

---

## Task 4.4: Invite Flow

**Day 6**
**Files to Create:**
- `Sources/HabitTracker/Features/Buddy/InviteBuddyFeature.swift`
- `Sources/HabitTracker/Features/Buddy/InviteBuddyView.swift`

**Implementation:**
1. [ ] Create invite sheet
2. [ ] Search buddies
3. [ ] Select buddy
4. [ ] Send invitation
5. [ ] Confirmation message

**Acceptance Criteria:**
- [ ] User can search friends
- [ ] User can send invite
- [ ] Invite appears in recipient's list

---

## Task 4.5: Shared Goal UI

**Days 7-8**
**Files to Create:**
- `Sources/HabitTracker/Features/Buddy/SharedGoalFeature.swift`
- `Sources/HabitTracker/Features/Buddy/SharedGoalDetailView.swift`

**Files to Modify:**
- `TodayView.swift`

**Implementation:**
1. [ ] Enhance Today view for shared goals
   - Show member count badge
   - Display buddy progress
2. [ ] Create SharedGoalDetailView
   - Team streak
   - Member list with statuses
   - Send nudge feature
3. [ ] Update occurrence completion
   - Per-member tracking
   - Goal completes when all members finish

**Acceptance Criteria:**
- [ ] Shared goals display member count
- [ ] Detail view shows all members
- [ ] Per-member completion works
- [ ] Team streak calculated correctly

---

## Task 4.6: Notifications

**Days 9-10**
**Files to Create:**
- `Sources/HabitTracker/Infrastructure/Notifications/NotificationService.swift`

**Implementation:**
1. [ ] Set up push notifications
2. [ ] Buddy completed goal notification
3. [ ] Invitation received notification
4. [ ] Nudge notification
5. [ ] Badge counts

**Acceptance Criteria:**
- [ ] User receives buddy notifications
- [ ] Notifications navigate to correct screen
- [ ] Badge counts update

---

# Phase 5: Reflections Implementation

**Duration:** 5 days
**Priority:** P3
**Goal:** Daily journaling feature
**Design Doc:** See `FEATURE_DESIGNS_COMPREHENSIVE.md`

## Task 5.1: Templates

**Day 1**
**Implementation:**
1. [ ] Load default templates from database
2. [ ] Create template selection UI
3. [ ] Template model integration

---

## Task 5.2: Editor UI

**Days 2-3**
**Files to Create:**
- `Sources/HabitTracker/Features/Reflections/ReflectionEditorFeature.swift`
- `Sources/HabitTracker/Features/Reflections/ReflectionEditorView.swift`

**Implementation:**
1. [ ] Multi-page form
2. [ ] Navigation (previous/next)
3. [ ] Text input handling
4. [ ] Mood selector
5. [ ] Goal linking

**Acceptance Criteria:**
- [ ] User can navigate pages
- [ ] Text input saves per page
- [ ] Mood selection works
- [ ] Goals can be linked

---

## Task 5.3: Save Logic

**Day 4**
**Files to Create:**
- `Sources/HabitTracker/Data/Repositories/Supabase/SupabaseReflectionRepository.swift`

**Implementation:**
1. [ ] Create repository
2. [ ] Save reflection
3. [ ] Page content serialization
4. [ ] Linked goals persistence

**Acceptance Criteria:**
- [ ] Reflections save to database
- [ ] All pages saved correctly
- [ ] Linked goals associated

---

## Task 5.4: History View

**Day 5**
**Files to Create:**
- `Sources/HabitTracker/Features/Reflections/ReflectionHistoryFeature.swift`
- `Sources/HabitTracker/Features/Reflections/ReflectionHistoryView.swift`

**Implementation:**
1. [ ] Display list of reflections
2. [ ] Streak calculation
3. [ ] Stats display

**Acceptance Criteria:**
- [ ] User can view past reflections
- [ ] Streak calculated correctly
- [ ] Stats display accurate

---

# Phase 6: Testing & Polish

**Duration:** 5 days
**Priority:** P0
**Goal:** Production-ready polish

## Task 6.1: Unit Testing

**Days 1-2**

**Implementation:**
1. [ ] Goal creation/edit/delete tests
2. [ ] Water tracking calculation tests
3. [ ] Buddy system integration tests
4. [ ] Reflection save/load tests
5. [ ] Repository tests
6. [ ] TCA reducer tests

**Target:** 80%+ code coverage

---

## Task 6.2: Integration Testing

**Day 3**

**Implementation:**
1. [ ] Full user flows
   - Sign up → create area → create goal → complete → view insights
2. [ ] Offline → online sync
3. [ ] Buddy invite → accept → complete flow
4. [ ] Reflection → link to goal flow

---

## Task 6.3: UI Testing

**Day 4**

**Implementation:**
1. [ ] Automated UI tests
2. [ ] Manual testing checklist
3. [ ] Device testing (iPhone SE, Pro Max, iPad)
4. [ ] Dark mode testing
5. [ ] Accessibility testing (VoiceOver)
6. [ ] Dynamic Type testing

---

## Task 6.4: Performance & Polish

**Day 5**

**Implementation:**
1. [ ] Instruments profiling
2. [ ] Animation smoothness
3. [ ] Network request optimization
4. [ ] Image caching
5. [ ] App launch time optimization

---

# Progress Tracking

## Overall Progress

| Phase | Tasks | Completed | Progress | Status |
|-------|-------|-----------|----------|--------|
| Phase 1: Bug Fixes | 17 | 0 | 0% | ⏳ Not Started |
| Phase 2: Goals | 7 | 0 | 0% | ⏳ Not Started |
| Phase 3: Water | 4 | 0 | 0% | ⏳ Not Started |
| Phase 4: Buddy | 6 | 0 | 0% | ⏳ Not Started |
| Phase 5: Reflections | 4 | 0 | 0% | ⏳ Not Started |
| Phase 6: Testing | 4 | 0 | 0% | ⏳ Not Started |
| **TOTAL** | **42** | **0** | **0%** | 🔴 **NOT PRODUCTION READY** |

## Daily Progress Log

### Week 1: Bug Fixes
- [ ] Day 1: Bugs 1.1-1.3 (Force unwraps)
- [ ] Day 2: Bugs 1.4-1.6 (TCA & mocks)
- [ ] Day 3: Bugs 1.7-1.9 (Duplicates & validation)
- [ ] Day 4: Bugs 1.10-1.11 + P1 bugs
- [ ] Day 5: Remaining P1/P2 bugs

### Week 2: Goals Management
- [ ] Day 6: Task 2.1 (Templates)
- [ ] Day 7-8: Task 2.2 (Goal form)
- [ ] Day 9: Task 2.3 (Advanced options)
- [ ] Day 10: Task 2.4 (Save logic)
- [ ] Day 11: Task 2.5 (Detail view)
- [ ] Day 12: Tasks 2.6-2.7 (Edit/delete/integration)

### Week 3: Water Tracking
- [ ] Day 13: Task 3.1 (Widget)
- [ ] Day 14: Task 3.2 (Detail view)
- [ ] Day 15: Task 3.3 (Custom entry)
- [ ] Day 16: Task 3.4 (Settings)

### Weeks 4-5: Buddy System
- [ ] Days 17-18: Task 4.1 (Models)
- [ ] Days 19-20: Task 4.2 (Repositories)
- [ ] Day 21: Task 4.3 (List UI)
- [ ] Day 22: Task 4.4 (Invite flow)
- [ ] Days 23-24: Task 4.5 (Shared goal UI)
- [ ] Days 25-26: Task 4.6 (Notifications)

### Week 6: Reflections
- [ ] Day 27: Task 5.1 (Templates)
- [ ] Days 28-29: Task 5.2 (Editor)
- [ ] Day 30: Task 5.3 (Save logic)
- [ ] Day 31: Task 5.4 (History)

### Week 7: Testing & Polish
- [ ] Days 32-33: Task 6.1 (Unit tests)
- [ ] Day 34: Task 6.2 (Integration tests)
- [ ] Day 35: Task 6.3 (UI tests)
- [ ] Day 36: Task 6.4 (Performance)

### Week 8: Buffer & Launch Prep
- [ ] Days 37-40: Bug fixes from testing
- [ ] Days 37-40: Final polish
- [ ] Days 37-40: App Store preparation

---

# Risk Management

## Critical Risks

### Risk 1: Timeline Slip
**Probability:** HIGH
**Impact:** HIGH
**Mitigation:**
- Buffer week included (Week 8)
- Can cut Reflections feature if needed (P3)
- Can launch without Buddy System initially (P2)

### Risk 2: Complex Buddy System
**Probability:** MEDIUM
**Impact:** HIGH
**Mitigation:**
- Design complete upfront
- Database schema already exists
- Can simplify to 1-on-1 sharing initially

### Risk 3: Performance Issues
**Probability:** MEDIUM
**Impact:** MEDIUM
**Mitigation:**
- Profiling in Phase 6
- Offline-first architecture helps
- Cache layer reduces server load

### Risk 4: Sync Conflicts
**Probability:** MEDIUM
**Impact:** HIGH
**Mitigation:**
- Last-write-wins strategy
- Conflict resolution already implemented
- Comprehensive testing in Phase 6

## Scope Management

### Must Have (MVP)
- ✅ All P0 bug fixes
- ✅ Goals Management (Phase 2)
- ✅ Water Tracking (Phase 3)

### Should Have (V1)
- ✅ All P1 bug fixes
- ⚠️ Buddy System (can defer to V1.1)
- ⚠️ Reflections (can defer to V1.1)

### Nice to Have (V2)
- Widgets
- Apple Watch
- Advanced analytics

---

# Success Criteria

## Phase 1 Success
- [ ] All P0 bugs fixed
- [ ] All P1 bugs fixed
- [ ] No force unwraps in production code
- [ ] No silent error handling
- [ ] No compiler warnings

## Phase 2 Success
- [ ] User can create goal in <60 seconds
- [ ] User can edit existing goals
- [ ] User can delete goals
- [ ] Goals sync to Supabase
- [ ] Offline goal creation works

## Phase 3 Success
- [ ] User can log water with one tap
- [ ] Progress bar updates immediately
- [ ] User can view water history
- [ ] User can set custom target

## Phase 4 Success
- [ ] User can invite buddy to goal
- [ ] Per-member completion tracking works
- [ ] Notifications work
- [ ] Realtime updates work

## Phase 5 Success
- [ ] User can write daily reflection
- [ ] Multi-page templates work
- [ ] Reflections save to database

## Phase 6 Success
- [ ] 80%+ code coverage
- [ ] All critical flows tested
- [ ] Performance benchmarks met
- [ ] No crashes in testing
- [ ] Ready for TestFlight

## Overall Success (Production Ready)
- [ ] All phases complete
- [ ] All acceptance criteria met
- [ ] 294 unit tests passing
- [ ] Integration tests passing
- [ ] UI tests passing
- [ ] Performance acceptable (<2s launch, 60fps scrolling)
- [ ] Accessibility verified
- [ ] Dark mode working
- [ ] TestFlight beta successful (50+ users, <5% crash rate)

---

**Document Version:** 1.0
**Last Updated:** 2025-11-18
**Next Review:** After each phase completion
**Status:** 🔴 NOT PRODUCTION READY → 🟡 IN PROGRESS (when Phase 1 starts)

---

# Quick Reference

## Command to run tests
```bash
swift test --parallel
```

## Command to run app
```bash
open HabitTracker.xcodeproj
# Product > Run (Cmd+R)
```

## Environment variables needed
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## Git workflow
```bash
# After completing each task
git add .
git commit -m "feat: [task description]"

# After completing each phase
git push -u origin claude/swiftui-app-planning-01Fxme8XNSYDtz7acgPdxC8i
```
