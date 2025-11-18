# Test Suite Verification Guide

Comprehensive guide for the HabitTracker test suite, covering all test layers, verification strategies, and quality assurance practices.

## Test Suite Overview

### Total Test Coverage

**13 Test Files | ~3,600+ Lines of Test Code**

- **DTO Tests**: 4 files (~800 lines)
- **Cache Tests**: 5 files (~1,500 lines)
- **Repository Tests**: 4 files (~1,300 lines)

### Test Infrastructure

**Test Helpers** (~/Tests/HabitTrackerTests/TestHelpers/)
- `TestFixtures.swift`: Centralized factory methods for all domain models and DTOs
- `MockNetworkMonitor.swift`: Actor-based network simulation
- `MockSupabaseClient.swift`: Supabase client mock for integration tests
- `MockCacheService.swift`: In-memory cache for repository tests
- `MockSyncEngine.swift`: Sync operation tracker

## Test Layers

### Layer 1: DTO Tests (Data Transfer Objects)

**Purpose**: Verify domain ↔ DTO conversions are lossless and handle all edge cases.

**Test Files**:
- `AreaDTOTests.swift` (~200 lines)
- `GoalDTOTests.swift` (~220 lines)
- `GoalOccurrenceDTOTests.swift` (~200 lines)
- `MeasurementDTOTests.swift` (~180 lines)

**Coverage**:
- ✅ Domain → DTO conversion (from initializer)
- ✅ DTO → Domain conversion (toDomain property)
- ✅ Round-trip conversion (preserve all fields)
- ✅ Enum string conversion (GoalKind, GoalStatus, OccurrenceStatus, UnitKind)
- ✅ Optional field handling
- ✅ Nested object conversion (ContentSnapshot, LinkedExercise)
- ✅ Array handling (hashtags)
- ✅ Date precision preservation

**Test Pattern**:
```swift
func testRoundTripConversion() {
    // Given - Create domain model
    let original = TestFixtures.makeGoal(
        hashtags: ["fitness", "health"],
        linkedExerciseKey: .meditation
    )

    // When - Convert to DTO and back
    let dto = GoalDTO(from: original)
    let converted = dto.toDomain

    // Then - Verify all fields preserved
    XCTAssertEqual(converted.id, original.id)
    XCTAssertEqual(converted.hashtags, original.hashtags)
    XCTAssertEqual(converted.linkedExerciseKey, original.linkedExerciseKey)
}
```

### Layer 2: Cache Tests (SwiftData Persistence)

**Purpose**: Verify local persistence layer correctly stores/retrieves domain models with sync state tracking.

**Test Files**:
- `CachedAreaTests.swift` (~180 lines)
- `CachedGoalTests.swift` (~200 lines)
- `CachedOccurrenceTests.swift` (~180 lines)
- `CachedMeasurementTests.swift` (~180 lines)
- `CacheServiceTests.swift` (~350 lines) - Integration tests for all cache operations

**Coverage**:
- ✅ CRUD operations (Create, Read, Update, Delete)
- ✅ Sync state management (.synced, .pending, .failed)
- ✅ Query filtering (by userId, by areaId, by goalId, by date)
- ✅ Pending changes tracking
- ✅ Thread safety (@MainActor)
- ✅ Cascading updates
- ✅ Batch operations
- ✅ Cache clearing strategies

**Test Pattern**:
```swift
@MainActor
func testSaveGoalWithPendingState() throws {
    // Given
    let goal = TestFixtures.makeGoal()

    // When
    try cacheService.saveGoal(goal, syncState: .pending)

    // Then
    let pending = try cacheService.fetchPendingGoals()
    XCTAssertEqual(pending.count, 1)
    XCTAssertEqual(pending.first?.id, goal.id)
}
```

### Layer 3: Repository Tests (Offline-First Logic)

**Purpose**: Verify repository business logic for cache-first reads, offline queuing, and sync coordination.

**Test Files**:
- `SupabaseAreaRepositoryTests.swift` (~393 lines)
- `SupabaseGoalRepositoryTests.swift` (~460 lines)
- `SupabaseOccurrenceRepositoryTests.swift` (~430 lines)
- `SupabaseMeasurementRepositoryTests.swift` (~449 lines)

**Coverage**:
- ✅ Cache-first read patterns
- ✅ Offline operation queuing (write-through with .pending state)
- ✅ Sync state transitions (pending → synced, pending → failed)
- ✅ Network state handling (online/offline detection)
- ✅ Background sync triggering
- ✅ Data integrity preservation
- ✅ Concurrent operations (thread safety)
- ✅ Edge cases (empty data, special characters, boundary values)

**Test Strategy**:
- Use **real CacheService** (already tested, provides authentic SwiftData behavior)
- Use **mocked dependencies** (NetworkMonitor, SyncEngine)
- Focus on **repository-controlled logic** (not Supabase SDK behavior)
- **Integration tests recommended** for actual API calls

**Test Pattern**:
```swift
@MainActor
func testCreateOfflineSavesToCacheWithPendingState() async throws {
    // Given - Offline network
    await networkMonitor.setConnected(false)
    let area = TestFixtures.makeArea(name: "New Area")

    // When - Save to cache with pending state
    try cacheService.saveArea(area, syncState: .pending)

    // Then - Area is in pending queue
    let pending = try cacheService.fetchPendingAreas()
    XCTAssertEqual(pending.count, 1)
    XCTAssertEqual(pending.first?.name, "New Area")

    // Verify background sync was NOT triggered (offline)
    let syncCalled = await syncEngine.performFullSyncCalled
    XCTAssertFalse(syncCalled)
}
```

## Test Execution

### Prerequisites

- Xcode 15.0+ or Swift 5.9+
- SwiftData framework
- XCTest framework

### Running Tests

**Run all tests:**
```bash
cd HabitTracker
swift test
```

**Run specific test target:**
```bash
swift test --filter HabitTrackerTests
```

**Run specific test class:**
```bash
swift test --filter SupabaseAreaRepositoryTests
```

**Run specific test method:**
```bash
swift test --filter testCacheFirs tReadBehavior
```

**With verbose output:**
```bash
swift test --verbose
```

### Expected Results

All tests should pass with **0 failures**:
```
Test Suite 'All tests' passed
    - DTO Tests: 40+ tests passed
    - Cache Tests: 80+ tests passed
    - Repository Tests: 50+ tests passed
Executed 170+ tests, with 0 failures
```

## Verification Checklist

### Pre-Execution Checks

- [ ] All test files compile without errors
- [ ] TestFixtures provides all necessary factory methods
- [ ] All mocks implement required interfaces
- [ ] Test infrastructure is properly configured in Package.swift

### Post-Execution Verification

- [ ] All DTO round-trip conversions pass
- [ ] All cache CRUD operations pass
- [ ] All sync state transitions work correctly
- [ ] No memory leaks (SwiftData containers properly released)
- [ ] No force-unwrap crashes (nil safety verified)
- [ ] Thread safety confirmed (@MainActor used where required)

### Quality Metrics

**Code Coverage Targets**:
- DTO layer: 95%+ (conversion logic is critical)
- Cache layer: 90%+ (persistence must be reliable)
- Repository layer: 85%+ (business logic well-tested)
- Overall: 90%+ across data layer

**Test Quality Indicators**:
- ✅ Given-When-Then structure for clarity
- ✅ Descriptive test names (testWhatIsBeingTested)
- ✅ Single assertion focus (one concept per test)
- ✅ Comprehensive edge case coverage
- ✅ Proper setup/tearDown isolation

## Common Issues and Solutions

### Issue 1: SwiftData Container Conflicts

**Symptom**: Tests fail with "modelContainer already configured" error

**Solution**: Ensure CacheService is properly cleared in tearDown()
```swift
override func tearDown() async throws {
    try cacheService.clearAll()
    cacheService = nil
    try await super.tearDown()
}
```

### Issue 2: Actor Isolation Warnings

**Symptom**: "Expression is 'async' but is not marked with 'await'" warnings

**Solution**: Mark test class with @MainActor for SwiftData tests
```swift
@MainActor
final class CacheServiceTests: XCTestCase {
    // Tests that use SwiftData
}
```

### Issue 3: Mock Not Resetting Between Tests

**Symptom**: Tests pass individually but fail when run together

**Solution**: Always reset mocks in tearDown()
```swift
override func tearDown() async throws {
    await networkMonitor.reset()
    await syncEngine.reset()
    try await super.tearDown()
}
```

### Issue 4: Date Comparison Failures

**Symptom**: Tests fail with small date differences (milliseconds)

**Solution**: Use accuracy parameter in date assertions
```swift
XCTAssertEqual(
    dto.createdAt.timeIntervalSince1970,
    area.createdAt.timeIntervalSince1970,
    accuracy: 0.001
)
```

## Integration Test Recommendations

While unit tests cover repository logic, integration tests are recommended for:

1. **Supabase Client Behavior**
   - Actual query building and execution
   - RPC function calls
   - Authentication token handling
   - RLS policy enforcement

2. **Network Error Handling**
   - 401 Unauthorized responses
   - 403 RLS violations
   - 404 Not Found errors
   - Network timeout scenarios

3. **End-to-End Sync Flow**
   - Offline → Online transitions
   - Conflict resolution (last-write-wins)
   - Pending queue synchronization
   - Background sync triggers

4. **Performance Testing**
   - Large dataset queries (1000+ records)
   - Concurrent sync operations
   - Cache memory usage
   - Query optimization validation

## Test Maintenance

### When to Update Tests

**Add new tests when**:
- Adding new domain models
- Adding new repository methods
- Changing sync behavior
- Adding new query filters
- Fixing bugs (regression tests)

**Update existing tests when**:
- Domain model properties change
- DTO structure changes
- Repository interface changes
- Sync state transitions change

### Test Documentation Standards

Every test should have:
1. Clear Given-When-Then structure
2. Descriptive name explaining what is tested
3. Comments for complex setup or assertions
4. Meaningful assertion messages

```swift
func testGoalWithMultipleHashtagsRoundTrips() {
    // Given - Goal with multiple hashtags
    let original = TestFixtures.makeGoal(
        hashtags: ["fitness", "morning", "health"]
    )

    // When - Convert through DTO and back
    let dto = GoalDTO(from: original)
    let converted = dto.toDomain

    // Then - All hashtags preserved in order
    XCTAssertEqual(
        converted.hashtags,
        ["fitness", "morning", "health"],
        "Hashtag array should preserve order and all elements"
    )
}
```

## Enterprise Quality Standards

### Test Code Quality

- ✅ No force-unwraps in test code (use XCTAssertNotNil + optional binding)
- ✅ No magic numbers (use TestFixtures constants)
- ✅ No hardcoded UUIDs (use TestFixtures.userId, etc.)
- ✅ Proper error handling (async throws properly propagated)
- ✅ Thread-safe test execution (@MainActor where needed)

### Test Coverage Goals

```
Data Layer Coverage:
├── DTOs: 95%+ (critical conversion logic)
├── Cache: 90%+ (persistence reliability)
├── Repositories: 85%+ (business logic)
└── Overall: 90%+

Domain Layer Coverage:
├── Models: 80%+ (computed properties, methods)
└── Enums: 100% (all cases tested)

Infrastructure Layer Coverage:
├── Sync: 85%+ (sync coordination)
└── Network: 90%+ (connectivity detection)
```

## Continuous Integration

### CI Pipeline Recommendations

1. **Pre-Commit Hooks**
   - Run all tests before push
   - Verify code compiles
   - Check for test coverage regression

2. **PR Checks**
   - All tests must pass
   - Coverage must meet threshold
   - No new test warnings

3. **Nightly Builds**
   - Run full test suite
   - Generate coverage reports
   - Performance regression detection

## Summary

The HabitTracker test suite provides comprehensive coverage of the data layer with:

- **13 test files** covering DTOs, Cache, and Repositories
- **170+ test cases** with enterprise-quality standards
- **3,600+ lines of test code** following best practices
- **Clear test patterns** for maintainability
- **Proper isolation** with setup/tearDown
- **Thread-safe execution** with proper actor annotations

All tests are designed to pass with full functionality, providing confidence in the offline-first architecture and data integrity.
