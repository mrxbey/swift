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
    public let updatedAt: Date

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case goalId = "goal_id"
        case occurrenceId = "occurrence_id"
        case value
        case unit
        case recordedAt = "recorded_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Initialization

    /// Creates a DTO from a domain model
    ///
    /// - Parameter measurement: The domain Measurement model
    public init(from measurement: Measurement) {
        self.id = measurement.id
        self.userId = measurement.userId
        self.goalId = measurement.goalId
        self.occurrenceId = measurement.occurrenceId
        self.value = measurement.value
        self.unit = measurement.unit.rawValue
        self.recordedAt = measurement.recordedAt
        self.createdAt = measurement.createdAt
        self.updatedAt = measurement.updatedAt
    }

    // MARK: - Conversion

    /// Converts the DTO to a domain model
    public var toDomain: Measurement {
        Measurement(
            id: id,
            userId: userId,
            goalId: goalId,
            occurrenceId: occurrenceId,
            value: value,
            unit: UnitKind(rawValue: unit) ?? .count,
            recordedAt: recordedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - GoalMeasureTargetDTO

/// Data Transfer Object for GoalMeasureTarget entity
///
/// Maps between the PostgreSQL `goal_measure_targets` table and the Swift domain model.
/// Used for versioned targets (e.g., changing water intake goals over time).
public struct GoalMeasureTargetDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let goalId: UUID
    public let targetValue: Double
    public let unit: String
    public let effectiveFrom: Date
    public let effectiveTo: Date?
    public let createdAt: Date
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case goalId = "goal_id"
        case targetValue = "target_value"
        case unit
        case effectiveFrom = "effective_from"
        case effectiveTo = "effective_to"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from target: GoalMeasureTarget) {
        self.id = target.id
        self.userId = target.userId
        self.goalId = target.goalId
        self.targetValue = target.targetValue
        self.unit = target.unit.rawValue
        self.effectiveFrom = target.effectiveFrom
        self.effectiveTo = target.effectiveTo
        self.createdAt = target.createdAt
        self.updatedAt = target.updatedAt
    }

    public var toDomain: GoalMeasureTarget {
        GoalMeasureTarget(
            id: id,
            userId: userId,
            goalId: goalId,
            targetValue: targetValue,
            unit: UnitKind(rawValue: unit) ?? .count,
            effectiveFrom: effectiveFrom,
            effectiveTo: effectiveTo,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
