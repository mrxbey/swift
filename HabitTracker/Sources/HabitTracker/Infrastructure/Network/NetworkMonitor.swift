import Foundation
import Network

/// Monitors network connectivity and triggers sync when online
///
/// Uses NWPathMonitor to detect network status changes.
/// Automatically triggers sync when connectivity is restored.
public actor NetworkMonitor {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.habittracker.networkmonitor")

    private var isMonitoring = false
    private var currentStatus: NetworkStatus = .unknown

    // Callbacks
    private var statusChangeHandlers: [@Sendable (NetworkStatus) -> Void] = []

    /// MARK: - Initialization

    public init() {
        self.monitor = NWPathMonitor()
    }

    /// MARK: - Monitoring

    /// Starts monitoring network status
    public func startMonitoring() {
        guard !isMonitoring else { return }

        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                await self?.handlePathUpdate(path)
            }
        }

        monitor.start(queue: queue)
        isMonitoring = true
    }

    /// Stops monitoring network status
    public func stopMonitoring() {
        guard isMonitoring else { return }

        monitor.cancel()
        isMonitoring = false
    }

    private func handlePathUpdate(_ path: NWPath) {
        let newStatus = NetworkStatus(from: path)

        // Detect status change
        let previousStatus = currentStatus
        currentStatus = newStatus

        // Notify handlers
        if previousStatus != newStatus {
            notifyStatusChange(newStatus)
        }
    }

    /// MARK: - Status

    /// Returns current network status
    public func getCurrentStatus() -> NetworkStatus {
        currentStatus
    }

    /// Checks if currently connected
    public func isConnected() -> Bool {
        currentStatus.isConnected
    }

    /// MARK: - Callbacks

    /// Registers a callback for status changes
    public func onStatusChange(_ handler: @escaping @Sendable (NetworkStatus) -> Void) {
        statusChangeHandlers.append(handler)
    }

    private func notifyStatusChange(_ status: NetworkStatus) {
        for handler in statusChangeHandlers {
            handler(status)
        }
    }

    /// MARK: - Cleanup

    deinit {
        monitor.cancel()
    }
}

/// MARK: - NetworkStatus

public enum NetworkStatus: Equatable, Sendable {
    case connected(ConnectionType)
    case disconnected
    case unknown

    public var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }

    public var connectionType: ConnectionType? {
        if case let .connected(type) = self {
            return type
        }
        return nil
    }

    init(from path: NWPath) {
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                self = .connected(.wifi)
            } else if path.usesInterfaceType(.cellular) {
                self = .connected(.cellular)
            } else if path.usesInterfaceType(.wiredEthernet) {
                self = .connected(.ethernet)
            } else {
                self = .connected(.other)
            }
        } else {
            self = .disconnected
        }
    }
}

/// MARK: - ConnectionType

public enum ConnectionType: Equatable, Sendable {
    case wifi
    case cellular
    case ethernet
    case other

    public var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .other: return "Network"
        }
    }

    public var isExpensive: Bool {
        self == .cellular
    }
}
