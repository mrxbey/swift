# HabitTracker - Bugs & Improvements

**Last Updated**: November 21, 2025
**Status**: 4 Critical, 3 High, 3 Medium, 2 Low
**Total Items**: 12

---

## 🚨 Critical Bugs (Block Production)

### BUG-001: Mock Repositories in Production [P0]
**Severity**: 🔴 CRITICAL
**Priority**: P0 - BLOCK PRODUCTION
**Impact**: Data Loss, Sync Failure
**Effort**: 30 minutes

**Description**:
ReflectionRepository and ProgramRepository use `MockRepository` for `liveValue` instead of `SupabaseRepository`. This means production will use in-memory mock data instead of persisting to Supabase.

**Location**:
```
File: HabitTracker/Sources/HabitTracker/Data/Dependencies/DependencyValues+Repositories.swift
Lines: 115-132
```

**Current Code**:
```swift
private enum ReflectionRepositoryKey: DependencyKey {
    static let liveValue: ReflectionRepository = MockReflectionRepository()
    static let testValue: ReflectionRepository = MockReflectionRepository()
    static let previewValue: ReflectionRepository = MockReflectionRepository()
}

private enum ProgramRepositoryKey: DependencyKey {
    static let liveValue: ProgramRepository = MockProgramRepository()
    static let testValue: ProgramRepository = MockProgramRepository()
    static let previewValue: ProgramRepository = MockProgramRepository()
}
```

**Fix**:
```swift
private enum ReflectionRepositoryKey: DependencyKey {
    static let liveValue: ReflectionRepository = {
        do {
            return try SupabaseReflectionRepository()
        } catch {
            fatalError("Failed to initialize SupabaseReflectionRepository: \(error)")
        }
    }()
    static let testValue: ReflectionRepository = MockReflectionRepository()
    static let previewValue: ReflectionRepository = MockReflectionRepository()
}

private enum ProgramRepositoryKey: DependencyKey {
    static let liveValue: ProgramRepository = {
        do {
            return try SupabaseProgramRepository()
        } catch {
            fatalError("Failed to initialize SupabaseProgramRepository: \(error)")
        }
    }()
    static let testValue: ProgramRepository = MockProgramRepository()
    static let previewValue: ProgramRepository = MockProgramRepository()
}
```

**Verification Steps**:
1. Create a reflection in the app
2. Restart the app
3. Verify reflection still exists (data persisted)
4. Adopt a program
5. Restart the app
6. Verify goals were created and still exist

**Status**: 🔴 Not Fixed

---

### BUG-002: AreaStatistics Field Name Mismatch [P0]
**Severity**: 🔴 CRITICAL
**Priority**: P0 - BLOCK COMPILATION
**Impact**: Test Compilation Failure
**Effort**: 15 minutes

**Description**:
MockAreaRepository.fetchStatistics uses wrong field names for AreaStatistics struct. This causes compilation errors when using the mock repository in tests.

**Location**:
```
File: HabitTracker/Sources/HabitTracker/Data/Dependencies/DependencyValues+Repositories.swift
Lines: 293-302
```

**Current Code**:
```swift
public func fetchStatistics(for id: UUID) async throws -> AreaStatistics {
    AreaStatistics(
        areaId: id,
        activeGoalsCount: 5,      // ❌ Wrong field name
        completedGoalsCount: 10,  // ❌ Wrong field name
        totalPoints: 150,         // ❌ Wrong field name
        completionRate: 0.75,
        currentStreak: 7          // ❌ Wrong field name
    )
}
```

**Fix** (need to verify actual AreaStatistics struct):
```swift
public func fetchStatistics(for id: UUID) async throws -> AreaStatistics {
    AreaStatistics(
        areaId: id,
        totalGoals: 15,
        activeGoals: 5,
        totalCompletions: 10,
        completionRate: 0.75
    )
}
```

**Action Required**:
1. Check AreaStatistics struct definition
2. Update MockAreaRepository.fetchStatistics to use correct field names
3. Run tests to verify compilation

**Status**: 🔴 Not Fixed

---

### BUG-003: GoalEditorFeature is Placeholder [P0]
**Severity**: 🔴 CRITICAL
**Priority**: P0 - BLOCK CORE FEATURE
**Impact**: Cannot Create/Edit Goals
**Effort**: 4-6 hours

**Description**:
GoalEditorFeature is a placeholder with no implementation. Users cannot create new goals or edit existing goals from the Today view.

**Location**:
```
File: HabitTracker/Sources/HabitTracker/Features/Today/TodayFeature.swift
Lines: 300-320
```

**Current Implementation**:
```swift
@Reducer
public struct GoalEditorFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Mode { case create, edit(Goal) }
        public var mode: Mode
        public init(mode: Mode) { self.mode = mode }
    }

    public enum Action: Sendable {
        case delegate(Delegate)
        public enum Delegate: Sendable {
            case goalSaved(Goal)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none  // ❌ No implementation
        }
    }
}
```

**Required Implementation**:
- [ ] State properties: title, emoji, areaId, kind, schedule, points, status
- [ ] Actions: titleChanged, emojiSelected, areaSelected, kindSelected, scheduleChanged, pointsChanged, saveTapped, cancelTapped
- [ ] Dependency: @Dependency(\.goalRepository), @Dependency(\.dismiss)
- [ ] Save logic: create new goal or update existing goal
- [ ] Validation: ensure title not empty, area selected
- [ ] Error handling: show alert on save failure

**UI Requirements**:
- Text field for goal title
- Emoji picker or text field
- Area picker (dropdown or sheet)
- Goal kind picker (habit, task, measure)
- Schedule configuration (daily, weekly, custom)
- Points per completion input
- Save/Cancel buttons

**Status**: 🔴 Not Started

---

### BUG-004: OccurrenceDetailFeature is Placeholder [P0]
**Severity**: 🔴 CRITICAL
**Priority**: P0 - BLOCK CORE FEATURE
**Impact**: Cannot View/Edit Occurrence Details
**Effort**: 2-3 hours

**Description**:
OccurrenceDetailFeature is a placeholder with no implementation. Users cannot view occurrence details or add notes/modify properties.

**Location**:
```
File: HabitTracker/Sources/HabitTracker/Features/Today/TodayFeature.swift
Lines: 322-342
```

**Current Implementation**:
```swift
@Reducer
public struct OccurrenceDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public var occurrence: GoalOccurrence
        public init(occurrence: GoalOccurrence) {
            self.occurrence = occurrence
        }
    }

    public enum Action: Sendable {
        case dismiss
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none  // ❌ No implementation
        }
    }
}
```

**Required Implementation**:
- [ ] State: occurrence, notes, isEditing
- [ ] Actions: addNote, saveNote, changeStatus, undoCompletion, dismiss
- [ ] Dependency: @Dependency(\.occurrenceRepository)
- [ ] Display: goal title, scheduled date, status, completion count, points earned
- [ ] Edit: add/edit notes, change status
- [ ] Actions: undo completion, skip, reschedule

**UI Requirements**:
- Goal title and emoji
- Scheduled date and time
- Current status (pending, completed, skipped)
- Completion count / target count
- Points earned
- Notes text view
- Action buttons (complete, skip, undo)

**Status**: 🔴 Not Started

---

### BUG-005: Account Deletion Not Implemented [P0]
**Severity**: 🔴 CRITICAL
**Priority**: P0 - LEGAL/COMPLIANCE
**Impact**: GDPR Non-Compliance, App Store Requirement
**Effort**: 2-3 hours

**Description**:
Delete Account button exists but only signs out the user. Actual account deletion is not implemented, leaving user data in the database.

**Location**:
```
File: HabitTracker/Sources/HabitTracker/Features/Settings/SettingsView.swift
Lines: 265-275
```

**Current Code**:
```swift
case .deleteAccountConfirmation(.presented(.confirmDeleteAccount)):
    return .run { send in
        await send(.deleteAccountResponse(
            TaskResult {
                // TODO: Implement account deletion API call
                // For now, just sign out
                try await authService.signOut()
            }
        ))
    }
```

**Required Implementation**:

**Step 1**: Create Supabase RPC function
```sql
-- Run in Supabase SQL editor
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Delete user data in correct order (foreign keys)
    DELETE FROM measurements WHERE user_id = auth.uid();
    DELETE FROM goal_occurrences WHERE user_id = auth.uid();
    DELETE FROM goals WHERE user_id = auth.uid();
    DELETE FROM reflections WHERE user_id = auth.uid();
    DELETE FROM areas WHERE user_id = auth.uid();
    DELETE FROM profiles WHERE id = auth.uid();

    -- Delete auth user (if permissions allow)
    -- This may require admin privileges
END;
$$;
```

**Step 2**: Add method to AuthService
```swift
// In AuthService.swift
public func deleteAccount() async throws {
    // Call RPC to delete all user data
    try await client.rpc("delete_user_account").execute()

    // Delete auth account
    // Note: Supabase doesn't provide direct account deletion in SDK
    // May need to call admin API or handle via RPC

    // Sign out
    try await signOut()
}
```

**Step 3**: Update SettingsFeature
```swift
case .deleteAccountConfirmation(.presented(.confirmDeleteAccount)):
    return .run { send in
        await send(.deleteAccountResponse(
            TaskResult {
                try await authService.deleteAccount()
            }
        ))
    }
```

**Legal Requirements**:
- GDPR: Right to erasure (Article 17)
- Apple App Store: Account deletion in-app
- Must delete all user data within reasonable time

**Status**: 🔴 Not Implemented

---

## ⚠️ High Priority Bugs

### BUG-006: Missing Error Alert Presentation [P1]
**Severity**: 🟠 HIGH
**Priority**: P1 - UX CRITICAL
**Impact**: Users Don't Know When Operations Fail
**Effort**: 1-2 hours

**Description**:
Five error cases silently fail without showing alerts to users, leading to confusion when operations like sync or export fail.

**Locations**:
1. `SettingsView.swift:267` - Export response failure
2. `SettingsView.swift:287` - Sync response failure
3. `SettingsView.swift:330` - Sign out response failure (duplicate at 261)
4. `SettingsView.swift:350` - Delete account response failure (duplicate at 281)
5. `ProgramsView.swift:542` - Program adoption failure

**Current Pattern**:
```swift
case .exportResponse(.failure):
    // TODO: Show error alert
    return .none
```

**Fix Pattern**:
Add alert state to feature:
```swift
@ObservableState
struct State: Equatable {
    // ... existing state
    @Presents var errorAlert: AlertState<Action.ErrorAlert>?
}

enum Action: Sendable {
    // ... existing actions
    case errorAlert(PresentationAction<ErrorAlert>)

    enum ErrorAlert: Sendable {
        case dismiss
    }
}

// In reducer:
case .exportResponse(.failure(let error)):
    state.errorAlert = AlertState {
        TextState("Export Failed")
    } message: {
        TextState(error.localizedDescription)
    }
    return .none

// In view:
.alert($store.scope(state: \.errorAlert, action: \.errorAlert))
```

**Apply to all 5 locations**

**Status**: 🟠 Not Fixed

---

### BUG-007: Incomplete Data Export [P1]
**Severity**: 🟠 HIGH
**Priority**: P1 - GDPR COMPLIANCE
**Impact**: Users Cannot Export Their Data
**Effort**: 2-3 hours

**Description**:
Data export only exports metadata (email, timestamp), not actual user data (goals, occurrences, etc.).

**Location**:
```
File: HabitTracker/Sources/HabitTracker/Features/Settings/SettingsView.swift
Lines: 241-260
```

**Current Code**:
```swift
case .exportDataTapped:
    return .run { send in
        await send(.exportResponse(
            TaskResult {
                // TODO: Implement full data export
                let exportData: [String: Any] = [
                    "exported_at": ISO8601DateFormatter().string(from: Date()),
                    "user_email": await authService.currentUser()?.email ?? "",
                    "version": "1.0.0"
                ]
                let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("habit_tracker_export_\(Date().timeIntervalSince1970).json")
                try jsonData.write(to: fileURL)
                return fileURL
            }
        ))
    }
```

**Required Fix**:
```swift
case .exportDataTapped:
    return .run { send in
        await send(.exportResponse(
            TaskResult {
                // Fetch all user data
                let user = await authService.currentUser()
                let profile = try? await profileRepository.fetch(user?.id)
                let areas = try? await areaRepository.fetchAll()
                let goals = try? await goalRepository.fetchAll()
                let reflections = try? await reflectionRepository.fetchAll()

                // Get date range for occurrences/measurements (last 365 days)
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -365, to: endDate)!
                let occurrences = try? await occurrenceRepository.fetchOccurrences(from: startDate, to: endDate)
                let measurements = try? await measurementRepository.fetchMeasurements(from: startDate, to: endDate)

                // Build export structure
                let exportData: [String: Any] = [
                    "exported_at": ISO8601DateFormatter().string(from: Date()),
                    "version": "1.0.0",
                    "user": [
                        "email": user?.email ?? "",
                        "id": user?.id.uuidString ?? ""
                    ],
                    "profile": profile.map { /* convert to dict */ } ?? [:],
                    "areas": areas?.map { /* convert to dict */ } ?? [],
                    "goals": goals?.map { /* convert to dict */ } ?? [],
                    "occurrences": occurrences?.map { /* convert to dict */ } ?? [],
                    "measurements": measurements?.map { /* convert to dict */ } ?? [],
                    "reflections": reflections?.map { /* convert to dict */ } ?? []
                ]

                let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("habittracker_export_\(Date().timeIntervalSince1970).json")
                try jsonData.write(to: fileURL)
                return fileURL
            }
        ))
    }
```

**Note**: May need to add methods to repositories:
- `profileRepository.fetch(_ userId:)`
- `occurrenceRepository.fetchOccurrences(from:to:)`
- `measurementRepository.fetchMeasurements(from:to:)`

**Status**: 🟠 Not Fixed

---

### BUG-008: fatalError in Production Code [P1]
**Severity**: 🟠 HIGH
**Priority**: P1 - RELIABILITY
**Impact**: App Crashes Instead of Error Handling
**Effort**: 3-4 hours

**Description**:
13 instances of `fatalError` in production code that will crash the app instead of handling errors gracefully.

**Locations**:

**Category 1: Dependency Initialization** (9 instances)
```
File: DependencyValues+Repositories.swift
Lines: 155, 163, 171, 183, 193, 203, 217, 229, 241
```

**Category 2: Config Validation** (4 instances)
```
File: Config.swift
Lines: 75, 108, 144, 179
```

**Current Pattern**:
```swift
static let liveValue: CacheService = {
    do {
        return try CacheService()
    } catch {
        fatalError("Failed to initialize CacheService: \(error)")
    }
}()
```

**Fix Option 1: Fallback Values**
```swift
static let liveValue: CacheService = {
    do {
        return try CacheService()
    } catch {
        Logger.app.error("Failed to initialize CacheService: \(error)")
        // Return in-memory only version as fallback
        return try! CacheService(inMemoryOnly: true)
    }
}()
```

**Fix Option 2: App-Level Error Handling**
```swift
// In AppFeature, add initialization check
case .task:
    return .run { send in
        do {
            // Validate all dependencies can initialize
            _ = try CacheService()
            _ = try SyncEngine(...)
            await send(.initializationSucceeded)
        } catch {
            await send(.initializationFailed(error))
        }
    }
```

**For Config.swift**:
```swift
// Instead of fatalError, show error screen
guard !supabaseURL.isEmpty else {
    return ConfigurationError.missingSupabaseURL
}

// In App:
if case .error(let config Error) = appState {
    ConfigurationErrorView(error: configError)
        .onAppear {
            Logger.app.error("Configuration error: \(configError)")
        }
}
```

**Status**: 🟠 Not Fixed

---

## 🟡 Medium Priority Issues

### ISSUE-009: Missing Share Sheet for Export [P2]
**Severity**: 🟡 MEDIUM
**Priority**: P2 - UX IMPROVEMENT
**Impact**: User Cannot Share Exported File
**Effort**: 30 minutes

**Description**:
Data export creates file but doesn't present share sheet. User has no way to access the exported file.

**Location**:
```
File: SettingsView.swift
Lines: 263-265
```

**Current Code**:
```swift
case .exportResponse(.success(let fileURL)):
    // TODO: Present share sheet with the exported file
    return .none
```

**Fix**:
```swift
// Add to State:
@Presents var shareSheet: ShareSheetState?

struct ShareSheetState: Equatable {
    let fileURL: URL
}

// In reducer:
case .exportResponse(.success(let fileURL)):
    state.shareSheet = ShareSheetState(fileURL: fileURL)
    return .none

// In view:
.sheet(item: $store.scope(state: \.shareSheet, action: \.shareSheet)) { store in
    ActivityViewController(activityItems: [store.fileURL])
}

// Helper:
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
```

**Status**: 🟡 Not Fixed

---

### ISSUE-010: Water Progress Not Implemented [P2]
**Severity**: 🟡 MEDIUM
**Priority**: P2 - FEATURE INCOMPLETE
**Impact**: Water Tracking Not Functional
**Effort**: 2-3 hours

**Description**:
Water progress feature has placeholder comment but no implementation.

**Location**:
```
File: TodayFeature.swift
Lines: 115-117
```

**Current Code**:
```swift
// Water progress can be fetched if we have a water goal
// For now, skip water progress until we identify the water goal
```

**Required Implementation**:
1. Identify water goal (kind == .measure, title contains "water" or custom flag)
2. Fetch today's measurements for water goal
3. Calculate total consumed (sum of measurements)
4. Get target from goal.measurementTarget
5. Display progress ring or bar
6. Add quick-add buttons for common amounts (250ml, 500ml, 1L)

**Status**: 🟡 Not Started

---

### ISSUE-011: Recommendation Tapping No-op [P2]
**Severity**: 🟡 MEDIUM
**Priority**: P2 - UX IMPROVEMENT
**Impact**: Tapping Recommendations Does Nothing
**Effort**: 1 hour

**Description**:
Recommendations are displayed but tapping them does nothing.

**Location**:
```
File: TodayFeature.swift
Lines: 226-228
```

**Current Code**:
```swift
case let .recommendationTapped(goal):
    // Could show goal detail or quick-add
    return .none
```

**Possible Implementations**:

**Option 1: Quick Add**
```swift
case let .recommendationTapped(goal):
    // Create occurrence for today if none exists
    return .run { send in
        let occurrence = try await occurrenceRepository.createOccurrence(
            for: goal.id,
            on: Date()
        )
        await send(.refresh)
    }
```

**Option 2: Show Detail**
```swift
case let .recommendationTapped(goal):
    state.goalDetail = GoalDetailFeature.State(goal: goal)
    return .none
```

**Decision**: Quick Add makes more sense for Today view

**Status**: 🟡 Not Fixed

---

## 📝 Low Priority Issues

### ISSUE-012: External Links are Placeholders [P3]
**Severity**: 📝 LOW
**Priority**: P3 - POLISH
**Impact**: Dead Links in Settings
**Effort**: 5 minutes

**Description**:
Privacy policy, terms of service, and support links point to example.com placeholders.

**Location**:
```
File: SettingsView.swift
Lines: 12-15
```

**Current Code**:
```swift
private enum ExternalLinks {
    static let privacyPolicy = URL(string: "https://example.com/privacy")
    static let termsOfService = URL(string: "https://example.com/terms")
    static let support = URL(string: "https://example.com/support")
}
```

**Fix**:
Replace with actual URLs before launch:
```swift
private enum ExternalLinks {
    static let privacyPolicy = URL(string: "https://habittracker.app/privacy")
    static let termsOfService = URL(string: "https://habittracker.app/terms")
    static let support = URL(string: "https://habittracker.app/support")
}
```

**Status**: 📝 Not Fixed

---

## 💡 Improvement Suggestions

### IMPROVE-001: Add Analytics Integration
**Priority**: P3
**Effort**: 4-6 hours

Add Firebase Analytics or similar to track:
- User engagement metrics
- Feature usage
- Crash reporting
- Performance monitoring

### IMPROVE-002: Add Local Notifications
**Priority**: P2
**Effort**: 6-8 hours

Implement reminder notifications:
- Daily reminder at user-configured time
- Goal-specific reminders
- Streak reminder ("Don't break your streak!")
- Completion celebration

### IMPROVE-003: Reflection UI Implementation
**Priority**: P2
**Effort**: 8-12 hours

Create full reflection feature:
- Reflection list view with filters
- Reflection editor with mood/tags
- Search reflections
- Link reflections to goals/areas

### IMPROVE-004: Accessibility Audit
**Priority**: P1
**Effort**: 4-6 hours

Ensure accessibility compliance:
- VoiceOver support
- Dynamic Type support
- Color contrast ratios
- Haptic feedback
- Accessibility labels

### IMPROVE-005: Performance Profiling
**Priority**: P1
**Effort**: 2-3 hours

Profile with Instruments:
- Memory leaks
- CPU usage
- Network efficiency
- Database query optimization
- UI responsiveness

### IMPROVE-006: Comprehensive Testing
**Priority**: P1
**Effort**: 8-12 hours

Increase test coverage:
- Unit tests for all reducers
- Integration tests for key flows
- UI tests for critical paths
- Performance tests
- Target: 80%+ coverage

---

## Priority Summary

| Priority | Count | Total Effort |
|----------|-------|--------------|
| P0 - Block Production | 5 bugs | 10-14 hours |
| P1 - Critical | 3 bugs | 6-9 hours |
| P2 - High | 3 issues | 3.5-6.5 hours |
| P3 - Low | 1 issue | 5 minutes |
| P1-P3 Improvements | 6 items | 32-47 hours |

**Critical Path to Launch**: 16-23 hours (P0 + P1)
**Full Polish**: 48-70 hours (All items)

---

## Fix Strategy

### Week 1: Blockers
- [ ] BUG-001: Fix mock repositories (30 min)
- [ ] BUG-002: Fix AreaStatistics (15 min)
- [ ] BUG-005: Implement account deletion (2-3 hours)
- [ ] BUG-003: Implement GoalEditorFeature (4-6 hours)
- [ ] BUG-004: Implement OccurrenceDetailFeature (2-3 hours)

**Total**: 10-14 hours

### Week 2: Critical
- [ ] BUG-006: Add error alerts (1-2 hours)
- [ ] BUG-007: Complete data export (2-3 hours)
- [ ] BUG-008: Remove fatalError instances (3-4 hours)

**Total**: 6-9 hours

### Week 3: High Priority
- [ ] ISSUE-009: Add share sheet (30 min)
- [ ] ISSUE-010: Implement water progress (2-3 hours)
- [ ] ISSUE-011: Fix recommendation tapping (1 hour)
- [ ] IMPROVE-004: Accessibility audit (4-6 hours)
- [ ] IMPROVE-005: Performance profiling (2-3 hours)
- [ ] IMPROVE-006: Comprehensive testing (8-12 hours)

**Total**: 18-25.5 hours

### Week 4: Polish & Launch Prep
- [ ] ISSUE-012: Update external links (5 min)
- [ ] IMPROVE-003: Reflection UI (8-12 hours)
- [ ] App Store preparation
- [ ] Documentation updates
- [ ] Beta testing

---

**Report Generated**: November 21, 2025
**Next Update**: After P0 fixes completed
