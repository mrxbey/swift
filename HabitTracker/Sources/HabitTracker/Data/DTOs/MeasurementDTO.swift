import Foundation

/// Data Transfer Object for Measurement entity
///
/// Maps between the PostgreSQL `measurements` table (snake_case) and the Swift `Measurement` domain model (camelCase).
public struct MeasurementDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let goalId: UUID
    public let occurrenceId: UUID?
    public let value: Double
    public let unit: String
    public let recordedAt: Date
    public let createdAt: Date

    /// MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case goalId = "goal_id"
        case occurrenceId = "occurrence_id"
        case value
        case unit
        case recordedAt = "occurred_at"
        case createdAt = "created_at"
    }

    /// MARK: - Initialization

    /// Creates a DTO from a domain model
    ///
    /// - Parameter measurement: The domain Measurement model
    public init(from measurement: Measurement) {
        self.id = measurement.id
        self.userId = measurement.userId
        self.goalId = measurement.goalId
        self.occurrenceId = measurement.occurrenceId
        self.value = measurement.value

        // Convert Swift unit to database unit (handle 'minutes' → 'min' legacy mapping)
        let dbUnit: String
        switch measurement.unit {
        case .minutes:
            dbUnit = "min"  // Database uses 'min' for backwards compatibility
        default:
            dbUnit = measurement.unit.rawValue
        }
        self.unit = dbUnit

        self.recordedAt = measurement.recordedAt
        self.createdAt = measurement.createdAt
    }

    /// MARK: - Conversion

    /// Converts the DTO to a domain model
    public var toDomain: Measurement {
        // Convert database unit to Swift unit (handle 'min' → 'minutes' legacy mapping)
        let swiftUnit: UnitKind
        if unit == "min" {
            swiftUnit = .minutes  // Database 'min' maps to Swift .minutes
        } else {
            swiftUnit = UnitKind(rawValue: unit) ?? .count
        }

        return Measurement(
            id: id,
            userId: userId,
            goalId: goalId,
            occurrenceId: occurrenceId,
            value: value,
            unit: swiftUnit,
            recordedAt: recordedAt,
            createdAt: createdAt
        )
    }
}

/// MARK: - GoalMeasureTargetDTO

/// Data Transfer Object for GoalMeasureTarget entity
///
/// Maps between the PostgreSQL `goal_measure_targets` table and the Swift domain model.
/// Used for versioned targets (e.g., changing water intake goals over time).
public struct GoalMeasureTargetDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let goalId: UUID
    public let targetValue: Double
    public let unit: String
    public let effectiveFrom: Date
    public let effectiveTo: Date?
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case targetValue = "target_value"
        case unit
        case effectiveFrom = "effective_from"
        case effectiveTo = "effective_to"
        case createdAt = "created_at"
    }

    public init(from target: GoalMeasureTarget) {
        self.id = target.id
        self.goalId = target.goalId
        self.targetValue = target.targetValue

        // Convert Swift unit to database unit (handle 'minutes' → 'min' legacy mapping)
        let dbUnit: String
        switch target.unit {
        case .minutes:
            dbUnit = "min"  // Database uses 'min' for backwards compatibility
        default:
            dbUnit = target.unit.rawValue
        }
        self.unit = dbUnit

        self.effectiveFrom = target.effectiveFrom
        self.effectiveTo = target.effectiveTo
        self.createdAt = target.createdAt
    }

    public var toDomain: GoalMeasureTarget {
        // Convert database unit to Swift unit (handle 'min' → 'minutes' legacy mapping)
        let swiftUnit: UnitKind
        if unit == "min" {
            swiftUnit = .minutes  // Database 'min' maps to Swift .minutes
        } else {
            swiftUnit = UnitKind(rawValue: unit) ?? .count
        }

        return GoalMeasureTarget(
            id: id,
            goalId: goalId,
            targetValue: targetValue,
            unit: swiftUnit,
            effectiveFrom: effectiveFrom,
            effectiveTo: effectiveTo,
            createdAt: createdAt
        )
    }
}
