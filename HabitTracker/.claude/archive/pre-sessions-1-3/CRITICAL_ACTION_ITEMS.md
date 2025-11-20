# CRITICAL ACTION ITEMS - Immediate Attention Required

**Status:** 🔴 PRODUCTION BLOCKERS
**Timeline:** Must fix before any production deployment
**Priority:** P0 - Critical

---

## 🔴 Security Vulnerabilities (Fix Today)

### 1. Remove Hardcoded Credentials
**File:** `Infrastructure/Config.swift` lines 11-19
**Risk:** Anyone can extract production credentials from compiled app

**Current Code:**
```swift
public static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"]
    ?? "https://wiecalnwrmnnojkvnkym.supabase.co"  // ⚠️ REMOVE

public static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
    ?? "eyJhbGciOiJIUzI1NiIsInR..."  // ⚠️ REMOVE
```

**Fix:**
```swift
public static let supabaseURL: String = {
    guard let url = ProcessInfo.processInfo.environment["SUPABASE_URL"] else {
        fatalError("SUPABASE_URL environment variable not set. Configure in Xcode scheme.")
    }
    return url
}()

public static let supabaseAnonKey: String = {
    guard let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] else {
        fatalError("SUPABASE_ANON_KEY environment variable not set. Configure in Xcode scheme.")
    }
    return key
}()
```

**Testing:** Verify app fails gracefully when env vars missing

---

### 2. Implement Keychain Storage for Tokens
**File:** `Infrastructure/Network/SupabaseService.swift` line 46
**Risk:** Session tokens accessible via backup, jailbreak

**Current Code:**
```swift
storage: UserDefaults.standard,  // ⚠️ INSECURE!
```

**Fix:** Create KeychainStorage conforming to SupabaseClientDependencies.storage protocol
```swift
// New file: Infrastructure/Auth/KeychainStorage.swift
import Security

final class KeychainStorage: @unchecked Sendable {
    func store(key: String, value: Data) throws { /* Keychain implementation */ }
    func retrieve(key: String) throws -> Data? { /* Keychain implementation */ }
    func delete(key: String) throws { /* Keychain implementation */ }
}

// In SupabaseService.swift:
storage: KeychainStorage(),
```

**Testing:** Verify tokens not in UserDefaults, survive app restart

---

### 3. Add Authentication Input Validation
**File:** `Infrastructure/Auth/AuthService.swift`
**Risk:** Weak passwords, invalid emails, credential stuffing

**Add validation methods:**
```swift
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
    guard password.rangeOfCharacter(from: .uppercaseLetters) != nil else {
        throw AuthError.passwordNeedsUppercase
    }
    guard password.rangeOfCharacter(from: .lowercaseLetters) != nil else {
        throw AuthError.passwordNeedsLowercase
    }
    guard password.rangeOfCharacter(from: .decimalDigits) != nil else {
        throw AuthError.passwordNeedsNumber
    }
}
```

**Testing:** Verify weak passwords rejected

---

## 🔴 Data Corruption Risks (Fix This Week)

### 4. Fix Force Unwrap Crash
**File:** `Domain/Models/Measurement.swift` line 144
**Risk:** App crashes when effectiveTo is nil

**Current Code:**
```swift
public var isActive: Bool {
    let now = Date()
    return effectiveFrom <= now && effectiveTo! > now  // ⚠️ CRASH!
}
```

**Fix:**
```swift
public var isActive: Bool {
    let now = Date()
    return effectiveFrom <= now && (effectiveTo.map { $0 > now } ?? true)
}
```

**Testing:** Create measurement with nil effectiveTo, verify isActive works

---

### 5. Fix Race Conditions in Repositories
**Files:** All repositories (Area, Goal, Occurrence, Measurement)
**Risk:** Stale data, cache corruption, duplicates

**Pattern to Fix:**
```swift
// Current - WRONG
public func fetchAll() async throws -> [Area] {
    let cached = try await MainActor.run {
        try cacheService.fetchAreas(userId: userId)
    }

    if !cached.isEmpty {
        Task {  // ⚠️ Race condition
            if await networkMonitor.isConnected() {
                try? await syncEngine.performFullSync(userId: userId)
            }
        }
        return cached  // ⚠️ May be stale
    }
    // ...
}

// Fixed - RIGHT
public func fetchAll() async throws -> [Area] {
    // Return cached data immediately
    let cached = try await MainActor.run {
        try cacheService.fetchAreas(userId: userId)
    }

    // Sync in background WITHOUT returning before completion
    // OR implement proper cache invalidation observer pattern
    if await networkMonitor.isConnected() {
        // Option 1: Await sync (slower but consistent)
        try? await syncEngine.performFullSync(userId: userId)
        return try await MainActor.run {
            try cacheService.fetchAreas(userId: userId)
        }

        // Option 2: Return cached but notify observer of updates
        // (Requires implementing cache update notifications)
    }

    return cached
}
```

**Testing:** Verify concurrent fetches don't cause issues

---

### 6. Fix RPC Cache Bypass
**Files:** All repositories
**Risk:** Cache becomes stale after RPC operations

**Locations to Fix:**
- SupabaseOccurrenceRepository: completeTick (287), skip (307), rename (333), ensureOccurrence (354)
- SupabaseMeasurementRepository: addMeasurement (289), setMeasureTarget (369)

**Pattern:**
```swift
// Current - WRONG
public func completeTick(_ id: UUID) async throws {
    try await client.rpc("complete_tick", params: [...]).execute()
    // ⚠️ Cache not updated
}

// Fixed - RIGHT
public func completeTick(_ id: UUID) async throws {
    // Execute RPC
    try await client.rpc("complete_tick", params: [...]).execute()

    // Update cache
    if let occurrence = try? await fetchFromSupabase(id) {
        try await MainActor.run {
            try cacheService.saveOccurrence(occurrence, syncState: .synced)
        }
    }
}
```

**Testing:** Verify cache reflects changes after RPC calls

---

### 7. Fix Measurement fetch() Bug
**File:** `Data/Repositories/Supabase/SupabaseMeasurementRepository.swift` line 133-135
**Risk:** Method completely broken

**Current Code:**
```swift
public func fetch(_ id: UUID) async throws -> Measurement {
    let cached = try await MainActor.run {
        try cacheService.fetchMeasurements(goalId: id)  // ⚠️ WRONG!
    }
}
```

**Fix:**
```swift
public func fetch(_ id: UUID) async throws -> Measurement {
    // Try cache first
    if let cached = try? await MainActor.run {
        try cacheService.fetchMeasurement(id: id)  // ✅ Correct parameter
    } {
        return cached
    }

    // Fetch from Supabase
    let dto: MeasurementDTO = try await client
        .from("measurements")
        .select()
        .eq("id", value: id)
        .single()
        .execute()
        .value

    let measurement = dto.toDomain

    // Update cache
    try await MainActor.run {
        try cacheService.saveMeasurement(measurement, syncState: .synced)
    }

    return measurement
}
```

**Testing:** Verify can fetch individual measurements by ID

---

### 8. Fix GoalScheduleDTO Field Mismatch
**File:** `Data/DTOs/GoalScheduleDTO.swift`
**Risk:** timezone and rrule data lost

**Issues:**
- DTO missing `timezone` field
- DTO missing `rrule` field
- DTO has extra `userId` field
- Wrong enum type

**Fix:** Rewrite DTO to match domain model:
```swift
public struct GoalScheduleDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let goalId: UUID  // Not userId!
    public let freq: String
    public let interval: Int
    public let byWeekday: [Int]?
    public let byMonthday: [Int]?
    public let startDate: Date
    public let endDate: Date?
    public let timezone: String  // ✅ ADD
    public let rrule: String?    // ✅ ADD
    public let createdAt: Date
    public let updatedAt: Date

    // Update CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, freq, interval, timezone, rrule
        case goalId = "goal_id"
        case byWeekday = "by_weekday"
        case byMonthday = "by_monthday"
        case startDate = "start_date"
        case endDate = "end_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

**Testing:** Verify round-trip conversion preserves all fields

---

### 9. Add Concurrent Sync Protection
**File:** `Data/Sync/SyncEngine.swift`
**Risk:** Duplicate syncs, data corruption

**Current Code:**
```swift
public func performFullSync(userId: UUID) async throws {
    // ⚠️ No protection against concurrent calls
    try await uploadPendingChanges(userId: userId)
    try await downloadUpdates(userId: userId)
}
```

**Fix:**
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

**Testing:** Verify concurrent sync attempts are handled correctly

---

### 10. Implement Conflict Resolution
**File:** `Data/Sync/SyncEngine.swift`
**Risk:** User's offline changes silently lost

**Current Code:**
```swift
// Downloads overwrite everything
for dto in dtos {
    let area = dto.toDomain
    try cacheService.saveArea(area, syncState: .synced)  // ⚠️ Overwrites pending!
}
```

**Fix:**
```swift
for dto in dtos {
    // Check for pending local changes
    if let cached = try? cacheService.fetchArea(id: dto.id),
       cached.syncState == .pending {
        // Resolve conflict using timestamps
        let shouldKeepLocal = cached.updatedAt > dto.updatedAt
        if shouldKeepLocal {
            continue  // Skip download, will be uploaded later
        }
    }

    let area = dto.toDomain
    try cacheService.saveArea(area, syncState: .synced)
}
```

**Testing:** Verify offline changes not lost during sync

---

### 11. Fix CacheService MainActor Blocking
**File:** `Data/Cache/CacheService.swift` line 8
**Risk:** UI freezes, ANR errors

**Current Code:**
```swift
@MainActor  // ⚠️ All operations block main thread
public final class CacheService {
```

**Fix:** Remove @MainActor, use background ModelContext:
```swift
// Remove @MainActor annotation
public final class CacheService {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    public init() throws {
        self.modelContainer = try ModelContainer(
            for: CachedArea.self, CachedGoal.self,
            CachedMeasurement.self, CachedOccurrence.self
        )

        // Create background context
        self.modelContext = ModelContext(modelContainer)
        modelContext.autosaveEnabled = true
    }

    // All methods now run on background thread
    public func fetchAreas(userId: UUID) throws -> [Area] {
        // No MainActor.run needed
        let descriptor = FetchDescriptor<CachedArea>(...)
        let cached = try modelContext.fetch(descriptor)
        return cached.map { $0.toDomain() }
    }
}
```

**Testing:** Verify UI remains responsive during cache operations

---

### 12. Implement Cascade Deletes
**Files:** All cache models
**Risk:** Orphaned data, memory bloat

**Current Code:**
```swift
@Model
public final class CachedGoal {
    public var areaId: UUID  // ⚠️ Just UUID, no relationship
}
```

**Fix:**
```swift
@Model
public final class CachedArea {
    @Attribute(.unique) public var id: UUID
    public var name: String
    // ...

    // Add relationship
    @Relationship(deleteRule: .cascade, inverse: \CachedGoal.area)
    public var goals: [CachedGoal] = []
}

@Model
public final class CachedGoal {
    @Attribute(.unique) public var id: UUID
    public var title: String
    // ...

    // Change from UUID to relationship
    public var area: CachedArea?  // ✅ Proper relationship

    @Relationship(deleteRule: .cascade, inverse: \CachedOccurrence.goal)
    public var occurrences: [CachedOccurrence] = []
}
```

**Testing:** Verify deleting area deletes all associated goals

---

## Testing Checklist

After implementing fixes, verify:

- [ ] App starts without hardcoded credentials
- [ ] Auth tokens stored in Keychain
- [ ] Weak passwords rejected
- [ ] Measurement.isActive doesn't crash
- [ ] Concurrent fetches handled correctly
- [ ] Cache updated after RPC calls
- [ ] Measurement fetch works by ID
- [ ] GoalSchedule preserves all fields
- [ ] Concurrent syncs prevented
- [ ] Offline changes not lost
- [ ] UI responsive during cache ops
- [ ] Deleting area deletes goals
- [ ] All existing tests still pass
- [ ] No new crashes or errors

---

## Priority Order

1. **Security (1-3):** Remove credentials, Keychain, validation
2. **Crash Risk (4):** Fix force unwrap
3. **Data Integrity (5-12):** Fix race conditions, cache issues, sync

**Estimated Time:** 40-60 hours (1-1.5 weeks)

---

## After Critical Fixes

Next priorities:
- Add transaction boundaries for deletes
- Implement offline queueing for RPC
- Add retry logic with exponential backoff
- Fix expensive DateFormatters
- Add comprehensive error handling

See COMPREHENSIVE_AUDIT_FINDINGS.md for full list.
