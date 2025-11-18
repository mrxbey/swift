//
// HabitTrackerApp.swift
// HabitTracker
//

import SwiftUI
import ComposableArchitecture

@main
struct HabitTrackerApp: App {
    @State private var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}

// MARK: - AppFeature

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .today
        var today = TodayFeature.State()
        var areas = AreasFeature.State()
        var insights = InsightsFeature.State()
        var programs = ProgramsFeature.State()
        var settings = SettingsFeature.State()
    }

    enum Action: Sendable {
        case tabSelected(Tab)
        case today(TodayFeature.Action)
        case areas(AreasFeature.Action)
        case insights(InsightsFeature.Action)
        case programs(ProgramsFeature.Action)
        case settings(SettingsFeature.Action)
    }

    enum Tab: Hashable, CaseIterable {
        case today, areas, insights, programs, settings

        var title: String {
            switch self {
            case .today: return "Today"
            case .areas: return "Areas"
            case .insights: return "Insights"
            case .programs: return "Inspire"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .today: return Theme.Icons.today
            case .areas: return Theme.Icons.areas
            case .insights: return Theme.Icons.insights
            case .programs: return Theme.Icons.programs
            case .settings: return Theme.Icons.settings
            }
        }
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.today, action: \.today) {
            TodayFeature()
        }
        Scope(state: \.areas, action: \.areas) {
            AreasFeature()
        }
        Scope(state: \.insights, action: \.insights) {
            InsightsFeature()
        }
        Scope(state: \.programs, action: \.programs) {
            ProgramsFeature()
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }

        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case .today, .areas, .insights, .programs, .settings:
                return .none
            }
        }
    }
}

// MARK: - AppView

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            ForEach(AppFeature.Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .tint(Theme.Colors.primary)
    }

    @ViewBuilder
    private func tabContent(for tab: AppFeature.Tab) -> some View {
        switch tab {
        case .today:
            TodayView(store: store.scope(state: \.today, action: \.today))

        case .areas:
            AreasView(store: store.scope(state: \.areas, action: \.areas))

        case .insights:
            InsightsView(store: store.scope(state: \.insights, action: \.insights))

        case .programs:
            ProgramsView(store: store.scope(state: \.programs, action: \.programs))

        case .settings:
            SettingsView(store: store.scope(state: \.settings, action: \.settings))
        }
    }
}

// MARK: - Placeholder Features

@Reducer
struct AreasFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action: Sendable {}
    var body: some ReducerOf<Self> {
        Reduce { state, action in .none }
    }
}

@Reducer
struct InsightsFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action: Sendable {}
    var body: some ReducerOf<Self> {
        Reduce { state, action in .none }
    }
}

@Reducer
struct ProgramsFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action: Sendable {}
    var body: some ReducerOf<Self> {
        Reduce { state, action in .none }
    }
}

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action: Sendable {}
    var body: some ReducerOf<Self> {
        Reduce { state, action in .none }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
#endif
