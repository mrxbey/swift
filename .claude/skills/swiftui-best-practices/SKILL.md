---
name: swiftui-best-practices
description: Implements modern SwiftUI views using iOS 17+ features. Use when creating views, building UI components, working with @Observable, NavigationStack, Charts, or when user mentions SwiftUI, View, @Bindable, preview, layout, animation.
allowed-tools: Read, Write, Edit, Grep, Glob
---

# SwiftUI Best Practices (iOS 17+)

Implements modern SwiftUI patterns for this HabitTracker project using iOS 17+ features.

## When to Use

Activate when:
- Creating new SwiftUI views
- Building reusable UI components
- Working with @Observable models
- Implementing navigation
- Adding animations
- Creating previews
- Debugging layout issues
- User mentions "view", "SwiftUI", "UI", "screen", "component"

## Project SwiftUI Structure

**This project:**
- iOS 17+ minimum (uses @Observable)
- Design system in `DesignSystem/Theme.swift`
- TCA integration via @Bindable
- 5 main features with views
- Reusable components

## iOS 17+ Features

### 1. @Observable (instead of ObservableObject)

**OLD way (don't use):**
```swift
class ViewModel: ObservableObject {
    @Published var count: Int = 0
    @Published var name: String = ""
}

struct MyView: View {
    @StateObject var viewModel = ViewModel()
}
```

**NEW way (use this):**
```swift
@Observable
class ViewModel {
    var count: Int = 0
    var name: String = ""
}

struct MyView: View {
    @State var viewModel = ViewModel()
    // or with TCA:
    @Bindable var store: StoreOf<MyFeature>
}
```

**Benefits:**
- 100% performance improvement
- Only re-renders views using changed properties
- No @Published needed
- Simpler code

### 2. @Bindable (for TCA stores)

```swift
struct MyView: View {
    @Bindable var store: StoreOf<MyFeature>

    var body: some View {
        Form {
            TextField("Name", text: $store.name)
            Toggle("Active", isOn: $store.isActive)
        }
    }
}
```

### 3. NavigationStack (not NavigationView)

**OLD:**
```swift
NavigationView {
    List { }
}
```

**NEW:**
```swift
NavigationStack {
    List { }
        .navigationTitle("Title")
        .navigationBarTitleDisplayMode(.inline)
}
```

### 4. Swift Charts

```swift
import Charts

struct CompletionChart: View {
    let data: [CompletionDataPoint]

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Rate", point.completionRate)
            )
            .foregroundStyle(
                point.completionRate >= 0.8 ? .green : .orange
            )
        }
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0])
        }
    }
}
```

## Design System Usage

**This project has a complete design system:**

### Colors
```swift
Theme.Colors.primary
Theme.Colors.secondary
Theme.Colors.accent
Theme.Colors.success / warning / error / info
Theme.Colors.background / secondaryBackground / tertiaryBackground
Theme.Colors.text / secondaryText / tertiaryText
Theme.Colors.areaColors[index]
Theme.Colors.statusColor(status)
```

### Typography
```swift
Theme.Typography.largeTitle
Theme.Typography.title1 / title2 / title3
Theme.Typography.body / bodyBold
Theme.Typography.callout / footnote / caption
Theme.Typography.emoji / emojiLarge
```

### Spacing
```swift
Theme.Spacing.xSmall    // 8
Theme.Spacing.small     // 12
Theme.Spacing.medium    // 16
Theme.Spacing.large     // 24
Theme.Spacing.xLarge    // 32
```

### Modifiers
```swift
myView
    .cardStyle()
    .primaryButtonStyle()
    .secondaryButtonStyle()
```

## View Structure

**Standard view template:**

```swift
import SwiftUI
import ComposableArchitecture

struct MyView: View {
    @Bindable var store: StoreOf<MyFeature>

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.large) {
                    headerSection
                    contentSection
                }
                .padding()
            }
            .background(Theme.Colors.background)
            .navigationTitle("My View")
            .toolbar {
                toolbarContent
            }
            .sheet(
                item: $store.scope(state: \.editor, action: \.editor)
            ) { store in
                EditorView(store: store)
            }
            .task {
                store.send(.task)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.medium) {
            // Header content
        }
    }

    private var contentSection: some View {
        VStack(spacing: Theme.Spacing.medium) {
            // Main content
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                store.send(.addTapped)
            } label: {
                Image(systemName: Theme.Icons.add)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MyView(
        store: Store(initialState: MyFeature.State()) {
            MyFeature()
        }
    )
}
```

## Common Patterns

### 1. Card Components

```swift
struct GoalCard: View {
    let goal: Goal
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.medium) {
                if let emoji = goal.emoji {
                    Text(emoji)
                        .font(Theme.Typography.emoji)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(Theme.Typography.bodyBold)
                        .foregroundColor(Theme.Colors.text)

                    Text(goal.status.displayName)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
            .padding()
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}
```

### 2. Empty States

```swift
private var emptyState: some View {
    VStack(spacing: Theme.Spacing.medium) {
        Image(systemName: "checkmark.circle")
            .font(.system(size: 60))
            .foregroundColor(Theme.Colors.secondaryText)

        Text("No items yet")
            .font(Theme.Typography.title3)

        Text("Tap the + button to add your first item")
            .font(Theme.Typography.callout)
            .foregroundColor(Theme.Colors.secondaryText)
            .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, Theme.Spacing.xxxLarge)
}
```

### 3. Loading States

```swift
var body: some View {
    ZStack {
        // Main content
        content

        // Loading overlay
        if store.isLoading {
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            ProgressView()
                .scaleEffect(1.5)
        }
    }
}

// Or inline:
.overlay {
    if store.isLoading {
        ProgressView()
    }
}
```

### 4. Lists (Lazy Loading)

```swift
ScrollView {
    LazyVStack(spacing: Theme.Spacing.medium) {
        ForEach(store.items) { item in
            ItemRow(item: item) {
                store.send(.itemTapped(item.id))
            }
        }
    }
    .padding()
}
```

### 5. Grids

```swift
LazyVGrid(
    columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
    ],
    spacing: Theme.Spacing.medium
) {
    ForEach(store.programs) { program in
        ProgramCard(program: program) {
            store.send(.programTapped(program.id))
        }
    }
}
```

### 6. Forms

```swift
Form {
    Section("Basic Info") {
        TextField("Name", text: $store.name)

        Picker("Category", selection: $store.category) {
            ForEach(categories, id: \.self) { category in
                Text(category).tag(category)
            }
        }
    }

    Section("Preferences") {
        Toggle("Enabled", isOn: $store.isEnabled)

        if store.isEnabled {
            DatePicker(
                "Start Date",
                selection: $store.startDate,
                displayedComponents: .date
            )
        }
    }
}
```

### 7. Animations

```swift
// Implicit
.animation(Theme.Animation.spring, value: store.count)

// Explicit
withAnimation(Theme.Animation.spring) {
    store.send(.toggle)
}

// Custom
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
```

### 8. Swipe Actions

```swift
ForEach(store.items) { item in
    ItemRow(item: item)
        .swipeActions(edge: .trailing) {
            Button("Delete", systemImage: "trash", role: .destructive) {
                store.send(.deleteItem(item.id))
            }

            Button("Edit", systemImage: "pencil") {
                store.send(.editItem(item.id))
            }
            .tint(.blue)
        }
}
```

### 9. Context Menus

```swift
.contextMenu {
    Button("Edit", systemImage: Theme.Icons.edit) {
        store.send(.edit)
    }

    Button("Duplicate", systemImage: "doc.on.doc") {
        store.send(.duplicate)
    }

    Divider()

    Button("Delete", systemImage: Theme.Icons.delete, role: .destructive) {
        store.send(.delete)
    }
}
```

### 10. Async Images

```swift
AsyncImage(url: imageURL) { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fill)
} placeholder: {
    Rectangle()
        .fill(Theme.Colors.secondaryBackground)
        .overlay(ProgressView())
}
.frame(width: 120, height: 120)
.clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
```

## TCA Integration

### Sheets

```swift
// State
@Presents var editor: EditorFeature.State?

// Action
case editor(PresentationAction<EditorFeature.Action>)

// Reducer
.ifLet(\.$editor, action: \.editor) {
    EditorFeature()
}

// View
.sheet(
    item: $store.scope(state: \.editor, action: \.editor)
) { store in
    EditorView(store: store)
}
```

### Alerts

```swift
// State
@Presents var alert: AlertState<Action.Alert>?

// Action
case alert(PresentationAction<Alert>)
enum Alert: Sendable {
    case confirmDelete
}

// Reducer
case .deleteTapped:
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

// View
.alert($store.scope(state: \.alert, action: \.alert))
```

### Navigation

```swift
// For simple navigation, use NavigationStack with @Bindable
NavigationStack {
    List(store.items) { item in
        NavigationLink(value: item) {
            ItemRow(item: item)
        }
    }
    .navigationDestination(for: Item.self) { item in
        ItemDetailView(item: item)
    }
}
```

## Performance

### DO:
✅ Use LazyVStack/LazyVGrid for long lists
✅ Use .task for loading data (cancels automatically)
✅ Use @Bindable for TCA stores
✅ Use Theme constants (no magic numbers)
✅ Extract subviews when body gets complex
✅ Use GeometryReader sparingly
✅ Debounce expensive operations
✅ Use .onChange(of:) instead of .onReceive

### DON'T:
❌ Put logic in view body
❌ Perform expensive calculations in body
❌ Use NavigationView (deprecated)
❌ Use @StateObject with @Observable
❌ Forget .task cleanup (TCA handles this)
❌ Overuse animations
❌ Create new colors inline (use Theme)

## Accessibility

```swift
.accessibilityLabel("Add new goal")
.accessibilityHint("Creates a new goal in the selected area")
.accessibilityValue("\(count) goals")
.accessibilityAddTraits(.isButton)
```

## Preview Techniques

### Basic Preview

```swift
#Preview {
    MyView(
        store: Store(initialState: MyFeature.State()) {
            MyFeature()
        }
    )
}
```

### Multiple Variants

```swift
#Preview("Light Mode") {
    MyView(store: makeStore())
}

#Preview("Dark Mode") {
    MyView(store: makeStore())
        .preferredColorScheme(.dark)
}

#Preview("Loading") {
    MyView(store: makeStoreWithLoading())
}
```

### With Mock Data

```swift
#Preview {
    MyView(
        store: Store(
            initialState: MyFeature.State(
                items: [.mock1, .mock2, .mock3]
            )
        ) {
            MyFeature()
        } withDependencies: {
            $0.itemRepository = MockItemRepository()
        }
    )
}
```

## Common Issues

**Issue: View not updating**
- Check: Is state marked @ObservableState?
- Check: Is store marked @Bindable?
- Check: Are you sending actions correctly?

**Issue: Binding not working**
- Check: Using @Bindable var store
- Check: Using $ prefix for bindings
- Check: BindableAction in reducer

**Issue: Navigation not working**
- Check: Using NavigationStack (not NavigationView)
- Check: Proper scope in TCA
- Check: @Presents in state

## Project-Specific Patterns

This project uses:
- Card-based design (`.cardStyle()`)
- Emoji + text headers
- Progress rings for metrics
- Color-coded areas
- Swipe actions for quick operations
- Pull to refresh everywhere
- Empty states for all views

See existing views in `Features/` for examples.

## Related Skills

- **tca-development** - State management
- **swift-development** - Swift patterns
- **skill-creator** - Create UI-specific skills
