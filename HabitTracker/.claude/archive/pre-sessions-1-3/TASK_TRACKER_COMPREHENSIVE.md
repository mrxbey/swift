# Comprehensive Task Tracker - HabitTracker Critical Fixes

**Start Date:** 2025-11-18
**Status:** 🟡 In Progress
**Total Tasks:** 37 tasks across 6 phases
**Completion:** 0/37 (0%)

---

## Phase 1: Critical Security Fixes (P0) 🔴

**Priority:** CRITICAL - Must complete before any other work
**Estimated Time:** 8-10 hours
**Status:** ⏳ Not Started

### Task 1.1: Remove Hardcoded Credentials ✅ / ❌

**Status:** ⏳ Not Started
**File:** `Sources/HabitTracker/Infrastructure/Config.swift`
**Lines:** 11-19
**Priority:** CRITICAL - Security Vulnerability
**Risk:** HIGH - Production credentials exposed

**Current State:**
```swift
public static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"]
    ?? "https://wiecalnwrmnnojkvnkym.supabase.co"  // ⚠️ HARDCODED

public static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
    ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."  // ⚠️ HARDCODED
```

**Target State:**
```swift
public static let supabaseURL: String = {
    guard let url = ProcessInfo.processInfo.environment["SUPABASE_URL"] else {
        fatalError("""
            SUPABASE_URL environment variable not set.

            Configure in Xcode:
            1. Edit Scheme > Run > Arguments > Environment Variables
            2. Add SUPABASE_URL with your Supabase project URL
            """)
    }
    return url
}()

public static let supabaseAnonKey: String = {
    guard let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] else {
        fatalError("""
            SUPABASE_ANON_KEY environment variable not set.

            Configure in Xcode:
            1. Edit Scheme > Run > Arguments > Environment Variables
            2. Add SUPABASE_ANON_KEY with your Supabase anon key
            """)
    }
    return key
}()
```

**Implementation Steps:**
1. Read current Config.swift
2. Replace hardcoded fallbacks with fatalError guards
3. Add helpful error messages for developers
4. Update .gitignore to ensure Config.swift never committed (already done)
5. Create Config.swift.example template

**Validation:**
- [ ] App fails to start without env vars
- [ ] Error message is clear and helpful
- [ ] No hardcoded credentials remain in code
- [ ] grep confirms no credentials in any file

**Dependencies:** None
**Blocks:** None (but critical for security)

---

### Task 1.2: Implement Keychain Storage for Auth Tokens ✅ / ❌

**Status:** ⏳ Not Started
**File:** NEW - `Sources/HabitTracker/Infrastructure/Auth/KeychainStorage.swift`
**Also:** `Sources/HabitTracker/Infrastructure/Network/SupabaseService.swift` line 46
**Priority:** CRITICAL - Security Vulnerability
**Risk:** HIGH - Session hijacking possible

**Current State:**
```swift
// SupabaseService.swift line 46
auth: .init(
    autoRefreshToken: true,
    persistSession: true,
    storage: UserDefaults.standard,  // ⚠️ INSECURE - unencrypted
    flowType: .pkce
)
```

**Target State:**
Create new KeychainStorage conforming to Supabase storage protocol, update SupabaseService to use it.

**Implementation Steps:**
1. Create KeychainStorage.swift implementing Supabase storage protocol
2. Implement store, retrieve, delete methods using Security framework
3. Add proper error handling
4. Update SupabaseService to use KeychainStorage
5. Add migration from UserDefaults to Keychain for existing users

**Validation:**
- [ ] Tokens not found in UserDefaults after auth
- [ ] Tokens persist across app restarts
- [ ] Tokens stored encrypted in Keychain
- [ ] Migration from UserDefaults works

**Dependencies:** None
**Blocks:** Task 1.3

---

### Task 1.3: Add Authentication Input Validation ✅ / ❌

**Status:** ⏳ Not Started
**File:** `Sources/HabitTracker/Infrastructure/Auth/AuthService.swift`
**Lines:** 54-71, 97-103, 109-115
**Priority:** CRITICAL - Security Vulnerability
**Risk:** MEDIUM - Weak credentials allowed

**Current State:**
No validation on email or password inputs. Comment says "minimum 6 characters" but not enforced.

**Target State:**
```swift
// Add validation methods
private func validateEmail(_ email: String) throws {
    let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,64}$"
    let predicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
    guard predicate.evaluate(with: email) else {
        throw AuthError.invalidEmail
    }
}

private func validatePassword(_ password: String) throws {
    guard password.count >= 8 else {
        throw AuthError.passwordTooShort
    }
    // Add complexity checks
}

// Call validation in all auth methods
```

**Implementation Steps:**
1. Add validateEmail method with regex
2. Add validatePassword method with complexity rules
3. Add new AuthError cases
4. Call validation in signUpWithEmail
5. Call validation in resetPassword
6. Call validation in updatePassword
7. Update AuthenticationFeature to show validation errors

**Validation:**
- [ ] Invalid emails rejected
- [ ] Weak passwords rejected
- [ ] Error messages clear to users
- [ ] AuthenticationFeature handles errors gracefully

**Dependencies:** Task 1.2 (Keychain)
**Blocks:** None

---

### Task 1.4: Replace print() with Proper Logging ✅ / ❌

**Status:** ⏳ Not Started
**Files:** Multiple files (8 print statements found)
**Priority:** HIGH - Information Disclosure
**Risk:** MEDIUM - Sensitive data in logs

**Current State:**
```swift
// RealtimeService.swift, SyncEngine.swift, SyncCoordinator.swift
print("Error decoding occurrence event: \(error)")
print("Failed to sync area \(cached.id): \(error)")
print("Sync error: \(error)")
```

**Target State:**
```swift
// Use OSLog for proper logging
import OSLog

private let logger = Logger(subsystem: "com.habittracker", category: "sync")

logger.error("Failed to sync area", error: error)
logger.info("Sync completed successfully")
```

**Implementation Steps:**
1. Create Logger+Extensions.swift with app loggers
2. Replace all print() with logger calls
3. Sanitize error messages (no sensitive data)
4. Add logging levels (error, warning, info, debug)
5. Remove print() statements from production builds

**Validation:**
- [ ] No print() statements remain
- [ ] Logs use proper Logger framework
- [ ] No sensitive data in logs
- [ ] Log levels appropriate

**Dependencies:** None
**Blocks:** None

---

### Task 1.5: Fix fatalError on Configuration Failure ✅ / ❌

**Status:** ⏳ Not Started
**File:** `Sources/HabitTracker/Infrastructure/Network/SupabaseService.swift`
**Lines:** 24-33
**Priority:** MEDIUM-HIGH - Crash Risk
**Risk:** MEDIUM - App becomes unusable

**Current State:**
```swift
private init() {
    do {
        try Config.validate()
    } catch {
        fatalError("Supabase configuration error: \(error.localizedDescription)")
    }

    guard let url = URL(string: Config.supabaseURL) else {
        fatalError("Invalid Supabase URL: \(Config.supabaseURL)")
    }
}
```

**Target State:**
Make init throwing, handle errors at app level with user-friendly messages.

**Implementation Steps:**
1. Change init() to init() throws
2. Remove fatalError calls
3. Throw ConfigError instead
4. Update SupabaseService.shared to handle errors
5. Add retry mechanism or settings screen

**Validation:**
- [ ] No fatalError in SupabaseService
- [ ] Errors handled gracefully
- [ ] User sees helpful error message
- [ ] App doesn't crash on config error

**Dependencies:** Task 1.1
**Blocks:** None

---

## Phase 2: Critical Data Integrity Fixes (P0) 🔴

**Priority:** CRITICAL - Data corruption prevention
**Estimated Time:** 12-15 hours
**Status:** ⏳ Not Started

### Task 2.1: Fix Force Unwrap Crash in Measurement ✅ / ❌

**Status:** ⏳ Not Started
**File:** `Sources/HabitTracker/Domain/Models/Measurement.swift`
**Line:** 144
**Priority:** CRITICAL - Crash Risk
**Risk:** HIGH - App crashes when effectiveTo is nil

**Current State:**
```swift
public var isActive: Bool {
    let now = Date()
    return effectiveFrom <= now && effectiveTo! > now  // ⚠️ CRASH!
}
```

**Target State:**
```swift
public var isActive: Bool {
    let now = Date()
    return effectiveFrom <= now && (effectiveTo.map { $0 > now } ?? true)
}
```

**Implementation Steps:**
1. Read Measurement.swift
2. Locate line 144
3. Replace force unwrap with safe optional handling
4. Test with nil effectiveTo
5. Verify logic: nil effectiveTo means "active forever"

**Validation:**
- [ ] No force unwrap on line 144
- [ ] isActive returns true when effectiveTo is nil
- [ ] isActive returns correct value when effectiveTo is set
- [ ] No crashes with nil effectiveTo

**Dependencies:** None
**Blocks:** None

---

### Task 2.2: Fix Critical Bug in Measurement fetch() ✅ / ❌

**Status:** ⏳ Not Started
**File:** `Sources/HabitTracker/Data/Repositories/Supabase/SupabaseMeasurementRepository.swift`
**Lines:** 133-135
**Priority:** CRITICAL - Logic Bug
**Risk:** HIGH - Method completely broken

**Current State:**
```swift
public func fetch(_ id: UUID) async throws -> Measurement {
    let cached = try await MainActor.run {
        try cacheService.fetchMeasurements(goalId: id)  // ⚠️ WRONG PARAMETER!
    }
}
```

**Target State:**
Fix to query by measurement ID, not goalId. Implement proper fetch logic.

**Implementation Steps:**
1. Read current implementation
2. Add fetchMeasurement(id:) method to CacheService if missing
3. Fix fetch() to use correct parameter
4. Implement full fetch logic (cache-first, then network)
5. Update cache after network fetch

**Validation:**
- [ ] fetch(id) returns correct measurement
- [ ] Uses measurement ID not goalId
- [ ] Cache-first pattern implemented
- [ ] Network fallback works

**Dependencies:** None
**Blocks:** None

---

### Task 2.3: Fix GoalScheduleDTO Field Mismatch ✅ / ❌

**Status:** ⏳ Not Started
**File:** `Sources/HabitTracker/Data/DTOs/GoalScheduleDTO.swift`
**Priority:** CRITICAL - Data Loss
**Risk:** HIGH - timezone and rrule data lost

**Current State:**
- DTO missing `timezone` field (domain has it)
- DTO missing `rrule` field (domain has it)
- DTO has `userId` field (domain doesn't have it)
- Wrong enum type used

**Target State:**
DTO matches domain model exactly. All fields mapped correctly.

**Implementation Steps:**
1. Read current GoalScheduleDTO.swift
2. Read domain GoalSchedule.swift
3. Add missing fields: timezone, rrule
4. Remove extra field: userId
5. Fix enum type (PeriodFrequency not RecurrenceFrequency)
6. Update CodingKeys
7. Fix init(from:) and toDomain
8. Test round-trip conversion

**Validation:**
- [ ] All domain fields in DTO
- [ ] No extra fields in DTO
- [ ] Correct enum types
- [ ] Round-trip preserves all data
- [ ] timezone not lost
- [ ] rrule not lost

**Dependencies:** None
**Blocks:** None

---

### Task 2.4: Fix Race Conditions in Repository Fetch Methods ✅ / ❌

**Status:** ⏳ Not Started
**Files:** All repositories (Area, Goal, Occurrence, Measurement)
**Priority:** CRITICAL - Data Corruption
**Risk:** HIGH - Stale data, cache corruption

**Current Pattern (WRONG):**
```swift
public func fetchAll() async throws -> [Area] {
    let cached = try await MainActor.run {
        try cacheService.fetchAreas(userId: userId)
    }

    if !cached.isEmpty {
        Task {  // ⚠️ RACE CONDITION
            if await networkMonitor.isConnected() {
                try? await syncEngine.performFullSync(userId: userId)
            }
        }
        return cached  // ⚠️ Returns potentially stale data
    }
}
```

**Target Pattern (RIGHT):**
Option A: Synchronous (slower but consistent)
```swift
public func fetchAll() async throws -> [Area] {
    let cached = try await MainActor.run {
        try cacheService.fetchAreas(userId: userId)
    }

    if await networkMonitor.isConnected() {
        try? await syncEngine.performFullSync(userId: userId)
        return try await MainActor.run {
            try cacheService.fetchAreas(userId: userId)
        }
    }

    return cached
}
```

Option B: Async notification (faster, more complex)
Requires implementing cache update observer pattern.

**Implementation Steps:**
1. Explore all fetch methods in all repositories
2. Identify all race condition patterns
3. Choose approach (Option A for now - simpler and safer)
4. Fix SupabaseAreaRepository.fetchAll()
5. Fix SupabaseGoalRepository.fetchAll() and fetchGoals(areaId:)
6. Fix SupabaseOccurrenceRepository.fetchOccurrences()
7. Fix SupabaseMeasurementRepository.fetchAll()
8. Test concurrent fetches

**Validation:**
- [ ] No background Task {} for sync in fetch methods
- [ ] Sync completes before returning if online
- [ ] Cached data returned if offline
- [ ] No race conditions possible
- [ ] Data always consistent

**Dependencies:** Task 2.8 (Sync protection)
**Blocks:** None

---

### Task 2.5: Add Cache Updates After RPC Operations ✅ / ❌

**Status:** ⏳ Not Started
**Files:** All repositories with RPC methods
**Priority:** CRITICAL - Cache Staleness
**Risk:** HIGH - Cache out of sync with database

**Locations to Fix:**
- SupabaseOccurrenceRepository.completeTick() line 287
- SupabaseOccurrenceRepository.skip() line 307
- SupabaseOccurrenceRepository.rename() line 333
- SupabaseOccurrenceRepository.ensureOccurrence() line 354
- SupabaseMeasurementRepository.addMeasurement() line 289
- SupabaseMeasurementRepository.setMeasureTarget() line 369
- SupabaseGoalRepository.searchByHashtag() line 316
- SupabaseGoalRepository.fetchMostCompleted() line 348
- SupabaseAreaRepository.fetchStatistics() line 334

**Current Pattern (WRONG):**
```swift
public func completeTick(_ id: UUID) async throws {
    try await client.rpc("complete_tick", params: [...]).execute()
    // ⚠️ Cache not updated!
}
```

**Target Pattern (RIGHT):**
```swift
public func completeTick(_ id: UUID) async throws {
    // Execute RPC
    try await client.rpc("complete_tick", params: [...]).execute()

    // Update cache - fetch latest from database
    let updated: GoalOccurrenceDTO = try await client
        .from("goal_occurrences")
        .select()
        .eq("id", value: id)
        .single()
        .execute()
        .value

    let occurrence = updated.toDomain

    try await MainActor.run {
        try cacheService.saveOccurrence(occurrence, syncState: .synced)
    }
}
```

**Implementation Steps:**
1. Fix completeTick() - fetch and cache updated occurrence
2. Fix skip() - fetch and cache updated occurrence
3. Fix rename() - fetch and cache updated occurrence
4. Fix ensureOccurrence() - cache created occurrence
5. Fix addMeasurement() - cache created measurement
6. Fix setMeasureTarget() - cache created target
7. Fix searchByHashtag() - optionally cache results
8. Fix fetchMostCompleted() - read-only, no cache update needed
9. Fix fetchStatistics() - read-only, no cache update needed

**Validation:**
- [ ] All RPC methods update cache
- [ ] Cache reflects database state after RPC
- [ ] Subsequent fetches return correct data
- [ ] No stale data in cache

**Dependencies:** None
**Blocks:** None

---

### Task 2.6: Add Concurrent Sync Protection ✅ / ❌

**Status:** ⏳ Not Started
**File:** `Sources/HabitTracker/Data/Sync/SyncEngine.swift`
**Lines:** 42-50
**Priority:** CRITICAL - Race Condition
**Risk:** HIGH - Data corruption from concurrent syncs

**Current State:**
```swift
public func performFullSync(userId: UUID) async throws {
    // ⚠️ No protection against concurrent calls
    try await uploadPendingChanges(userId: userId)
    try await downloadUpdates(userId: userId)
    saveLastSyncTimestamps()
}
```

**Target State:**
```swift
private var isSyncing = false
private var syncTask: Task<Void, Error>?

public func performFullSync(userId: UUID) async throws {
    // If already syncing, await existing task
    if let existing = syncTask {
        return try await existing.value
    }

    guard !isSyncing else {
        throw SyncError.alreadySyncing
    }

    isSyncing = true
    defer { isSyncing = false }

    let task = Task {
        defer { syncTask = nil }
        try await uploadPendingChanges(userId: userId)
        try await downloadUpdates(userId: userId)
        saveLastSyncTimestamps()
    }

    syncTask = task
    try await task.value
}
```

**Implementation Steps:**
1. Add isSyncing property
2. Add syncTask property
3. Add check for existing sync
4. Add defer cleanup
5. Wrap sync in Task
6. Test concurrent calls

**Validation:**
- [ ] Concurrent calls don't start multiple syncs
- [ ] Second call awaits first to complete
- [ ] No data corruption
- [ ] Clean error handling

**Dependencies:** None
**Blocks:** Task 2.4

---

### Task 2.7: Implement Proper Conflict Resolution ✅ / ❌

**Status:** ⏳ Not Started
**File:** `Sources/HabitTracker/Data/Sync/SyncEngine.swift`
**Lines:** 183-264 (download methods)
**Priority:** CRITICAL - Data Loss
**Risk:** HIGH - User's offline changes lost

**Current State:**
```swift
private func downloadAreas(userId: UUID) async throws {
    // ...
    for dto in dtos {
        let area = dto.toDomain
        try cacheService.saveArea(area, syncState: .synced)  // ⚠️ Overwrites pending!
    }
}
```

**Target State:**
```swift
private func downloadAreas(userId: UUID) async throws {
    let lastSync = lastSyncTimestamps["areas"] ?? Date.distantPast
    let dtos: [AreaDTO] = try await supabaseClient...

    for dto in dtos {
        // Check for pending local changes
        if let cached = try? cacheService.fetchArea(id: dto.id),
           cached.syncState == .pending {
            // Resolve conflict using timestamps (last-write-wins)
            let shouldKeepLocal = cached.updatedAt > dto.updatedAt
            if shouldKeepLocal {
                continue  // Skip this download, will be uploaded later
            }
        }

        let area = dto.toDomain
        try cacheService.saveArea(area, syncState: .synced)
    }

    lastSyncTimestamps["areas"] = Date()
}
```

**Implementation Steps:**
1. Implement timestamp-based conflict resolution in downloadAreas()
2. Implement same logic in downloadGoals()
3. Implement same logic in downloadOccurrences()
4. Implement same logic in downloadMeasurements()
5. Test offline changes preserved during sync
6. Add logging for resolved conflicts

**Validation:**
- [ ] Offline changes not lost
- [ ] Last-write-wins strategy implemented
- [ ] Timestamps compared correctly
- [ ] Local pending changes preserved

**Dependencies:** Task 2.6
**Blocks:** None

---

### Task 2.8: Implement Transaction Boundaries for Deletes ✅ / ❌

**Status:** ⏳ Not Started
**Files:** All repositories (delete methods)
**Priority:** HIGH - Data Consistency
**Risk:** MEDIUM - Inconsistent state between cache and server

**Current Pattern (WRONG):**
```swift
public func delete(id: UUID) async throws {
    // Delete from cache first
    try await MainActor.run {
        try cacheService.deleteArea(id: id)  // ⚠️ Cache deleted
    }

    // Try to sync deletion to Supabase if online
    if await networkMonitor.isConnected() {
        do {
            try await client.from("areas").delete().execute()  // ⚠️ May fail!
        } catch {
            // ⚠️ Cache deleted but server still has it!
            throw SupabaseError.from(error)
        }
    }
}
```

**Target Pattern (RIGHT):**
```swift
public func delete(id: UUID) async throws {
    // Mark as deleted in cache (soft delete)
    try await MainActor.run {
        try cacheService.markAreaAsDeleted(id: id)  // Soft delete
    }

    // Try to sync deletion to Supabase if online
    if await networkMonitor.isConnected() {
        do {
            try await client.from("areas").delete().execute()

            // Only hard delete from cache after server confirms
            try await MainActor.run {
                try cacheService.deleteArea(id: id)  // Hard delete
            }
        } catch {
            // Cache marked as deleted, will retry on next sync
            throw SupabaseError.from(error)
        }
    }
}
```

**Implementation Steps:**
1. Add soft delete support to CacheService (deleted flag)
2. Update delete methods in all repositories
3. Mark as deleted instead of hard delete
4. Hard delete only after server confirms
5. Add sync support for deleted items
6. Test offline delete and sync

**Validation:**
- [ ] Soft delete implemented
- [ ] Hard delete only after server confirms
- [ ] Offline deletes synced later
- [ ] No inconsistent state

**Dependencies:** Task 2.6, Task 2.7
**Blocks:** None

---

## Phase 3: Performance & Concurrency Fixes (P1) 🟡

**Priority:** HIGH - Performance and UX
**Estimated Time:** 10-12 hours
**Status:** ⏳ Not Started

### Task 3.1: Remove @MainActor from CacheService ✅ / ❌

**Status:** ⏳ Not Started
**File:** `Sources/HabitTracker/Data/Cache/CacheService.swift`
**Line:** 8
**Priority:** HIGH - Performance
**Risk:** HIGH - UI freezes, ANR errors

**Current State:**
```swift
@MainActor  // ⚠️ ALL operations block main thread!
public final class CacheService {
```

**Target State:**
Remove @MainActor, use background ModelContext.

**Implementation Steps:**
1. Remove @MainActor annotation
2. Ensure ModelContext is background context
3. Update all call sites to remove MainActor.run {}
4. Test cache operations don't block UI
5. Verify SwiftData thread safety

**Validation:**
- [ ] No @MainActor on CacheService
- [ ] Operations run on background thread
- [ ] UI remains responsive during cache ops
- [ ] No threading errors

**Dependencies:** None (can be done independently)
**Blocks:** Task 3.2

---

### Task 3.2: Implement Cascade Deletes in SwiftData Models ✅ / ❌

**Status:** ⏳ Not Started
**Files:** All cache models (CachedArea, CachedGoal, CachedOccurrence, CachedMeasurement)
**Priority:** HIGH - Data Integrity
**Risk:** MEDIUM - Orphaned records, memory bloat

**Current State:**
```swift
@Model
public final class CachedGoal {
    public var areaId: UUID  // ⚠️ Just UUID, no relationship
}
```

**Target State:**
```swift
@Model
public final class CachedArea {
    @Relationship(deleteRule: .cascade, inverse: \CachedGoal.area)
    public var goals: [CachedGoal] = []
}

@Model
public final class CachedGoal {
    public var area: CachedArea?  // ✅ Proper relationship
}
```

**Implementation Steps:**
1. Update CachedArea with goals relationship
2. Update CachedGoal with area relationship
3. Update CachedGoal with occurrences relationship
4. Update CachedGoal with measurements relationship
5. Update CachedOccurrence with goal relationship
6. Update CachedMeasurement with goal relationship
7. Test cascade deletes work
8. Migrate existing data if needed

**Validation:**
- [ ] Deleting area deletes goals
- [ ] Deleting goal deletes occurrences
- [ ] Deleting goal deletes measurements
- [ ] No orphaned records
- [ ] Migration works

**Dependencies:** Task 3.1
**Blocks:** None

---

### Task 3.3: Fix Expensive DateFormatter in Computed Properties ✅ / ❌

**Status:** ⏳ Not Started
**Files:**
- `Sources/HabitTracker/Domain/Models/Profile.swift` line 67
- `Sources/HabitTracker/Domain/Models/Reflection.swift` line 62
**Priority:** HIGH - Performance
**Risk:** MEDIUM - Severe performance degradation

**Current State:**
```swift
public var formattedReminderTime: String {
    guard let time = dailyReminderTime else { return "None" }
    let formatter = ISO8601DateFormatter()  // ⚠️ Created every call!
    return formatter.string(from: time)
}
```

**Target State:**
```swift
// In new ProfileFormatter.swift
public struct ProfileFormatter {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    public static func formatReminderTime(_ date: Date?) -> String {
        guard let date = date else { return "None" }
        return timeFormatter.string(from: date)
    }
}

// In Profile.swift - remove computed property, use formatter
```

**Implementation Steps:**
1. Create Infrastructure/Formatters/ProfileFormatter.swift
2. Create Infrastructure/Formatters/ReflectionFormatter.swift
3. Move formatting logic to formatters
4. Use static cached formatters
5. Update Profile model
6. Update Reflection model
7. Update views to use formatters
8. Test performance improvement

**Validation:**
- [ ] Formatters use static cached instances
- [ ] No DateFormatter created in loops
- [ ] Performance improved
- [ ] Views work correctly

**Dependencies:** None
**Blocks:** None

---

### Task 3.4: Add Retry Logic with Exponential Backoff ✅ / ❌

**Status:** ⏳ Not Started
**File:** `Sources/HabitTracker/Data/Sync/SyncEngine.swift`
**Lines:** 70-162 (upload methods)
**Priority:** HIGH - Data Integrity
**Risk:** MEDIUM - Failed syncs stuck forever

**Current State:**
```swift
catch {
    try? cacheService.saveArea(area, syncState: .failed)
    print("Failed to sync area \(cached.id): \(error)")
    // ⚠️ No retry, stuck forever
}
```

**Target State:**
Add retry count and backoff logic.

**Implementation Steps:**
1. Add retryCount to cache models
2. Add lastRetryAt to cache models
3. Implement shouldRetry() logic
4. Implement exponential backoff calculation
5. Update upload methods to use retry logic
6. Track retry count
7. Max retries: 5
8. Backoff: 5s, 10s, 20s, 40s, 80s

**Validation:**
- [ ] Failed items retry with backoff
- [ ] Max retries enforced
- [ ] Backoff times correct
- [ ] Eventually succeeds or gives up

**Dependencies:** Task 3.2 (model updates)
**Blocks:** None

---

### Task 3.5: Fix SyncCoordinator Race Condition ✅ / ❌

**Status:** ⏳ Not Started
**File:** `Sources/HabitTracker/Data/Sync/SyncCoordinator.swift`
**Lines:** 72-93
**Priority:** HIGH - Data Integrity
**Risk:** MEDIUM - Multiple syncs running

**Current State:**
```swift
public func sync(userId: UUID) async {
    guard !isSyncing else { return }  // ⚠️ Not atomic!
    guard networkStatus.isConnected else { return }

    isSyncing = true  // ⚠️ Race window here
}
```

**Target State:**
Use Task tracking to prevent races.

**Implementation Steps:**
1. Add activeSyncTask property
2. Check for existing task
3. Await existing task if present
4. Create new task if not
5. Clean up on completion
6. Test concurrent calls

**Validation:**
- [ ] No race condition
- [ ] Only one sync at a time
- [ ] Concurrent calls handled
- [ ] Clean completion

**Dependencies:** Task 2.6
**Blocks:** None

---

### Task 3.6: Add Offline Queueing for RPC Operations ✅ / ❌

**Status:** ⏳ Not Started
**Files:** All repositories with RPC methods
**Priority:** HIGH - Offline Support
**Risk:** MEDIUM - Features broken offline

**Current State:**
```swift
public func completeTick(_ id: UUID) async throws {
    // ⚠️ Fails immediately if offline
    try await client.rpc("complete_tick", params: [...]).execute()
}
```

**Target State:**
Queue RPC operations offline, execute when online.

**Implementation Steps:**
1. Create PendingRPCOperation model
2. Add RPCQueue to CacheService
3. Queue operations when offline
4. Execute queue in SyncEngine
5. Update all RPC methods
6. Test offline→online flow

**Validation:**
- [ ] RPC operations queued offline
- [ ] Operations execute when online
- [ ] User sees immediate feedback
- [ ] No data loss

**Dependencies:** Task 2.8
**Blocks:** None

---

## Phase 4: Code Quality Fixes (P2) 🟠

**Priority:** MEDIUM - Code maintainability
**Estimated Time:** 8-10 hours
**Status:** ⏳ Not Started

### Task 4.1-4.8: Fix MARK Comments Across All Files ✅ / ❌

**Status:** ⏳ Not Started
**Files:** All domain models (8 files)
**Priority:** MEDIUM - Code Quality
**Risk:** LOW - IDE navigation broken

**Pattern:** Replace `/// MARK:` with `// MARK:`

**Implementation:**
1. Global find/replace in domain models
2. Verify Xcode navigation works

**Validation:**
- [ ] All MARK comments use //
- [ ] Xcode jump bar works

---

### Task 4.9: Add Domain Model Validation Methods ✅ / ❌

**Status:** ⏳ Not Started
**Files:** Area, Goal, GoalOccurrence, Profile, Program, Reflection
**Priority:** MEDIUM - Data Quality
**Risk:** LOW - Invalid data accepted

**Target:** Add validate() throws methods to all models

---

### Task 4.10: Extract Presentation Logic to Formatters ✅ / ❌

**Status:** ⏳ Not Started
**Files:** GoalSchedule, Profile, Reflection, Program
**Priority:** MEDIUM - Architecture
**Risk:** LOW - Code organization

**Target:** Move all display strings to formatter classes

---

### Task 4.11: Move Business Logic from GoalOccurrence ✅ / ❌

**Status:** ⏳ Not Started
**File:** GoalOccurrence.swift
**Priority:** MEDIUM - Architecture
**Risk:** LOW - Testability

**Target:** Move mutation methods to OccurrenceService

---

### Task 4.12: Fix MeasurementDTO Silent Fallback ✅ / ❌

**Status:** ⏳ Not Started
**File:** MeasurementDTO.swift
**Priority:** MEDIUM - Data Quality
**Risk:** MEDIUM - Data corruption

**Target:** Throw error instead of falling back to .count

---

## Phase 5: Validation & Testing 🧪

**Priority:** CRITICAL - Ensure nothing broken
**Estimated Time:** 4-6 hours
**Status:** ⏳ Not Started

### Task 5.1: Validate Security Fixes ✅ / ❌

**Status:** ⏳ Not Started
**Validation:**
- [ ] No hardcoded credentials in code
- [ ] Tokens in Keychain not UserDefaults
- [ ] Weak passwords rejected
- [ ] No sensitive data in logs

---

### Task 5.2: Validate Data Integrity Fixes ✅ / ❌

**Status:** ⏳ Not Started
**Validation:**
- [ ] No force unwrap crashes
- [ ] Cache consistent with server
- [ ] Conflict resolution works
- [ ] No data loss offline→online

---

### Task 5.3: Validate Performance Fixes ✅ / ❌

**Status:** ⏳ Not Started
**Validation:**
- [ ] UI responsive during cache ops
- [ ] No DateFormatter creation in loops
- [ ] Sync doesn't block UI

---

### Task 5.4: Manual Testing Checklist ✅ / ❌

**Status:** ⏳ Not Started
**Tests:**
- [ ] Sign up with weak password (should fail)
- [ ] Sign in and verify token in Keychain
- [ ] Create area, verify cascade delete
- [ ] Complete task offline, sync online
- [ ] Multiple concurrent operations

---

## Phase 6: Automated Testing 🤖

**Priority:** CRITICAL - Regression prevention
**Estimated Time:** 2-3 hours
**Status:** ⏳ Not Started

### Task 6.1: Run Full Test Suite ✅ / ❌

**Status:** ⏳ Not Started
**Command:** `swift test --parallel`
**Expected:** 294 tests pass, 0 failures

**Validation:**
- [ ] All 294 tests pass
- [ ] No new test failures
- [ ] No crashes during tests
- [ ] Test execution time reasonable

---

### Task 6.2: Add New Tests for Fixes ✅ / ❌

**Status:** ⏳ Not Started
**New Tests:**
- [ ] Test Keychain storage
- [ ] Test conflict resolution
- [ ] Test concurrent sync protection
- [ ] Test cascade deletes
- [ ] Test offline RPC queueing

---

## Progress Tracking

**Overall Progress:** 0/37 tasks (0%)

**Phase 1 (Security):** 0/5 (0%)
**Phase 2 (Data):** 0/8 (0%)
**Phase 3 (Performance):** 0/6 (0%)
**Phase 4 (Quality):** 0/12 (0%)
**Phase 5 (Validation):** 0/4 (0%)
**Phase 6 (Testing):** 0/2 (0%)

---

## Risk Assessment

**Current Risk Level:** 🔴 CRITICAL
- Security vulnerabilities present
- Data corruption possible
- Performance issues exist

**After Phase 1:** 🟡 HIGH
- Security fixed
- Data issues remain

**After Phase 2:** 🟢 MEDIUM
- Security fixed
- Data integrity improved
- Performance issues remain

**After Phase 3:** 🟢 LOW
- All critical issues fixed
- Code quality issues remain

**After Phase 4:** 🟢 MINIMAL
- Production ready
- Enterprise quality achieved

---

## Rollback Plan

**If Issues Found:**
1. Each task committed separately
2. Can revert individual commits
3. Feature flags for new behavior
4. Database migration reversible

**Critical Rollback Points:**
- After Phase 1: Security fixes
- After Phase 2: Data integrity
- After Phase 3: Performance

---

## Success Criteria

**Phase 1 Complete:**
- [ ] No hardcoded credentials
- [ ] Tokens encrypted in Keychain
- [ ] Auth validation works
- [ ] Proper logging implemented

**Phase 2 Complete:**
- [ ] No force unwrap crashes
- [ ] Cache always consistent
- [ ] Conflict resolution working
- [ ] Transaction boundaries enforced

**Phase 3 Complete:**
- [ ] UI responsive
- [ ] Cascade deletes working
- [ ] Retry logic functional
- [ ] Offline mode robust

**Phase 4 Complete:**
- [ ] Clean code organization
- [ ] Proper validation
- [ ] Good architecture

**All Phases Complete:**
- [ ] All 294 tests passing
- [ ] Manual testing passed
- [ ] No regressions
- [ ] Production ready

---

**Last Updated:** 2025-11-18
**Next Update:** After each phase completion
