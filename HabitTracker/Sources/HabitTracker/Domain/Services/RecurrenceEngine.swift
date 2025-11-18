import Foundation

/// Generates occurrence dates for goal schedules
public struct RecurrenceEngine: Sendable {
    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Generate occurrence dates for a schedule within a date range
    /// - Parameters:
    ///   - schedule: The goal schedule
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    ///   - timeZone: Timezone for date calculations
    /// - Returns: Array of dates where occurrences should be created
    public func generateOccurrences(
        for schedule: GoalSchedule,
        from startDate: Date,
        to endDate: Date,
        timeZone: TimeZone
    ) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        var occurrences: [Date] = []

        // For one-time tasks, only return the start date if it's in range
        guard schedule.isRepeating else {
            let scheduleStart = calendar.startOfDay(for: schedule.startDate)
            let rangeStart = calendar.startOfDay(for: startDate)
            let rangeEnd = calendar.startOfDay(for: endDate)

            if scheduleStart >= rangeStart && scheduleStart <= rangeEnd {
                return [scheduleStart]
            }
            return []
        }

        // Start from the later of: schedule start or query start
        var currentDate = calendar.startOfDay(for: max(schedule.startDate, startDate))
        let finalDate = calendar.startOfDay(for: min(schedule.endDate ?? endDate, endDate))

        // Safety limit: max 1000 occurrences
        var iterations = 0
        let maxIterations = 1000

        while currentDate <= finalDate && iterations < maxIterations {
            if shouldInclude(currentDate, schedule: schedule, calendar: calendar) {
                occurrences.append(currentDate)
            }

            // Move to next candidate date based on frequency
            guard let nextDate = calendar.date(
                byAdding: dateComponent(for: schedule.freq),
                value: schedule.interval,
                to: currentDate
            ) else {
                break
            }

            currentDate = nextDate
            iterations += 1
        }

        return occurrences
    }

    /// Generate occurrences for today only (for quick "today" queries)
    public func generateTodayOccurrence(
        for schedule: GoalSchedule,
        timeZone: TimeZone
    ) -> Date? {
        let today = Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let startOfToday = calendar.startOfDay(for: today)

        // Check if today is within the schedule range
        guard startOfToday >= schedule.startDate else { return nil }
        if let endDate = schedule.endDate, startOfToday > endDate {
            return nil
        }

        // For one-time tasks
        if !schedule.isRepeating {
            let scheduleStart = calendar.startOfDay(for: schedule.startDate)
            return scheduleStart == startOfToday ? startOfToday : nil
        }

        // Check if today matches the schedule pattern
        return shouldInclude(startOfToday, schedule: schedule, calendar: calendar)
            ? startOfToday
            : nil
    }

    // MARK: - Private Methods

    private func shouldInclude(
        _ date: Date,
        schedule: GoalSchedule,
        calendar: Calendar
    ) -> Bool {
        switch schedule.freq {
        case .none:
            // One-time: only on start date
            return calendar.isDate(date, inSameDayAs: schedule.startDate)

        case .daily:
            // Every N days: check if days since start is divisible by interval
            let components = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: schedule.startDate),
                to: calendar.startOfDay(for: date)
            )
            guard let daysSinceStart = components.day else { return false }
            return daysSinceStart % schedule.interval == 0

        case .weekly:
            // Check if it's the right weekday
            guard let weekdays = schedule.byWeekday, !weekdays.isEmpty else {
                return false
            }

            let weekday = isoWeekday(from: date, calendar: calendar)
            guard weekdays.contains(weekday) else { return false }

            // Check if weeks since start is divisible by interval
            let components = calendar.dateComponents(
                [.weekOfYear],
                from: calendar.startOfDay(for: schedule.startDate),
                to: calendar.startOfDay(for: date)
            )
            guard let weeksSinceStart = components.weekOfYear else { return false }
            return weeksSinceStart % schedule.interval == 0

        case .monthly:
            // Check if it's the right day of month
            guard let monthdays = schedule.byMonthday, !monthdays.isEmpty else {
                return false
            }

            let day = calendar.component(.day, from: date)

            // Handle overflow: if day doesn't exist in this month, skip
            guard monthdays.contains(day) else { return false }

            // Check if months since start is divisible by interval
            let components = calendar.dateComponents(
                [.month],
                from: calendar.startOfDay(for: schedule.startDate),
                to: calendar.startOfDay(for: date)
            )
            guard let monthsSinceStart = components.month else { return false }
            return monthsSinceStart % schedule.interval == 0
        }
    }

    private func dateComponent(for frequency: PeriodFrequency) -> Calendar.Component {
        switch frequency {
        case .none: return .day
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        }
    }

    /// Convert to ISO 8601 weekday (1=Monday...7=Sunday)
    private func isoWeekday(from date: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        // Foundation: 1=Sunday...7=Saturday
        // ISO: 1=Monday...7=Sunday
        return weekday == 1 ? 7 : weekday - 1
    }

    // MARK: - Convenience

    /// Generate occurrences for a rolling 14-day window (for notifications)
    public func generateNotificationWindow(
        for schedule: GoalSchedule,
        timeZone: TimeZone
    ) -> [Date] {
        let today = Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let endDate = calendar.date(byAdding: .day, value: 14, to: today)!

        return generateOccurrences(
            for: schedule,
            from: today,
            to: endDate,
            timeZone: timeZone
        )
    }

    /// Generate occurrences for a specific date range (week, month, etc.)
    public func generateOccurrencesForRange(
        _ range: DateRange,
        schedule: GoalSchedule,
        timeZone: TimeZone
    ) -> [Date] {
        return generateOccurrences(
            for: schedule,
            from: range.start,
            to: range.end,
            timeZone: timeZone
        )
    }
}

// MARK: - DateRange

public enum DateRange {
    case today
    case week
    case month
    case custom(start: Date, end: Date)

    public var start: Date {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        case .month:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        case .custom(let start, _):
            return start
        }
    }

    public var end: Date {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        case .week:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return calendar.date(byAdding: .day, value: 7, to: weekStart)!
        case .month:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return calendar.date(byAdding: .month, value: 1, to: monthStart)!
        case .custom(_, let end):
            return end
        }
    }
}

// MARK: - Tests Helper

#if DEBUG
extension RecurrenceEngine {
    /// Test helper to generate occurrences for debugging
    public static func preview(
        frequency: PeriodFrequency,
        interval: Int = 1,
        weekdays: [Int]? = nil,
        monthdays: [Int]? = nil,
        days: Int = 30
    ) -> [Date] {
        let engine = RecurrenceEngine()
        let schedule = GoalSchedule(
            goalId: UUID(),
            freq: frequency,
            interval: interval,
            startDate: Date(),
            byWeekday: weekdays,
            byMonthday: monthdays
        )

        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date())!

        return engine.generateOccurrences(
            for: schedule,
            from: Date(),
            to: endDate,
            timeZone: .current
        )
    }
}
#endif
