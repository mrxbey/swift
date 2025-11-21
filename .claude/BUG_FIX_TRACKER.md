# HabitTracker Bug Fix Implementation Tracker

**Session Started**: November 21, 2025
**Objective**: Fix all 12 identified issues with enterprise quality
**Approach**: Systematic, one-by-one, no skipping
**Branch**: `claude/audit-context-files-01UVD2KSgx3pZUhq4UW9qAHT`

---

## 🎯 Implementation Strategy

### Phase 1: Critical Fixes (P0) - BLOCK PRODUCTION
**Total**: 5 issues | **Effort**: 10-14 hours | **Status**: 🔴 NOT STARTED

1. **BUG-001**: Mock Repositories in Production (30 min) ⚡
2. **BUG-002**: AreaStatistics Field Mismatch (15 min)
3. **BUG-003**: GoalEditorFeature Placeholder (4-6 hours)
4. **BUG-004**: OccurrenceDetailFeature Placeholder (2-3 hours)
5. **BUG-005**: Account Deletion Not Implemented (2-3 hours)

### Phase 2: High Priority (P1) - UX & COMPLIANCE
**Total**: 3 issues | **Effort**: 6-9 hours | **Status**: ⏳ PENDING

6. **BUG-006**: Missing Error Alerts - 5 instances (1-2 hours)
7. **BUG-007**: Incomplete Data Export (2-3 hours)
8. **BUG-008**: fatalError in Production - 13 instances (3-4 hours)

### Phase 3: Medium Priority (P2) - POLISH
**Total**: 3 issues | **Effort**: 3.5-6.5 hours | **Status**: ⏳ PENDING

9. **ISSUE-009**: Missing Share Sheet (30 min)
10. **ISSUE-010**: Water Progress Not Implemented (2-3 hours)
11. **ISSUE-011**: Recommendation Tapping No-op (1 hour)

### Phase 4: Low Priority (P3) - COSMETIC
**Total**: 1 issue | **Effort**: 5 minutes | **Status**: ⏳ PENDING

12. **ISSUE-012**: External Links Placeholders (5 min)

---

## 📋 Detailed Task List

### 🔴 BUG-001: Mock Repositories in Production [HIGHEST PRIORITY]

**File**: `HabitTracker/Sources/HabitTracker/Data/Dependencies/DependencyValues+Repositories.swift`
**Lines**: 115-132
**Severity**: 🔴 CRITICAL - DATA LOSS
**Effort**: 30 minutes
**Status**: 🔴 NOT STARTED

**Context**:
- ReflectionRepository using MockReflectionRepository for liveValue
- ProgramRepository using MockProgramRepository for liveValue
- Production app will use in-memory mock data
- User data will be lost on app restart
- Sync engine will fail

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

**Required Fix**:
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
1. Build and run app
2. Create a reflection
3. Force quit app
4. Relaunch app
5. Verify reflection still exists
6. Adopt a program
7. Force quit app
8. Relaunch app
9. Verify goals were created and persist

**Completion Criteria**:
- [ ] Code updated
- [ ] App builds successfully
- [ ] Reflection persists after restart
- [ ] Program adoption creates real goals
- [ ] Goals persist after restart
- [ ] No data loss

---

### 🔴 BUG-002: AreaStatistics Field Mismatch

**File**: `HabitTracker/Sources/HabitTracker/Data/Dependencies/DependencyValues+Repositories.swift`
**Lines**: 293-302
**Severity**: 🔴 CRITICAL - COMPILATION ERROR
**Effort**: 15 minutes
**Status**: 🔴 NOT STARTED

**Context**:
- MockAreaRepository.fetchStatistics uses wrong field names
- Will cause compilation error when using mock repository
- Tests will fail to compile

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

**Action Required**:
1. Find actual AreaStatistics struct definition
2. Check correct field names
3. Update MockAreaRepository to use correct names

**Verification Steps**:
1. Build test target
2. Verify no compilation errors
3. Run area-related tests
4. Verify tests pass

**Completion Criteria**:
- [ ] Find AreaStatistics struct definition
- [ ] Update field names to match
- [ ] Code compiles successfully
- [ ] Tests compile successfully

---

### 🔴 BUG-003: GoalEditorFeature Placeholder

**File**: `HabitTracker/Sources/HabitTracker/Features/Today/TodayFeature.swift`
**Lines**: 300-320
**Severity**: 🔴 CRITICAL - BROKEN FEATURE
**Effort**: 4-6 hours
**Status**: 🔴 NOT STARTED

**Context**:
- GoalEditorFeature is placeholder with no implementation
- Users cannot create new goals
- Users cannot edit existing goals
- Core functionality blocked

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

**State Properties**:
- title: String
- emoji: String?
- areaId: UUID?
- kind: GoalKind
- schedule: GoalSchedule
- pointsPerCompletion: Int
- isValid: Bool (computed)
- isSaving: Bool
- availableAreas: [Area]
- showAreaPicker: Bool
- showEmojiPicker: Bool
- errorMessage: String?

**Actions**:
- task
- areasLoaded([Area])
- titleChanged(String)
- emojiSelected(String?)
- emojiPickerTapped
- areaSelected(UUID)
- areaPickerTapped
- kindSelected(GoalKind)
- scheduleChanged(GoalSchedule)
- pointsChanged(Int)
- saveTapped
- saveResponse(TaskResult<Goal>)
- cancelTapped
- delegate(Delegate)

**Dependencies**:
- @Dependency(\.goalRepository)
- @Dependency(\.areaRepository)
- @Dependency(\.dismiss)

**Validation Rules**:
- Title must not be empty
- Title must be 1-100 characters
- Area must be selected
- Points must be > 0

**Completion Criteria**:
- [ ] Full state implementation
- [ ] All actions implemented
- [ ] Dependencies wired
- [ ] Validation logic
- [ ] Save creates/updates goal
- [ ] Error handling
- [ ] Delegate notifications work
- [ ] UI implementation
- [ ] Can create goal successfully
- [ ] Can edit goal successfully

---

### 🔴 BUG-004: OccurrenceDetailFeature Placeholder

**File**: `HabitTracker/Sources/HabitTracker/Features/Today/TodayFeature.swift`
**Lines**: 322-342
**Severity**: 🔴 CRITICAL - BROKEN FEATURE
**Effort**: 2-3 hours
**Status**: 🔴 NOT STARTED

**Context**:
- OccurrenceDetailFeature is placeholder
- Users cannot view occurrence details
- Users cannot add notes
- Users cannot modify occurrence

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

**State Properties**:
- occurrence: GoalOccurrence
- goal: Goal?
- notes: String
- isEditingNotes: Bool
- isSaving: Bool
- errorMessage: String?

**Actions**:
- task
- goalLoaded(Goal)
- notesChanged(String)
- saveNotesTapped
- saveNotesResponse(TaskResult<Void>)
- completeAgainTapped
- undoCompletionTapped
- skipTapped
- actionResponse(TaskResult<Void>)
- dismiss

**Dependencies**:
- @Dependency(\.occurrenceRepository)
- @Dependency(\.goalRepository)
- @Dependency(\.dismiss)

**Completion Criteria**:
- [ ] Full state implementation
- [ ] All actions implemented
- [ ] Load goal details
- [ ] Display occurrence info
- [ ] Notes editing works
- [ ] Actions (complete, undo, skip) work
- [ ] Error handling
- [ ] UI implementation

---

### 🔴 BUG-005: Account Deletion Not Implemented

**File**: `HabitTracker/Sources/HabitTracker/Features/Settings/SettingsView.swift`
**Lines**: 265-275
**Severity**: 🔴 CRITICAL - LEGAL COMPLIANCE
**Effort**: 2-3 hours
**Status**: 🔴 NOT STARTED

**Context**:
- Delete Account button only signs out
- User data remains in database
- GDPR violation (right to erasure)
- App Store requirement not met

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

**Step 1: Create Supabase RPC Function**
```sql
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Delete in correct order (foreign key constraints)
    DELETE FROM measurements WHERE user_id = auth.uid();
    DELETE FROM goal_occurrences WHERE user_id = auth.uid();
    DELETE FROM goals WHERE user_id = auth.uid();
    DELETE FROM reflections WHERE user_id = auth.uid();
    DELETE FROM areas WHERE user_id = auth.uid();
    DELETE FROM profiles WHERE id = auth.uid();

    -- Note: Auth account deletion may require admin API
END;
$$;
```

**Step 2: Add AuthService Method**
```swift
public func deleteAccount() async throws {
    try await client.rpc("delete_user_account").execute()
    try await signOut()
}
```

**Step 3: Update SettingsFeature**
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

**Completion Criteria**:
- [ ] RPC function created in Supabase
- [ ] AuthService.deleteAccount() implemented
- [ ] SettingsFeature updated
- [ ] All user data deleted
- [ ] User signed out
- [ ] Verified data removed from database

---

### 🟠 BUG-006: Missing Error Alerts (5 instances)

**Files**: Multiple
**Severity**: 🟠 HIGH - POOR UX
**Effort**: 1-2 hours
**Status**: 🟠 NOT STARTED

**Locations**:
1. SettingsView.swift:267 - Export failure
2. SettingsView.swift:287 - Sync failure
3. SettingsView.swift:330 - Sign out failure
4. SettingsView.swift:350 - Delete account failure
5. ProgramsView.swift:542 - Adoption failure

**Pattern to Apply**:
```swift
// Add to State:
@Presents var errorAlert: AlertState<Action.ErrorAlert>?

// Add to Action:
case errorAlert(PresentationAction<ErrorAlert>)
enum ErrorAlert: Sendable { case dismiss }

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

**Completion Criteria**:
- [ ] All 5 locations updated
- [ ] Alert state added
- [ ] Error messages displayed
- [ ] Users informed of failures

---

### 🟠 BUG-007: Incomplete Data Export

**File**: `SettingsView.swift`
**Lines**: 241-260
**Severity**: 🟠 HIGH - GDPR COMPLIANCE
**Effort**: 2-3 hours
**Status**: 🟠 NOT STARTED

**Required**: Export all user data, not just metadata

**Completion Criteria**:
- [ ] Export profile
- [ ] Export all areas
- [ ] Export all goals
- [ ] Export occurrences (last 365 days)
- [ ] Export measurements (last 365 days)
- [ ] Export all reflections
- [ ] JSON format with proper structure

---

### 🟠 BUG-008: fatalError in Production (13 instances)

**Files**: Multiple
**Severity**: 🟠 HIGH - RELIABILITY
**Effort**: 3-4 hours
**Status**: 🟠 NOT STARTED

**Replace with proper error handling**

**Completion Criteria**:
- [ ] All 13 fatalError instances replaced
- [ ] Graceful error handling
- [ ] User-friendly error messages
- [ ] Fallback mechanisms

---

### 🟡 ISSUE-009: Missing Share Sheet

**File**: `SettingsView.swift`
**Lines**: 263-265
**Effort**: 30 minutes
**Status**: 🟡 NOT STARTED

---

### 🟡 ISSUE-010: Water Progress Not Implemented

**File**: `TodayFeature.swift`
**Lines**: 115-117
**Effort**: 2-3 hours
**Status**: 🟡 NOT STARTED

---

### 🟡 ISSUE-011: Recommendation Tapping No-op

**File**: `TodayFeature.swift`
**Lines**: 226-228
**Effort**: 1 hour
**Status**: 🟡 NOT STARTED

---

### 📝 ISSUE-012: External Links Placeholders

**File**: `SettingsView.swift`
**Lines**: 12-15
**Effort**: 5 minutes
**Status**: 📝 NOT STARTED

---

## 📊 Progress Tracking

### Overall Progress
```
P0 (Critical):  ░░░░░░░░░░░░░░░░░░░░  0/5  (0%)
P1 (High):      ░░░░░░░░░░░░░░░░░░░░  0/3  (0%)
P2 (Medium):    ░░░░░░░░░░░░░░░░░░░░  0/3  (0%)
P3 (Low):       ░░░░░░░░░░░░░░░░░░░░  0/1  (0%)
TOTAL:          ░░░░░░░░░░░░░░░░░░░░  0/12 (0%)
```

### Time Tracking
- **Estimated Total**: 20-30 hours
- **Time Spent**: 0 hours
- **Time Remaining**: 20-30 hours

---

## 🔄 Session Log

### Session 1: November 21, 2025 - Setup
- [x] Created BUG_FIX_TRACKER.md
- [x] Documented all 12 issues
- [x] Created implementation plan
- [ ] Ready to start fixes

**Next**: Start with BUG-001 (30 min)

---

## ✅ Completion Checklist

### Before Starting Each Fix
- [ ] Read issue details completely
- [ ] Understand the context
- [ ] Review current code
- [ ] Plan the implementation
- [ ] Identify verification steps

### After Completing Each Fix
- [ ] Code updated
- [ ] App builds successfully
- [ ] Functionality verified
- [ ] Tests pass (if applicable)
- [ ] Documentation updated
- [ ] Committed to git
- [ ] Status updated in tracker

### Final Verification
- [ ] All 12 issues resolved
- [ ] All tests passing
- [ ] No compilation errors
- [ ] No runtime crashes
- [ ] Enterprise quality maintained
- [ ] Ready for production

---

**Tracker Created**: November 21, 2025
**Last Updated**: November 21, 2025
**Status**: Ready to begin implementation
