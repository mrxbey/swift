import Foundation

/// Recurrence pattern for a goal (daily, weekly, monthly, or none for one-time tasks)
@Observable
public final class GoalSchedule: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public var goalId: UUID
    public var freq: PeriodFrequency
    public var interval: Int
    public var startDate: Date
    public var endDate: Date?
    public var byWeekday: [Int]?    // ISO 8601: 1=Mon...7=Sun
    public var byMonthday: [Int]?   // 1...31
    public var timezone: String
    public var rrule: String?       // Optional RFC 5545 RRULE
    public let createdAt: Date
    public var updatedAt: Date

    /// MARK: - Lifecycle

    public init(
        id: UUID = UUID(),
        goalId: UUID,
        freq: PeriodFrequency = .none,
        interval: Int = 1,
        startDate: Date = Date(),
        endDate: Date? = nil,
        byWeekday: [Int]? = nil,
        byMonthday: [Int]? = nil,
        timezone: String = TimeZone.current.identifier,
        rrule: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.goalId = goalId
        self.freq = freq
        self.interval = max(interval, 1)
        self.startDate = startDate
        self.endDate = endDate
        self.byWeekday = byWeekday
        self.byMonthday = byMonthday
        self.timezone = timezone
        self.rrule = rrule
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// MARK: - Computed Properties

    public var isRepeating: Bool {
        freq != .none
    }

    public var humanReadable: String {
        switch freq {
        case .none:
            return "Does not repeat"
        case .daily:
            return interval == 1 ? "Every day" : "Every \(interval) days"
        case .weekly:
            if let weekdays = byWeekday, !weekdays.isEmpty {
                let dayNames = weekdays.sorted().map { isoWeekdayToName($0) }
                if interval == 1 {
                    return "Every \(dayNames.joined(separator: ", "))"
                } else {
                    return "Every \(interval) weeks on \(dayNames.joined(separator: ", "))"
                }
            }
            return interval == 1 ? "Every week" : "Every \(interval) weeks"
        case .monthly:
            if let monthdays = byMonthday, !monthdays.isEmpty {
                let days = monthdays.sorted().map { ordinal($0) }
                if interval == 1 {
                    return "Monthly on the \(days.joined(separator: ", "))"
                } else {
                    return "Every \(interval) months on the \(days.joined(separator: ", "))"
                }
            }
            return interval == 1 ? "Every month" : "Every \(interval) months"
        }
    }

    /// MARK: - Validation

    public func validate() throws {
        guard interval >= 1 else {
            throw ScheduleValidationError.invalidInterval
        }

        switch freq {
        case .none:
            break
        case .daily:
            break
        case .weekly:
            guard let weekdays = byWeekday, !weekdays.isEmpty else {
                throw ScheduleValidationError.missingWeekdays
            }
            guard weekdays.allSatisfy({ (1...7).contains($0) }) else {
                throw ScheduleValidationError.invalidWeekday
            }
        case .monthly:
            guard let monthdays = byMonthday, !monthdays.isEmpty else {
                throw ScheduleValidationError.missingMonthdays
            }
            guard monthdays.allSatisfy({ (1...31).contains($0) }) else {
                throw ScheduleValidationError.invalidMonthday
            }
        }

        if let endDate = endDate {
            guard endDate >= startDate else {
                throw ScheduleValidationError.endBeforeStart
            }
        }
    }

    /// MARK: - Helpers

    private func isoWeekdayToName(_ day: Int) -> String {
        let names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return names[day - 1]
    }

    private func ordinal(_ n: Int) -> String {
        let suffix: String
        switch n {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(n)\(suffix)"
    }

    /// MARK: - Equatable

    public static func == (lhs: GoalSchedule, rhs: GoalSchedule) -> Bool {
        lhs.id == rhs.id &&
        lhs.freq == rhs.freq &&
        lhs.interval == rhs.interval &&
        lhs.byWeekday == rhs.byWeekday &&
        lhs.byMonthday == rhs.byMonthday
    }

    /// MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// MARK: - PeriodFrequency

public enum PeriodFrequency: String, Codable, Sendable, CaseIterable {
    case none       // One-time task
    case daily
    case weekly
    case monthly

    public var displayName: String {
        switch self {
        case .none: return "Does not repeat"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

/// MARK: - ScheduleValidationError

public enum ScheduleValidationError: LocalizedError {
    case invalidInterval
    case missingWeekdays
    case invalidWeekday
    case missingMonthdays
    case invalidMonthday
    case endBeforeStart

    public var errorDescription: String? {
        switch self {
        case .invalidInterval:
            return "Interval must be at least 1"
        case .missingWeekdays:
            return "Weekly schedule must specify at least one weekday"
        case .invalidWeekday:
            return "Weekdays must be between 1 (Monday) and 7 (Sunday)"
        case .missingMonthdays:
            return "Monthly schedule must specify at least one day of month"
        case .invalidMonthday:
            return "Month days must be between 1 and 31"
        case .endBeforeStart:
            return "End date must be after start date"
        }
    }
}

/// MARK: - Mock Data

#if DEBUG
extension GoalSchedule {
    public static let mockDaily = GoalSchedule(
        goalId: UUID(),
        freq: .daily,
        interval: 1
    )

    public static let mockWeekdays = GoalSchedule(
        goalId: UUID(),
        freq: .weekly,
        interval: 1,
        byWeekday: [1, 2, 3, 4, 5] // Mon-Fri
    )

    public static let mockWeekends = GoalSchedule(
        goalId: UUID(),
        freq: .weekly,
        interval: 1,
        byWeekday: [6, 7] // Sat-Sun
    )

    public static let mockMonthly = GoalSchedule(
        goalId: UUID(),
        freq: .monthly,
        interval: 1,
        byMonthday: [1, 15] // 1st and 15th
    )

    public static let mockOneTime = GoalSchedule(
        goalId: UUID(),
        freq: .none,
        interval: 1,
        startDate: Date()
    )

    public static let mockEveryOtherDay = GoalSchedule(
        goalId: UUID(),
        freq: .daily,
        interval: 2
    )
}
#endif
