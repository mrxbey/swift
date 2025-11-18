//
// AreasView.swift
// HabitTracker
//

import SwiftUI
import ComposableArchitecture

struct AreasView: View {
    @Bindable var store: StoreOf<AreasFeature>

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.medium) {
                    ForEach(store.areas) { area in
                        AreaCard(area: area) {
                            store.send(.areaTapped(area.id))
                        }
                    }
                }
                .padding()
            }
            .background(Theme.Colors.background)
            .navigationTitle("Areas")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addAreaTapped)
                    } label: {
                        Image(systemName: Theme.Icons.add)
                    }
                }
            }
            .overlay {
                if store.areas.isEmpty {
                    emptyState
                }
            }
            .sheet(
                item: $store.scope(state: \.areaEditor, action: \.areaEditor)
            ) { store in
                AreaEditorView(store: store)
            }
            .sheet(
                item: $store.scope(state: \.areaDetail, action: \.areaDetail)
            ) { store in
                AreaDetailView(store: store)
            }
            .task {
                store.send(.task)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: Theme.Icons.areas)
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondaryText)

            Text("No areas yet")
                .font(Theme.Typography.title3)

            Text("Organize your goals into life areas like Work, Health, and Personal")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - AreaCard

struct AreaCard: View {
    let area: Area
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.medium) {
                // Color indicator
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(Color(hex: area.colorHex ?? "#4ECDC4"))
                    .frame(width: 4)

                // Emoji
                if let emoji = area.emoji {
                    Text(emoji)
                        .font(Theme.Typography.emoji)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(area.name)
                        .font(Theme.Typography.bodyBold)
                        .foregroundColor(Theme.Colors.text)

                    Text(area.status.displayName)
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

// MARK: - AreaEditorView

struct AreaEditorView: View {
    @Bindable var store: StoreOf<AreaEditorFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Area Name", text: $store.name)

                    Picker("Emoji", selection: $store.selectedEmoji) {
                        Text("None").tag(String?.none)
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Text(emoji).tag(String?.some(emoji))
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Theme.Spacing.medium) {
                        ForEach(Theme.Colors.areaColors.indices, id: \.self) { index in
                            ColorButton(
                                color: Theme.Colors.areaColors[index],
                                isSelected: store.selectedColorIndex == index
                            ) {
                                store.send(.colorSelected(index))
                            }
                        }
                    }
                }
            }
            .navigationTitle(store.mode == .create ? "New Area" : "Edit Area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.cancelTapped)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.send(.saveTapped)
                    }
                    .disabled(store.name.isEmpty)
                }
            }
        }
    }

    private let emojiOptions = ["💼", "💪", "🧘", "🎨", "📚", "🏠", "🌱", "❤️", "✈️", "🎯"]
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white, lineWidth: isSelected ? 4 : 0)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
    }
}

// MARK: - AreaDetailView

struct AreaDetailView: View {
    @Bindable var store: StoreOf<AreaDetailFeature>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    // Header
                    VStack(spacing: Theme.Spacing.medium) {
                        if let emoji = store.area.emoji {
                            Text(emoji)
                                .font(Theme.Typography.emojiLarge)
                        }

                        Text(store.area.name)
                            .font(Theme.Typography.title1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: store.area.colorHex ?? "#4ECDC4").opacity(0.1))

                    // Goals in this area
                    VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                        Text("Goals")
                            .font(Theme.Typography.title3)

                        if store.goals.isEmpty {
                            Text("No goals in this area yet")
                                .font(Theme.Typography.callout)
                                .foregroundColor(Theme.Colors.secondaryText)
                        } else {
                            ForEach(store.goals) { goal in
                                GoalRowSimple(goal: goal)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(store.area.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Edit", systemImage: Theme.Icons.edit) {
                            store.send(.editTapped)
                        }

                        Button(
                            store.area.status == .active ? "Pause" : "Resume",
                            systemImage: store.area.status == .active ? "pause" : "play"
                        ) {
                            store.send(.togglePauseTapped)
                        }

                        Button("Archive", systemImage: "archivebox") {
                            store.send(.archiveTapped)
                        }

                        Divider()

                        Button("Delete", systemImage: Theme.Icons.delete, role: .destructive) {
                            store.send(.deleteTapped)
                        }
                    } label: {
                        Image(systemName: Theme.Icons.more)
                    }
                }
            }
            .alert($store.scope(state: \.deleteConfirmation, action: \.deleteConfirmation))
        }
    }
}

struct GoalRowSimple: View {
    let goal: Goal

    var body: some View {
        HStack {
            if let emoji = goal.emoji {
                Text(emoji)
            }

            Text(goal.title)
                .font(Theme.Typography.body)

            Spacer()

            Image(systemName: goal.kind.icon)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Features

@Reducer
struct AreasFeature {
    @ObservableState
    struct State: Equatable {
        var areas: IdentifiedArrayOf<Area> = []
        @Presents var areaEditor: AreaEditorFeature.State?
        @Presents var areaDetail: AreaDetailFeature.State?
    }

    enum Action: Sendable {
        case task
        case areasResponse(TaskResult<[Area]>)
        case areaTapped(UUID)
        case addAreaTapped
        case areaEditor(PresentationAction<AreaEditorFeature.Action>)
        case areaDetail(PresentationAction<AreaDetailFeature.Action>)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .none

            case .areasResponse(.success(let areas)):
                state.areas = IdentifiedArray(uniqueElements: areas)
                return .none

            case .areasResponse(.failure):
                return .none

            case .areaTapped(let id):
                guard let area = state.areas[id: id] else { return .none }
                state.areaDetail = AreaDetailFeature.State(area: area, goals: [])
                return .none

            case .addAreaTapped:
                state.areaEditor = AreaEditorFeature.State(mode: .create)
                return .none

            case .areaEditor, .areaDetail:
                return .none
            }
        }
        .ifLet(\.$areaEditor, action: \.areaEditor) {
            AreaEditorFeature()
        }
        .ifLet(\.$areaDetail, action: \.areaDetail) {
            AreaDetailFeature()
        }
    }
}

@Reducer
struct AreaEditorFeature {
    @ObservableState
    struct State: Equatable {
        enum Mode: Equatable {
            case create
            case edit(Area)
        }

        var mode: Mode
        var name: String = ""
        var selectedEmoji: String?
        var selectedColorIndex: Int = 0

        init(mode: Mode) {
            self.mode = mode
            if case .edit(let area) = mode {
                self.name = area.name
                self.selectedEmoji = area.emoji
                if let colorHex = area.colorHex,
                   let index = Theme.Colors.areaColors.firstIndex(where: { $0.description.contains(colorHex) }) {
                    self.selectedColorIndex = index
                }
            }
        }
    }

    enum Action: Sendable {
        case colorSelected(Int)
        case saveTapped
        case cancelTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .colorSelected(let index):
                state.selectedColorIndex = index
                return .none

            case .saveTapped, .cancelTapped:
                return .none
            }
        }
    }
}

@Reducer
struct AreaDetailFeature {
    @ObservableState
    struct State: Equatable {
        var area: Area
        var goals: IdentifiedArrayOf<Goal> = []
        @Presents var deleteConfirmation: AlertState<Action.Alert>?
    }

    enum Action: Sendable {
        case editTapped
        case togglePauseTapped
        case archiveTapped
        case deleteTapped
        case deleteConfirmation(PresentationAction<Alert>)

        enum Alert: Sendable {
            case confirmDelete
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .editTapped:
                return .none

            case .togglePauseTapped:
                return .none

            case .archiveTapped:
                return .none

            case .deleteTapped:
                state.deleteConfirmation = AlertState {
                    TextState("Delete Area")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete) {
                        TextState("Delete")
                    }
                } message: {
                    TextState("This will delete the area and ALL goals within it. This cannot be undone.")
                }
                return .none

            case .deleteConfirmation:
                return .none
            }
        }
        .ifLet(\.$deleteConfirmation, action: \.deleteConfirmation)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    AreasView(
        store: Store(initialState: AreasFeature.State(
            areas: [.mock, .mockWork, .mockPersonal]
        )) {
            AreasFeature()
        }
    )
}
#endif
