//
// ProgramsView.swift
// HabitTracker
//

import SwiftUI
import ComposableArchitecture

struct ProgramsView: View {
    @Bindable var store: StoreOf<ProgramsFeature>

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.large) {
                    // Categories
                    categoriesSection

                    // Programs
                    if store.filteredPrograms.isEmpty {
                        emptyState
                    } else {
                        programsGrid
                    }
                }
                .padding()
            }
            .background(Theme.Colors.background)
            .navigationTitle("Inspire")
            .searchable(text: $store.searchText, prompt: "Search programs")
            .sheet(
                item: $store.scope(state: \.programDetail, action: \.programDetail)
            ) { store in
                ProgramDetailView(store: store)
            }
            .task {
                store.send(.task)
            }
        }
    }

    /// MARK: - Categories Section

    private var categoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.small) {
                CategoryPill(
                    title: "All",
                    isSelected: store.selectedCategory == nil
                ) {
                    store.send(.categorySelected(nil))
                }

                ForEach(store.categories, id: \.self) { category in
                    CategoryPill(
                        title: category,
                        isSelected: store.selectedCategory == category
                    ) {
                        store.send(.categorySelected(category))
                    }
                }
            }
        }
    }

    /// MARK: - Programs Grid

    private var programsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: Theme.Spacing.medium
        ) {
            ForEach(store.filteredPrograms) { program in
                ProgramCard(program: program) {
                    store.send(.programTapped(program.id))
                }
            }
        }
    }

    /// MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: Theme.Icons.programs)
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondaryText)

            Text("No programs found")
                .font(Theme.Typography.title3)

            Text("Try adjusting your search or category filter")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Theme.Spacing.xxxLarge)
    }
}

/// MARK: - Supporting Views

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.callout)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, Theme.Spacing.xSmall)
                .background(
                    isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground
                )
                .foregroundColor(
                    isSelected ? .white : Theme.Colors.text
                )
                .cornerRadius(Theme.CornerRadius.large)
        }
    }
}

struct ProgramCard: View {
    let program: ProgramViewModel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                // Thumbnail
                AsyncImage(url: program.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.secondaryBackground)
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(Theme.CornerRadius.medium)

                // Title
                Text(program.title)
                    .font(Theme.Typography.bodyBold)
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)

                // Stats
                HStack(spacing: Theme.Spacing.xSmall) {
                    if let rating = program.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(Theme.Typography.caption2)
                            Text(String(format: "%.1f", rating))
                                .font(Theme.Typography.caption)
                        }
                        .foregroundColor(.yellow)
                    }

                    Text("•")
                        .foregroundColor(Theme.Colors.tertiaryText)

                    Text("\(program.addedCount) added")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// MARK: - Program Detail View

struct ProgramDetailView: View {
    @Bindable var store: StoreOf<ProgramDetailFeature>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    // Hero image
                    if let url = store.program.heroURL {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Theme.Colors.secondaryBackground)
                        }
                        .frame(height: 200)
                        .clipped()
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                        // Title & rating
                        VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
                            Text(store.program.title)
                                .font(Theme.Typography.title1)

                            if let rating = store.program.rating {
                                HStack {
                                    ForEach(0..<5) { index in
                                        Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                    }

                                    Text(String(format: "%.1f", rating))
                                        .font(Theme.Typography.callout)
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                            }
                        }

                        // Summary
                        if let summary = store.program.summary {
                            Text(summary)
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }

                        // Items
                        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                            Text("What's Included")
                                .font(Theme.Typography.title3)

                            ForEach(store.items) { item in
                                ProgramItemRow(
                                    item: item,
                                    isSelected: store.selectedItems.contains(item.id)
                                ) {
                                    store.send(.itemToggled(item.id))
                                }
                            }
                        }

                        // Add button
                        Button {
                            store.send(.addProgramTapped)
                        } label: {
                            Text("Add to My Goals")
                                .primaryButtonStyle()
                        }
                        .disabled(store.selectedItems.isEmpty)
                    }
                    .padding()
                }
            }
            .background(Theme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        store.send(.closeTapped)
                    }
                }
            }
        }
    }
}

struct ProgramItemRow: View {
    let item: ProgramItemViewModel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.separator)

                if let emoji = item.emoji {
                    Text(emoji)
                }

                Text(item.title)
                    .font(Theme.Typography.body)

                Spacer()

                Text("+\(item.defaultPoints) pts")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.accent)
            }
            .padding()
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

/// MARK: - ProgramsFeature

@Reducer
struct ProgramsFeature {
    @ObservableState
    struct State: Equatable {
        var programs: IdentifiedArrayOf<ProgramViewModel> = []
        var categories: [String] = []
        var selectedCategory: String?
        var searchText: String = ""
        var isLoading: Bool = false

        @Presents var programDetail: ProgramDetailFeature.State?

        var filteredPrograms: IdentifiedArrayOf<ProgramViewModel> {
            var filtered = programs

            // Filter by category
            if let category = selectedCategory {
                filtered = IdentifiedArray(
                    uniqueElements: filtered.filter { $0.category == category }
                )
            }

            // Filter by search
            if !searchText.isEmpty {
                filtered = IdentifiedArray(
                    uniqueElements: filtered.filter {
                        $0.title.localizedCaseInsensitiveContains(searchText) ||
                        $0.summary?.localizedCaseInsensitiveContains(searchText) == true
                    }
                )
            }

            return filtered
        }
    }

    enum Action: Sendable, BindableAction {
        case binding(BindingAction<State>)
        case task
        case programsResponse(TaskResult<[ProgramViewModel]>)
        case categorySelected(String?)
        case programTapped(UUID)
        case programDetail(PresentationAction<ProgramDetailFeature.Action>)
    }

    var body: some ReducerOf<Self> {
        BindableReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .task:
                state.isLoading = true
                return .none

            case .programsResponse(.success(let programs)):
                state.programs = IdentifiedArray(uniqueElements: programs)
                state.categories = Array(Set(programs.compactMap { $0.category })).sorted()
                state.isLoading = false
                return .none

            case .programsResponse(.failure):
                state.isLoading = false
                return .none

            case .categorySelected(let category):
                state.selectedCategory = category
                return .none

            case .programTapped(let id):
                guard let program = state.programs[id: id] else { return .none }
                state.programDetail = ProgramDetailFeature.State(program: program, items: [])
                return .none

            case .programDetail:
                return .none
            }
        }
        .ifLet(\.$programDetail, action: \.programDetail) {
            ProgramDetailFeature()
        }
    }
}

@Reducer
struct ProgramDetailFeature {
    @ObservableState
    struct State: Equatable {
        var program: ProgramViewModel
        var items: IdentifiedArrayOf<ProgramItemViewModel> = []
        var selectedItems: Set<UUID> = []

        init(program: ProgramViewModel, items: [ProgramItemViewModel]) {
            self.program = program
            self.items = IdentifiedArray(uniqueElements: items)
            self.selectedItems = Set(items.map { $0.id })
        }
    }

    enum Action: Sendable {
        case itemToggled(UUID)
        case addProgramTapped
        case closeTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .itemToggled(let id):
                if state.selectedItems.contains(id) {
                    state.selectedItems.remove(id)
                } else {
                    state.selectedItems.insert(id)
                }
                return .none

            case .addProgramTapped:
                // TODO: Implement program adoption
                return .none

            case .closeTapped:
                return .none
            }
        }
    }
}

/// MARK: - View Models

/// View-specific model for Program display in TCA
struct ProgramViewModel: Identifiable, Equatable {
    let id: UUID
    let title: String
    let summary: String?
    let category: String?
    let thumbnailURL: URL?
    let heroURL: URL?
    let rating: Double?
    let addedCount: Int

    init(
        id: UUID = UUID(),
        title: String,
        summary: String? = nil,
        category: String? = nil,
        thumbnailURL: URL? = nil,
        heroURL: URL? = nil,
        rating: Double? = nil,
        addedCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.category = category
        self.thumbnailURL = thumbnailURL
        self.heroURL = heroURL
        self.rating = rating
        self.addedCount = addedCount
    }
}

/// View-specific model for ProgramItem display in TCA
struct ProgramItemViewModel: Identifiable, Equatable {
    let id: UUID
    let title: String
    let emoji: String?
    let defaultPoints: Int

    init(
        id: UUID = UUID(),
        title: String,
        emoji: String? = nil,
        defaultPoints: Int = 5
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.defaultPoints = defaultPoints
    }
}

/// MARK: - Preview

#if DEBUG
#Preview {
    ProgramsView(
        store: Store(initialState: ProgramsFeature.State(
            programs: [
                ProgramViewModel(
                    title: "30-Day Meditation",
                    summary: "Build a consistent meditation practice",
                    category: "Mindfulness",
                    rating: 4.8,
                    addedCount: 1234
                ),
                ProgramViewModel(
                    title: "Hydration Hero",
                    summary: "Drink 8 glasses of water daily",
                    category: "Health",
                    rating: 4.6,
                    addedCount: 892
                )
            ],
            categories: ["Mindfulness", "Health", "Productivity"]
        )) {
            ProgramsFeature()
        }
    )
}
#endif
