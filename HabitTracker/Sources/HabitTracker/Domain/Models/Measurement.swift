import Foundation

/// A measured value for a goal (e.g., water intake, weight, etc.)
///
/// Measurements are recorded throughout the day and aggregated for progress tracking.
/// Each measurement is linked to a goal and optionally to a specific occurrence.
@Observable
public final class Measurement: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let userId: UUID
    public let goalId: UUID
    public let occurrenceId: UUID?
    public var value: Double
    public var unit: UnitKind
    public var recordedAt: Date
    public let createdAt: Date

    /// MARK: - Initialization

    public init(
        id: UUID = UUID(),
        userId: UUID,
        goalId: UUID,
        occurrenceId: UUID? = nil,
        value: Double,
        unit: UnitKind,
        recordedAt: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.goalId = goalId
        self.occurrenceId = occurrenceId
        self.value = value
        self.unit = unit
        self.recordedAt = recordedAt
        self.createdAt = createdAt
    }

    /// MARK: - Equatable

    public static func == (lhs: Measurement, rhs: Measurement) -> Bool {
        lhs.id == rhs.id &&
        lhs.value == rhs.value &&
        lhs.unit == rhs.unit
    }

    /// MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// MARK: - UnitKind

/// Supported measurement units
public enum UnitKind: String, Codable, Sendable, CaseIterable {
    case count = "count"
    case ml = "ml"
    case l = "l"
    case oz = "oz"
    case kg = "kg"
    case lb = "lb"
    case minutes = "minutes"
    case hours = "hours"

    public var displayName: String {
        switch self {
        case .count: return "count"
        case .ml: return "mL"
        case .l: return "L"
        case .oz: return "oz"
        case .kg: return "kg"
        case .lb: return "lb"
        case .minutes: return "minutes"
        case .hours: return "hours"
        }
    }

    public var isVolume: Bool {
        [.ml, .l, .oz].contains(self)
    }

    public var isWeight: Bool {
        [.kg, .lb].contains(self)
    }

    public var isTime: Bool {
        [.minutes, .hours].contains(self)
    }
}

/// MARK: - GoalMeasureTarget

/// A versioned target for a measured goal
///
/// Allows users to change their daily targets over time (e.g., increase water intake from 2L to 3L).
/// The system tracks which target was in effect for each measurement.
@Observable
public final class GoalMeasureTarget: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let goalId: UUID
    public var targetValue: Double
    public var unit: UnitKind
    public var effectiveFrom: Date
    public var effectiveTo: Date?
    public let createdAt: Date

    /// MARK: - Initialization

    public init(
        id: UUID = UUID(),
        goalId: UUID,
        targetValue: Double,
        unit: UnitKind,
        effectiveFrom: Date = Date(),
        effectiveTo: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.goalId = goalId
        self.targetValue = targetValue
        self.unit = unit
        self.effectiveFrom = effectiveFrom
        self.effectiveTo = effectiveTo
        self.createdAt = createdAt
    }

    /// MARK: - Computed Properties

    /// Check if this target is currently active
    public var isActive: Bool {
        let now = Date()
        return effectiveFrom <= now && (effectiveTo.map { $0 > now } ?? true)
    }

    /// MARK: - Equatable

    public static func == (lhs: GoalMeasureTarget, rhs: GoalMeasureTarget) -> Bool {
        lhs.id == rhs.id &&
        lhs.targetValue == rhs.targetValue &&
        lhs.unit == rhs.unit
    }

    /// MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
