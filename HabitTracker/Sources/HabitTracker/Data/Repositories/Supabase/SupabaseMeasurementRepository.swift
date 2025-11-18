import Foundation
import Supabase

/// Supabase implementation of MeasurementRepository with offline-first caching
///
/// Thread-safe actor that handles all measurement-related database operations.
/// Implements cache-first reads and write-through pattern for offline support.
public actor SupabaseMeasurementRepository: MeasurementRepository {
    private let client: SupabaseClient
    private let cacheService: CacheService
    private let networkMonitor: NetworkMonitor
    private let syncEngine: SyncEngine

    // MARK: - Initialization

    public init(
        client: SupabaseClient,
        cacheService: CacheService,
        networkMonitor: NetworkMonitor,
        syncEngine: SyncEngine
    ) {
        self.client = client
        self.cacheService = cacheService
        self.networkMonitor = networkMonitor
        self.syncEngine = syncEngine
    }

    public init() async {
        self.client = await SupabaseService.shared.getClient()
        let sharedCache = try! CacheService()
        self.cacheService = sharedCache
        self.networkMonitor = NetworkMonitor()
        self.syncEngine = SyncEngine(
            cacheService: sharedCache,
            supabaseClient: await SupabaseService.shared.getClient()
        )
    }

    // MARK: - MeasurementRepository Implementation

    public func fetchMeasurements(for goalId: UUID) async throws -> [Measurement] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Cache-first: Try to get from cache
        let cached = try await MainActor.run {
            try cacheService.fetchMeasurements(goalId: goalId)
        }

        if !cached.isEmpty {
            // Trigger background sync
            Task {
                if await networkMonitor.isConnected() {
                    try? await syncEngine.performFullSync(userId: userId)
                }
            }
            return cached
        }

        // Cache miss: Fetch from Supabase
        do {
            let response: [MeasurementDTO] = try await client
                .from("measurements")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("goal_id", value: goalId.uuidString)
                .order("recorded_at", ascending: false)
                .execute()
                .value

            let measurements = response.map(\.toDomain)

            // Cache the results
            try await MainActor.run {
                for measurement in measurements {
                    try cacheService.saveMeasurement(measurement, syncState: .synced)
                }
            }

            return measurements
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchMeasurements(for goalId: UUID, from: Date, to: Date) async throws -> [Measurement] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // For range queries, fetch from Supabase and refresh cache
        do {
            let response: [MeasurementDTO] = try await client
                .from("measurements")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("goal_id", value: goalId.uuidString)
                .gte("recorded_at", value: from.iso8601String)
                .lte("recorded_at", value: to.iso8601String)
                .order("recorded_at", ascending: true)
                .execute()
                .value

            let measurements = response.map(\.toDomain)

            // Cache the results
            try await MainActor.run {
                for measurement in measurements {
                    try cacheService.saveMeasurement(measurement, syncState: .synced)
                }
            }

            return measurements
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetch(_ id: UUID) async throws -> Measurement {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Cache-first: Try to get from cache
        let cached = try await MainActor.run {
            try cacheService.fetchMeasurements(goalId: id)  // Note: This queries by goalId, may need adjustment
        }

        // For individual fetch, always go to Supabase since cache doesn't support ID lookups yet
        do {
            let response: MeasurementDTO = try await client
                .from("measurements")
                .select()
                .eq("id", value: id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            let measurement = response.toDomain

            // Cache the result
            try await MainActor.run {
                try cacheService.saveMeasurement(measurement, syncState: .synced)
            }

            return measurement
        } catch let error as PostgrestError {
            if error.statusCode == 404 {
                throw SupabaseError.notFound
            }
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func create(_ measurement: Measurement) async throws -> Measurement {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        var measurementToCreate = measurement
        if measurementToCreate.userId != userId {
            measurementToCreate = Measurement(
                id: measurement.id,
                userId: userId,
                goalId: measurement.goalId,
                occurrenceId: measurement.occurrenceId,
                value: measurement.value,
                unit: measurement.unit,
                recordedAt: measurement.recordedAt,
                createdAt: measurement.createdAt,
                updatedAt: Date()
            )
        }

        // Save to cache with pending state
        try await MainActor.run {
            try cacheService.saveMeasurement(measurementToCreate, syncState: .pending)
        }

        // Try to sync to Supabase if online
        if await networkMonitor.isConnected() {
            do {
                let dto = MeasurementDTO(from: measurementToCreate)

                let response: MeasurementDTO = try await client
                    .from("measurements")
                    .insert(dto)
                    .select()
                    .single()
                    .execute()
                    .value

                let created = response.toDomain

                // Update cache with synced state
                try await MainActor.run {
                    try cacheService.saveMeasurement(created, syncState: .synced)
                }

                return created
            } catch let error as PostgrestError {
                throw SupabaseError.from(error)
            } catch {
                throw SupabaseError.from(error)
            }
        }

        // Offline: Return cached version
        return measurementToCreate
    }

    public func update(_ measurement: Measurement) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        var updatedMeasurement = measurement
        updatedMeasurement.updatedAt = Date()

        // Save to cache with pending state
        try await MainActor.run {
            try cacheService.saveMeasurement(updatedMeasurement, syncState: .pending)
        }

        // Try to sync to Supabase if online
        if await networkMonitor.isConnected() {
            do {
                let dto = MeasurementDTO(from: updatedMeasurement)

                try await client
                    .from("measurements")
                    .update(dto)
                    .eq("id", value: measurement.id.uuidString)
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                // Update cache with synced state
                try await MainActor.run {
                    try cacheService.saveMeasurement(updatedMeasurement, syncState: .synced)
                }
            } catch let error as PostgrestError {
                throw SupabaseError.from(error)
            } catch {
                throw SupabaseError.from(error)
            }
        }
        // Offline: Keep pending state
    }

    public func delete(id: UUID) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Delete from cache
        try await MainActor.run {
            try cacheService.deleteMeasurement(id: id)
        }

        // Try to sync deletion to Supabase if online
        if await networkMonitor.isConnected() {
            do {
                try await client
                    .from("measurements")
                    .delete()
                    .eq("id", value: id.uuidString)
                    .eq("user_id", value: userId.uuidString)
                    .execute()
            } catch let error as PostgrestError {
                throw SupabaseError.from(error)
            } catch {
                throw SupabaseError.from(error)
            }
        }
        // Offline: Deletion will be synced later
    }

    public func addMeasurement(
        for goalId: UUID,
        value: Double,
        unit: UnitKind,
        occurrenceId: UUID?
    ) async throws -> Measurement {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            var params: [String: Any] = [
                "p_goal": goalId.uuidString,
                "p_value": value,
                "p_unit": unit.rawValue,
                "p_user": userId.uuidString
            ]

            if let occurrenceId = occurrenceId {
                params["p_occ"] = occurrenceId.uuidString
            }

            // Use RPC for atomic operation
            let response: MeasurementDTO = try await client
                .rpc("add_measurement", params: params)
                .single()
                .execute()
                .value

            return response.toDomain
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchWaterProgress(
        for goalId: UUID,
        from: Date,
        to: Date
    ) async throws -> [WaterDataPoint] {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            struct WaterRow: Codable {
                let day: String
                let consumed: Double
                let target: Double
                let unit: String
            }

            let response: [WaterRow] = try await client
                .rpc("get_water_progress", params: [
                    "p_goal": goalId.uuidString,
                    "p_from": from.toDateOnlyString(),
                    "p_to": to.toDateOnlyString(),
                    "p_user": userId.uuidString
                ])
                .execute()
                .value

            return response.compactMap { row in
                guard let date = row.day.toDate() else { return nil }
                return WaterDataPoint(
                    date: date,
                    consumed: row.consumed,
                    target: row.target,
                    unit: UnitKind(rawValue: row.unit) ?? .ml
                )
            }
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func setMeasureTarget(
        for goalId: UUID,
        targetValue: Double,
        unit: UnitKind,
        effectiveFrom: Date
    ) async throws -> GoalMeasureTarget {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            // Use RPC for proper target management
            let response: GoalMeasureTargetDTO = try await client
                .rpc("set_measure_target", params: [
                    "p_goal": goalId.uuidString,
                    "p_target": targetValue,
                    "p_unit": unit.rawValue,
                    "p_from": effectiveFrom.toDateOnlyString(),
                    "p_user": userId.uuidString
                ])
                .single()
                .execute()
                .value

            return response.toDomain
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }
}

// MARK: - Date Extensions

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }

    func toDateOnlyString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: self)
    }
}

private extension String {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: self)
    }
}
