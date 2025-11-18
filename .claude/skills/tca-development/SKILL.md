---
name: tca-development
description: Implements The Composable Architecture (TCA) 1.23.1 patterns in Swift. Use when creating reducers, handling actions, managing state, integrating dependencies, or debugging TCA features. Keywords @Reducer, @ObservableState, @Dependency, @Presents, action, reduce, effect, store, TCA.
allowed-tools: Read, Write, Edit, Grep, Glob
---

# TCA Development (The Composable Architecture 1.23.1)

Implements modern TCA patterns following version 1.23.1 best practices for this HabitTracker project.

## When to Use

Activate when:
- Creating new TCA features
- Adding actions to existing reducers
- Managing feature state
- Integrating dependencies (repositories)
- Composing child features
- Presenting sheets/alerts
- Debugging TCA state flows
- User mentions "reducer", "action", "state", "TCA", "store"

## Project TCA Structure

This project uses TCA for ALL features:
- AppFeature (root with tab navigation)
- TodayFeature (main screen)
- AreasFeature, AreaEditorFeature, AreaDetailFeature
- InsightsFeature
- ProgramsFeature, ProgramDetailFeature
- SettingsFeature

**Location:** `HabitTracker/Sources/HabitTracker/Features/*/`

## TCA 1.23.1 Patterns

### 1. Feature Structure

**Standard feature file:**

```swift
import ComposableArchitecture

@Reducer
struct FeatureNameFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var items: IdentifiedArrayOf<Item> = []
        var isLoading: Bool = false
        var error: String?

        // Child features
        @Presents var editor: EditorFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
    }

    // MARK: - Action

    enum Action: Sendable {
        // Lifecycle
        case task
        case refresh

        // User interactions
        case itemTapped(UUID)
        case addButtonTapped
        case deleteButtonTapped(UUID)

        // Data responses
        case itemsResponse(TaskResult<[Item]>)
        case deleteResponse(UUID, TaskResult<Void>)

        // Child features
        case editor(PresentationAction<EditorFeature.Action>)
        case alert(PresentationAction<Alert>)

        // Delegate (optional)
        case delegate(Delegate)

        enum Alert: Sendable {
            case confirmDelete
        }

        enum Delegate: Sendable {
            case itemDeleted(UUID)
        }
    }

    // MARK: - Dependencies

    @Dependency(\.itemRepository) var repository
    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .run { send in
                    await send(.itemsResponse(
                        TaskResult { try await repository.fetchAll() }
                    ))
                }

            case let .itemsResponse(.success(items)):
                state.items = IdentifiedArray(uniqueElements: items)
                state.isLoading = false
                return .none

            case let .itemsResponse(.failure(error)):
                state.error = error.localizedDescription
                state.isLoading = false
                return .none

            case .itemTapped(let id):
                // Handle tap
                return .none

            case .addButtonTapped:
                state.editor = EditorFeature.State(mode: .create)
                return .none

            case .deleteButtonTapped(let id):
                state.alert = AlertState {
                    TextState("Delete Item")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete) {
                        TextState("Delete")
                    }
                } message: {
                    TextState("This cannot be undone.")
                }
                return .none

            case .alert(.presented(.confirmDelete)):
                guard let id = state.selectedItemId else { return .none }
                return .run { send in
                    await send(.deleteResponse(
                        id,
                        TaskResult { try await repository.delete(id) }
                    ))
                }

            case let .deleteResponse(id, .success):
                state.items.remove(id: id)
                return .send(.delegate(.itemDeleted(id)))

            case .editor(.presented(.delegate(.itemSaved))):
                state.editor = nil
                return .send(.refresh)

            case .editor, .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$editor, action: \.editor) {
            EditorFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
```

### 2. @ObservableState

**Use for all state structs:**

```swift
@ObservableState
struct State: Equatable {
    var count: Int = 0
    var name: String = ""

    // Automatically observable - no @Published needed!
}
```

**Benefits:**
- Granular UI updates (only changed properties trigger re-renders)
- No @Published wrappers
- Better performance
- Simpler code

### 3. @Presents for Child Features

**Sheets and navigation:**

```swift
@ObservableState
struct State: Equatable {
    @Presents var editor: EditorFeature.State?
    @Presents var detail: DetailFeature.State?
    @Presents var alert: AlertState<Action.Alert>?
}

enum Action {
    case editor(PresentationAction<EditorFeature.Action>)
    case detail(PresentationAction<DetailFeature.Action>)
    case alert(PresentationAction<Alert>)
}

var body: some ReducerOf<Self> {
    Reduce { /* main reducer */ }
        .ifLet(\.$editor, action: \.editor) {
            EditorFeature()
        }
        .ifLet(\.$detail, action: \.detail) {
            DetailFeature()
        }
        .ifLet(\.$alert, action: \.alert)
}
```

**SwiftUI binding:**

```swift
struct MyView: View {
    @Bindable var store: StoreOf<MyFeature>

    var body: some View {
        NavigationStack {
            // Main content
        }
        .sheet(
            item: $store.scope(state: \.editor, action: \.editor)
        ) { store in
            EditorView(store: store)
        }
    }
}
```

### 4. @Dependency Injection

**Register dependencies:**

```swift
// Declare dependency
extension DependencyValues {
    var goalRepository: GoalRepository {
        get { self[GoalRepositoryKey.self] }
        set { self[GoalRepositoryKey.self] = newValue }
    }
}

private enum GoalRepositoryKey: DependencyKey {
    static let liveValue: GoalRepository = SupabaseGoalRepository()
    static let testValue: GoalRepository = MockGoalRepository()
}
```

**Use in reducer:**

```swift
@Reducer
struct MyFeature {
    @Dependency(\.goalRepository) var repository
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchGoals:
                return .run { send in
                    let goals = try await repository.fetchAll()
                    await send(.goalsResponse(.success(goals)))
                }
            }
        }
    }
}
```

### 5. Effects (Async Operations)

**Run async work:**

```swift
case .task:
    return .run { send in
        // Parallel operations
        async let items = repository.fetchItems()
        async let stats = repository.fetchStats()

        await send(.itemsResponse(TaskResult { try await items }))
        await send(.statsResponse(TaskResult { try await stats }))
    }

// Sequential with cancellation
case .search(let query):
    return .run { send in
        try await clock.sleep(for: .milliseconds(300)) // Debounce
        let results = try await searchRepository.search(query)
        await send(.searchResults(results))
    }
    .cancellable(id: CancelID.search, cancelInFlight: true)

// Long-running task
case .startMonitoring:
    return .run { send in
        for await event in eventStream {
            await send(.eventReceived(event))
        }
    }
    .cancellable(id: CancelID.monitoring)

case .stopMonitoring:
    return .cancel(id: CancelID.monitoring)
```

**Cancel IDs:**

```swift
enum CancelID {
    case search
    case monitoring
    case sync
}
```

### 6. Computed Properties

**Derive state efficiently:**

```swift
@ObservableState
struct State: Equatable {
    var occurrences: IdentifiedArrayOf<GoalOccurrence> = []

    var pendingOccurrences: IdentifiedArrayOf<GoalOccurrence> {
        IdentifiedArray(uniqueElements: occurrences.filter { $0.isPending })
    }

    var completedOccurrences: IdentifiedArrayOf<GoalOccurrence> {
        IdentifiedArray(uniqueElements: occurrences.filter { $0.isComplete })
    }

    var completionRate: Double {
        guard !occurrences.isEmpty else { return 0 }
        let completed = occurrences.filter { $0.isComplete }.count
        return Double(completed) / Double(occurrences.count)
    }
}
```

### 7. BindableAction (for Forms)

**Two-way binding:**

```swift
@Reducer
struct FormFeature {
    @ObservableState
    struct State: Equatable {
        var name: String = ""
        var email: String = ""
        var agreedToTerms: Bool = false
    }

    enum Action: Sendable, BindableAction {
        case binding(BindingAction<State>)
        case submitTapped
    }

    var body: some ReducerOf<Self> {
        BindableReducer() // Handles all binding actions automatically

        Reduce { state, action in
            switch action {
            case .binding:
                // Automatically handled by BindableReducer
                return .none

            case .submitTapped:
                // Use state.name, state.email, etc.
                return .none
            }
        }
    }
}
```

**View binding:**

```swift
struct FormView: View {
    @Bindable var store: StoreOf<FormFeature>

    var body: some View {
        Form {
            TextField("Name", text: $store.name)
            TextField("Email", text: $store.email)
            Toggle("Agree to terms", isOn: $store.agreedToTerms)

            Button("Submit") {
                store.send(.submitTapped)
            }
        }
    }
}
```

### 8. Feature Composition

**Parent-child relationship:**

```swift
@Reducer
struct ParentFeature {
    @ObservableState
    struct State: Equatable {
        var child1 = ChildFeature1.State()
        var child2 = ChildFeature2.State()
    }

    enum Action {
        case child1(ChildFeature1.Action)
        case child2(ChildFeature2.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.child1, action: \.child1) {
            ChildFeature1()
        }
        Scope(state: \.child2, action: \.child2) {
            ChildFeature2()
        }

        Reduce { state, action in
            switch action {
            case .child1, .child2:
                return .none
            }
        }
    }
}
```

## Testing TCA Features

**TestStore:**

```swift
@Test("Feature loads items on task")
func testLoadItems() async {
    let store = TestStore(initialState: MyFeature.State()) {
        MyFeature()
    } withDependencies: {
        $0.itemRepository = MockItemRepository()
        $0.uuid = .constant(UUID(0))
    }

    await store.send(.task) {
        $0.isLoading = true
    }

    await store.receive(\.itemsResponse.success) {
        $0.isLoading = false
        $0.items = [Item.mock1, Item.mock2]
    }
}
```

## Best Practices

### DO:
✅ Use @Reducer macro
✅ Mark State as @ObservableState and Equatable
✅ Mark Actions as Sendable
✅ Use @Dependency for all external dependencies
✅ Use @Presents for child features
✅ Return .none when no effects needed
✅ Use IdentifiedArrayOf for lists
✅ Use TaskResult for async error handling
✅ Debounce with .cancellable
✅ Write exhaustive tests with TestStore

### DON'T:
❌ Mutate state outside reducer
❌ Perform side effects directly in reducer
❌ Forget to mark actions as Sendable
❌ Skip .none returns
❌ Use regular arrays for item lists (use IdentifiedArrayOf)
❌ Perform network calls in State properties
❌ Forget to cancel long-running effects
❌ Mix @Published with @ObservableState

## Common Patterns

### Optimistic UI Updates

```swift
case .completeTick(let id):
    // Optimistically update UI
    state.occurrences[id: id]?.incrementCompletion()

    // Then sync with server
    return .run { send in
        await send(.completeTickResponse(
            id,
            TaskResult { try await repository.completeTick(id) }
        ))
    }

case .completeTickResponse(let id, .failure(let error)):
    // Rollback on error
    state.occurrences[id: id]?.decrementCompletion()
    state.error = error.localizedDescription
    return .none
```

### Debouncing

```swift
case .searchQueryChanged(let query):
    state.searchQuery = query

    return .run { send in
        try await clock.sleep(for: .milliseconds(300))
        await send(.performSearch(query))
    }
    .cancellable(id: CancelID.search, cancelInFlight: true)
```

### Refreshing Data

```swift
case .refresh:
    return .send(.task).cancellable(id: CancelID.refresh)
```

## Integration with This Project

**Repository pattern:**

```swift
// Define protocol
protocol GoalRepository: Sendable {
    func fetchAll() async throws -> [Goal]
}

// Register dependency
extension DependencyValues {
    var goalRepository: GoalRepository {
        get { self[GoalRepositoryKey.self] }
        set { self[GoalRepositoryKey.self] = newValue }
    }
}

// Use in feature
@Reducer
struct GoalsFeature {
    @Dependency(\.goalRepository) var repository

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            case .task:
                return .run { send in
                    let goals = try await repository.fetchAll()
                    await send(.goalsResponse(.success(goals)))
                }
        }
    }
}
```

## Related Skills

- **swift-development** - Swift coding patterns
- **supabase-integration** - Repository implementations
- **swiftui-best-practices** - View integration
- **skill-creator** - Create TCA-specific skills as needed
