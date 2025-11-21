//
// OccurrenceDetailView.swift
// HabitTracker
//

import SwiftUI
import ComposableArchitecture

/// Placeholder view for OccurrenceDetailFeature
/// TODO: Implement full detail view in BUG-004
public struct OccurrenceDetailView: View {
    @Bindable var store: StoreOf<OccurrenceDetailFeature>

    public init(store: StoreOf<OccurrenceDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Occurrence Detail")
                    .font(.headline)

                Text("Occurrence ID: \(store.occurrence.id.uuidString)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("Full implementation coming in BUG-004")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.send(.dismiss)
                    }
                }
            }
        }
    }
}
