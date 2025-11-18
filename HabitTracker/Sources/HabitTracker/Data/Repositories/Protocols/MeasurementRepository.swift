import Foundation

/// Repository protocol for managing Measurement entities
///
/// Handles recording and querying measurements for tracked goals (water, weight, etc.).
public protocol MeasurementRepository: Sendable {
    /// Fetches measurements for a specific goal
    ///
    /// - Parameter goalId: The UUID of the goal
    /// - Returns: Array of measurements sorted by recorded date
    /// - Throws: SupabaseError if the operation fails
    func fetchMeasurements(for goalId: UUID) async throws -> [Measurement]

    /// Fetches measurements for a goal within a date range
    ///
    /// - Parameters:
    ///   - goalId: The UUID of the goal
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    /// - Returns: Array of measurements in the date range
    /// - Throws: SupabaseError if the operation fails
    func fetchMeasurements(for goalId: UUID, from: Date, to: Date) async throws -> [Measurement]

    /// Fetches a specific measurement by ID
    ///
    /// - Parameter id: The UUID of the measurement to fetch
    /// - Returns: The measurement if found
    /// - Throws: SupabaseError.notFound if measurement doesn't exist
    func fetch(_ id: UUID) async throws -> Measurement

    /// Creates a new measurement
    ///
    /// - Parameter measurement: The measurement to create
    /// - Returns: The created measurement with server-generated fields
    /// - Throws: SupabaseError if the operation fails
    func create(_ measurement: Measurement) async throws -> Measurement

    /// Updates an existing measurement
    ///
    /// - Parameter measurement: The measurement to update
    /// - Throws: SupabaseError if the operation fails
    func update(_ measurement: Measurement) async throws

    /// Deletes a measurement by ID
    ///
    /// - Parameter id: The UUID of the measurement to delete
    /// - Throws: SupabaseError if the operation fails
    func delete(id: UUID) async throws

    /// Adds a measurement using the RPC
    ///
    /// Simplified method that uses the add_measurement RPC for atomic operation
    /// with automatic occurrence updates.
    ///
    /// - Parameters:
    ///   - goalId: The UUID of the goal
    ///   - value: The measurement value
    ///   - unit: The unit of measurement
    ///   - occurrenceId: Optional occurrence to link to
    /// - Returns: The created measurement
    /// - Throws: SupabaseError if the operation fails
    func addMeasurement(
        for goalId: UUID,
        value: Double,
        unit: UnitKind,
        occurrenceId: UUID?
    ) async throws -> Measurement

    /// Fetches water progress data for charting
    ///
    /// Returns daily water consumption vs target for the specified date range.
    /// Uses the get_water_progress RPC.
    ///
    /// - Parameters:
    ///   - goalId: The UUID of the water goal
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Array of daily water data points
    /// - Throws: SupabaseError if the operation fails
    func fetchWaterProgress(
        for goalId: UUID,
        from: Date,
        to: Date
    ) async throws -> [WaterDataPoint]

    /// Fetches or creates measure target for a goal
    ///
    /// - Parameters:
    ///   - goalId: The UUID of the goal
    ///   - targetValue: The target value
    ///   - unit: The unit of measurement
    ///   - effectiveFrom: When this target becomes effective
    /// - Returns: The measure target
    /// - Throws: SupabaseError if the operation fails
    func setMeasureTarget(
        for goalId: UUID,
        targetValue: Double,
        unit: UnitKind,
        effectiveFrom: Date
    ) async throws -> GoalMeasureTarget
}

// MARK: - WaterDataPoint

/// A single data point for water progress charting
public struct WaterDataPoint: Codable, Sendable, Equatable {
    public let date: Date
    public let consumed: Double
    public let target: Double
    public let unit: UnitKind

    public init(date: Date, consumed: Double, target: Double, unit: UnitKind) {
        self.date = date
        self.consumed = consumed
        self.target = target
        self.unit = unit
    }

    /// Percentage of target consumed (0.0 to 1.0+)
    public var progress: Double {
        guard target > 0 else { return 0 }
        return consumed / target
    }

    /// Whether the target was met
    public var targetMet: Bool {
        consumed >= target
    }
}
