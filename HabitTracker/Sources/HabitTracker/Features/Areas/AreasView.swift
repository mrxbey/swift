//
// AreasView.swift
// HabitTracker
//

import SwiftUI
import ComposableArchitecture
import Dependencies

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

/// MARK: - AreaCard

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

/// MARK: - AreaEditorView

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

/// MARK: - AreaDetailView

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

/// MARK: - Features

@Reducer
struct AreasFeature {
    @ObservableState
    struct State: Equatable {
        var areas: IdentifiedArrayOf<Area> = []
        var isLoading = false
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
        case areaCreated(Area)
        case areaUpdated(Area)
        case areaDeleted(UUID)
    }

    @Dependency(\.areaRepository) var areaRepository
    @Dependency(\.goalRepository) var goalRepository

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .run { send in
                    await send(.areasResponse(
                        TaskResult { try await areaRepository.fetchAll() }
                    ))
                }

            case .areasResponse(.success(let areas)):
                state.areas = IdentifiedArray(uniqueElements: areas)
                state.isLoading = false
                return .none

            case .areasResponse(.failure):
                state.isLoading = false
                return .none

            case .areaTapped(let id):
                guard let area = state.areas[id: id] else { return .none }
                state.areaDetail = AreaDetailFeature.State(area: area, goals: [])
                return .run { [area] send in
                    // Fetch goals for this area
                    let goals = try await goalRepository.fetchGoals(for: area.id)
                    await send(.areaDetail(.presented(.goalsLoaded(goals))))
                }

            case .addAreaTapped:
                state.areaEditor = AreaEditorFeature.State(mode: .create)
                return .none

            case .areaEditor(.presented(.delegate(.areaCreated(let area)))):
                state.areaEditor = nil
                state.areas.append(area)
                return .none

            case .areaEditor(.presented(.delegate(.areaUpdated(let area)))):
                state.areaEditor = nil
                state.areas[id: area.id] = area
                return .none

            case .areaEditor:
                return .none

            case .areaDetail(.presented(.delegate(.areaUpdated(let area)))):
                state.areas[id: area.id] = area
                if let detail = state.areaDetail {
                    state.areaDetail = AreaDetailFeature.State(area: area, goals: detail.goals.elements)
                }
                return .none

            case .areaDetail(.presented(.delegate(.areaDeleted(let id)))):
                state.areaDetail = nil
                state.areas.remove(id: id)
                return .none

            case .areaDetail:
                return .none

            case .areaCreated(let area):
                state.areas.append(area)
                return .none

            case .areaUpdated(let area):
                state.areas[id: area.id] = area
                return .none

            case .areaDeleted(let id):
                state.areas.remove(id: id)
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
        var isSaving = false

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
        case saveResponse(TaskResult<Area>)
        case cancelTapped
        case delegate(Delegate)

        enum Delegate: Sendable {
            case areaCreated(Area)
            case areaUpdated(Area)
        }
    }

    @Dependency(\.areaRepository) var areaRepository
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .colorSelected(let index):
                state.selectedColorIndex = index
                return .none

            case .saveTapped:
                guard !state.name.isEmpty else { return .none }

                state.isSaving = true
                let colorHex = Theme.Colors.areaColors[state.selectedColorIndex].description

                switch state.mode {
                case .create:
                    let area = Area(
                        name: state.name,
                        emoji: state.selectedEmoji,
                        colorHex: colorHex,
                        status: .active
                    )
                    return .run { send in
                        await send(.saveResponse(
                            TaskResult { try await areaRepository.create(area) }
                        ))
                    }

                case .edit(let existingArea):
                    var updatedArea = existingArea
                    updatedArea.name = state.name
                    updatedArea.emoji = state.selectedEmoji
                    updatedArea.colorHex = colorHex

                    return .run { send in
                        await send(.saveResponse(
                            TaskResult {
                                try await areaRepository.update(updatedArea)
                                return updatedArea
                            }
                        ))
                    }
                }

            case .saveResponse(.success(let area)):
                state.isSaving = false
                switch state.mode {
                case .create:
                    return .run { send in
                        await send(.delegate(.areaCreated(area)))
                        await dismiss()
                    }
                case .edit:
                    return .run { send in
                        await send(.delegate(.areaUpdated(area)))
                        await dismiss()
                    }
                }

            case .saveResponse(.failure):
                state.isSaving = false
                return .none

            case .cancelTapped:
                return .run { _ in
                    await dismiss()
                }

            case .delegate:
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
        var isLoading = false
        @Presents var deleteConfirmation: AlertState<Action.Alert>?
        @Presents var areaEditor: AreaEditorFeature.State?
    }

    enum Action: Sendable {
        case goalsLoaded([Goal])
        case editTapped
        case togglePauseTapped
        case toggleResponse(TaskResult<Area>)
        case archiveTapped
        case archiveResponse(TaskResult<Area>)
        case deleteTapped
        case deleteConfirmation(PresentationAction<Alert>)
        case deleteResponse(TaskResult<Void>)
        case areaEditor(PresentationAction<AreaEditorFeature.Action>)
        case delegate(Delegate)

        enum Alert: Sendable {
            case confirmDelete
        }

        enum Delegate: Sendable {
            case areaUpdated(Area)
            case areaDeleted(UUID)
        }
    }

    @Dependency(\.areaRepository) var areaRepository
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .goalsLoaded(let goals):
                state.goals = IdentifiedArray(uniqueElements: goals)
                return .none

            case .editTapped:
                state.areaEditor = AreaEditorFeature.State(mode: .edit(state.area))
                return .none

            case .areaEditor(.presented(.delegate(.areaUpdated(let area)))):
                state.areaEditor = nil
                state.area = area
                return .send(.delegate(.areaUpdated(area)))

            case .areaEditor:
                return .none

            case .togglePauseTapped:
                var updatedArea = state.area
                updatedArea.status = state.area.status == .active ? .paused : .active

                return .run { send in
                    await send(.toggleResponse(
                        TaskResult {
                            try await areaRepository.update(updatedArea)
                            return updatedArea
                        }
                    ))
                }

            case .toggleResponse(.success(let area)):
                state.area = area
                return .send(.delegate(.areaUpdated(area)))

            case .toggleResponse(.failure):
                return .none

            case .archiveTapped:
                var updatedArea = state.area
                updatedArea.status = .archived

                return .run { send in
                    await send(.archiveResponse(
                        TaskResult {
                            try await areaRepository.update(updatedArea)
                            return updatedArea
                        }
                    ))
                }

            case .archiveResponse(.success(let area)):
                state.area = area
                return .run { send in
                    await send(.delegate(.areaUpdated(area)))
                    await dismiss()
                }

            case .archiveResponse(.failure):
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

            case .deleteConfirmation(.presented(.confirmDelete)):
                state.deleteConfirmation = nil
                let areaId = state.area.id

                return .run { send in
                    await send(.deleteResponse(
                        TaskResult { try await areaRepository.delete(id: areaId) }
                    ))
                }

            case .deleteConfirmation:
                return .none

            case .deleteResponse(.success):
                return .run { [areaId = state.area.id] send in
                    await send(.delegate(.areaDeleted(areaId)))
                    await dismiss()
                }

            case .deleteResponse(.failure):
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$deleteConfirmation, action: \.deleteConfirmation)
        .ifLet(\.$areaEditor, action: \.areaEditor) {
            AreaEditorFeature()
        }
    }
}

/// MARK: - Preview

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
