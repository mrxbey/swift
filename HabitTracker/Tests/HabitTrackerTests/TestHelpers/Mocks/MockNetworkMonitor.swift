import Foundation
@testable import HabitTracker

/// Mock NetworkMonitor for testing
actor MockNetworkMonitor: Sendable {
    var isConnectedValue: Bool = true
    var currentStatusValue: NetworkStatus = .connected(.wifi)
    private var statusChangeHandler: (@Sendable (NetworkStatus) -> Void)?

    func startMonitoring() {}

    func stopMonitoring() {}

    func isConnected() -> Bool {
        isConnectedValue
    }

    func getCurrentStatus() -> NetworkStatus {
        currentStatusValue
    }

    func onStatusChange(_ handler: @escaping @Sendable (NetworkStatus) -> Void) {
        self.statusChangeHandler = handler
    }

    // Test helper to simulate status changes
    func simulateStatusChange(_ status: NetworkStatus) {
        currentStatusValue = status
        isConnectedValue = status.isConnected
        statusChangeHandler?(status)
    }

    // Test helpers for repository tests
    func setConnected(_ connected: Bool) {
        isConnectedValue = connected
        currentStatusValue = connected ? .connected(.wifi) : .disconnected
    }

    func reset() {
        isConnectedValue = true
        currentStatusValue = .connected(.wifi)
        statusChangeHandler = nil
    }
}
