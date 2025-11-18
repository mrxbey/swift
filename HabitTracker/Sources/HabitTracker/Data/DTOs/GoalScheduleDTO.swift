import Foundation

/// Data Transfer Object for GoalSchedule entity
///
/// Maps between the PostgreSQL `goal_schedules` table (snake_case) and the Swift `GoalSchedule` domain model (camelCase).
public struct GoalScheduleDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let goalId: UUID
    public let freq: String
    public let interval: Int
    public let byWeekday: [Int]?
    public let byMonthday: [Int]?
    public let startDate: Date
    public let endDate: Date?
    public let timezone: String
    public let rrule: String?
    public let createdAt: Date
    public let updatedAt: Date

    /// MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case freq
        case interval
        case byWeekday = "by_weekday"
        case byMonthday = "by_monthday"
        case startDate = "start_date"
        case endDate = "end_date"
        case timezone
        case rrule
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// MARK: - Initialization

    /// Creates a DTO from a domain model
    ///
    /// - Parameter schedule: The domain GoalSchedule model
    public init(from schedule: GoalSchedule) {
        self.id = schedule.id
        self.goalId = schedule.goalId
        self.freq = schedule.freq.rawValue
        self.interval = schedule.interval
        self.byWeekday = schedule.byWeekday
        self.byMonthday = schedule.byMonthday
        self.startDate = schedule.startDate
        self.endDate = schedule.endDate
        self.timezone = schedule.timezone
        self.rrule = schedule.rrule
        self.createdAt = schedule.createdAt
        self.updatedAt = schedule.updatedAt
    }

    /// MARK: - Conversion

    /// Converts the DTO to a domain model
    public var toDomain: GoalSchedule {
        GoalSchedule(
            id: id,
            goalId: goalId,
            freq: PeriodFrequency(rawValue: freq) ?? .daily,
            interval: interval,
            startDate: startDate,
            endDate: endDate,
            byWeekday: byWeekday,
            byMonthday: byMonthday,
            timezone: timezone,
            rrule: rrule,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
