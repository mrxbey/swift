import Foundation
import Supabase

/// Coordinates offline sync between local cache and Supabase
///
/// Manages:
/// - Background sync on network changes
/// - Periodic sync intervals
/// - Manual sync triggers
/// - Sync state tracking
@MainActor
public final class SyncCoordinator: ObservableObject {
    @Published public private(set) var isSyncing: Bool = false
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var syncError: String?
    @Published public private(set) var networkStatus: NetworkStatus = .unknown

    private let cacheService: CacheService
    private let syncEngine: SyncEngine
    private let networkMonitor: NetworkMonitor

    private var syncTask: Task<Void, Never>?

    // Configuration
    private let autoSyncInterval: TimeInterval = 300 // 5 minutes
    private var lastAutoSyncDate: Date?

    /// MARK: - Initialization

    public init(
        cacheService: CacheService,
        syncEngine: SyncEngine,
        networkMonitor: NetworkMonitor
    ) {
        self.cacheService = cacheService
        self.syncEngine = syncEngine
        self.networkMonitor = networkMonitor

        setupNetworkMonitoring()
    }

    /// MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        Task {
            await networkMonitor.startMonitoring()

            // Register callback
            await networkMonitor.onStatusChange { [weak self] status in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }

                    self.networkStatus = status

                    // Trigger sync when coming back online
                    if status.isConnected {
                        await self.syncIfNeeded()
                    }
                }
            }

            // Get initial status
            self.networkStatus = await networkMonitor.getCurrentStatus()
        }
    }

    /// MARK: - Sync Operations

    /// Triggers a manual sync
    ///
    /// - Parameter userId: The user ID to sync for
    public func sync(userId: UUID) async {
        guard !isSyncing else { return }
        guard networkStatus.isConnected else {
            syncError = "No network connection. Changes will sync when online."
            return
        }

        isSyncing = true
        syncError = nil

        do {
            try await syncEngine.performFullSync(userId: userId)
            lastSyncDate = Date()
            lastAutoSyncDate = Date()
            syncError = nil
        } catch {
            syncError = "Sync failed: \(error.localizedDescription)"
            Logger.sync.error("Sync failed", error: error)
        }

        isSyncing = false
    }

    /// Syncs if enough time has passed since last sync
    ///
    /// - Parameter userId: The user ID to sync for
    public func syncIfNeeded(userId: UUID? = nil) async {
        guard let userId = userId else { return }
        guard !isSyncing else { return }
        guard networkStatus.isConnected else { return }

        // Check if enough time has passed
        if let lastSync = lastAutoSyncDate {
            let timeSinceLastSync = Date().timeIntervalSince(lastSync)
            if timeSinceLastSync < autoSyncInterval {
                return // Too soon
            }
        }

        await sync(userId: userId)
    }

    /// Starts background sync with periodic intervals
    ///
    /// - Parameter userId: The user ID to sync for
    public func startBackgroundSync(userId: UUID) {
        // Cancel existing task
        syncTask?.cancel()

        syncTask = Task {
            while !Task.isCancelled {
                // Wait for interval
                try? await Task.sleep(for: .seconds(autoSyncInterval))

                // Check if still connected
                guard await networkMonitor.isConnected() else { continue }

                // Perform sync
                await sync(userId: userId)
            }
        }
    }

    /// Stops background sync
    public func stopBackgroundSync() {
        syncTask?.cancel()
        syncTask = nil
    }

    /// MARK: - Cache Management

    /// Clears local cache
    ///
    /// WARNING: This will delete all offline data!
    public func clearCache() throws {
        try cacheService.clearAll()
        lastSyncDate = nil
        lastAutoSyncDate = nil
        syncEngine.resetSyncState()
    }

    /// Clears old cached data to free up space
    public func clearOldCache() throws {
        try syncEngine.clearOldCachedData()
    }

    /// MARK: - Status

    /// Checks if offline changes are pending
    public func hasPendingChanges() async throws -> Bool {
        let areas = try cacheService.fetchPendingAreas()
        let goals = try cacheService.fetchPendingGoals()
        let occurrences = try cacheService.fetchPendingOccurrences()
        let measurements = try cacheService.fetchPendingMeasurements()

        return !areas.isEmpty || !goals.isEmpty || !occurrences.isEmpty || !measurements.isEmpty
    }

    /// Returns count of pending changes
    public func pendingChangesCount() async throws -> Int {
        let areas = try cacheService.fetchPendingAreas()
        let goals = try cacheService.fetchPendingGoals()
        let occurrences = try cacheService.fetchPendingOccurrences()
        let measurements = try cacheService.fetchPendingMeasurements()

        return areas.count + goals.count + occurrences.count + measurements.count
    }

    /// MARK: - Cleanup

    deinit {
        Task {
            await networkMonitor.stopMonitoring()
        }
        syncTask?.cancel()
    }
}
