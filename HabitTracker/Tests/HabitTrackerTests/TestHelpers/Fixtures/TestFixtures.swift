import Foundation
@testable import HabitTracker

/// Centralized test fixtures for consistent test data
enum TestFixtures {
    // MARK: - Test UUIDs

    static let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let areaId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let goalId = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    static let occurrenceId = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    static let measurementId = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!

    // MARK: - Test Dates

    static let baseDate = Date(timeIntervalSince1970: 1700000000) // Fixed date for consistency
    static let laterDate = Date(timeIntervalSince1970: 1700086400) // +1 day

    // MARK: - Area Fixtures

    static func makeArea(
        id: UUID = areaId,
        userId: UUID = userId,
        name: String = "Health",
        emoji: String? = "💪",
        colorHex: String? = "#FF6B6B",
        status: AreaStatus = .active,
        createdAt: Date = baseDate,
        updatedAt: Date = baseDate
    ) -> Area {
        Area(
            id: id,
            userId: userId,
            name: name,
            emoji: emoji,
            colorHex: colorHex,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func makeAreaDTO(
        id: UUID = areaId,
        userId: UUID = userId,
        name: String = "Health",
        emoji: String = "💪",
        colorHex: String = "#FF6B6B",
        status: String = "active",
        createdAt: Date = baseDate,
        updatedAt: Date = baseDate
    ) -> AreaDTO {
        AreaDTO(
            id: id,
            userId: userId,
            name: name,
            emoji: emoji,
            colorHex: colorHex,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - Goal Fixtures

    static func makeGoal(
        id: UUID = goalId,
        userId: UUID = userId,
        areaId: UUID = areaId,
        title: String = "Exercise Daily",
        emoji: String? = "🏃",
        kind: GoalKind = .habit,
        status: GoalStatus = .active,
        keepUntilComplete: Bool = false,
        timesPerDay: Int = 1,
        pointsPerCompletion: Int = 10,
        linkedExerciseKey: LinkedExercise? = nil,
        hashtags: [String] = [],
        createdAt: Date = baseDate,
        updatedAt: Date = baseDate
    ) -> Goal {
        Goal(
            id: id,
            userId: userId,
            areaId: areaId,
            title: title,
            emoji: emoji,
            kind: kind,
            status: status,
            keepUntilComplete: keepUntilComplete,
            timesPerDay: timesPerDay,
            pointsPerCompletion: pointsPerCompletion,
            linkedExerciseKey: linkedExerciseKey,
            hashtags: hashtags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func makeGoalDTO(
        id: UUID = goalId,
        userId: UUID = userId,
        areaId: UUID = areaId,
        title: String = "Exercise Daily",
        emoji: String = "🏃",
        kind: String = "habit",
        status: String = "active",
        keepUntilComplete: Bool = false,
        timesPerDay: Int = 1,
        pointsPerCompletion: Int = 10,
        linkedExerciseKey: String? = nil,
        hashtags: [String] = [],
        createdAt: Date = baseDate,
        updatedAt: Date = baseDate
    ) -> GoalDTO {
        GoalDTO(
            id: id,
            userId: userId,
            areaId: areaId,
            title: title,
            emoji: emoji,
            kind: kind,
            status: status,
            keepUntilComplete: keepUntilComplete,
            timesPerDay: timesPerDay,
            pointsPerCompletion: pointsPerCompletion,
            linkedExerciseKey: linkedExerciseKey,
            hashtags: hashtags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - GoalOccurrence Fixtures

    static func makeOccurrence(
        id: UUID = occurrenceId,
        userId: UUID = userId,
        goalId: UUID = goalId,
        scheduledDate: Date = baseDate,
        dueAt: Date? = nil,
        targetCount: Int = 1,
        completedCount: Int = 0,
        status: OccurrenceStatus = .pending,
        keepUntilComplete: Bool = false,
        rolledFromId: UUID? = nil,
        rolledIntoId: UUID? = nil,
        nameOverride: String? = nil,
        emojiOverride: String? = nil,
        contentSnapshot: ContentSnapshot? = nil,
        isOneTime: Bool = false,
        createdAt: Date = baseDate,
        updatedAt: Date = baseDate
    ) -> GoalOccurrence {
        GoalOccurrence(
            id: id,
            goalId: goalId,
            userId: userId,
            scheduledDate: scheduledDate,
            dueAt: dueAt,
            status: status,
            targetCount: targetCount,
            completedCount: completedCount,
            keepUntilComplete: keepUntilComplete,
            rolledFromId: rolledFromId,
            rolledIntoId: rolledIntoId,
            nameOverride: nameOverride,
            emojiOverride: emojiOverride,
            contentSnapshot: contentSnapshot,
            isOneTime: isOneTime,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func makeOccurrenceDTO(
        id: UUID = occurrenceId,
        userId: UUID = userId,
        goalId: UUID = goalId,
        scheduleId: UUID? = nil,
        scheduledDate: Date = baseDate,
        dueAt: Date? = nil,
        targetCount: Int = 1,
        completedCount: Int = 0,
        status: String = "pending",
        keepUntilComplete: Bool = false,
        rolledFromId: UUID? = nil,
        rolledIntoId: UUID? = nil,
        nameOverride: String? = nil,
        emojiOverride: String? = nil,
        contentSnapshot: ContentSnapshotDTO? = nil,
        isOneTime: Bool = false,
        createdAt: Date = baseDate,
        updatedAt: Date = baseDate
    ) -> GoalOccurrenceDTO {
        GoalOccurrenceDTO(
            id: id,
            userId: userId,
            goalId: goalId,
            scheduleId: scheduleId,
            scheduledDate: scheduledDate,
            dueAt: dueAt,
            targetCount: targetCount,
            completedCount: completedCount,
            status: status,
            keepUntilComplete: keepUntilComplete,
            rolledFromId: rolledFromId,
            rolledIntoId: rolledIntoId,
            nameOverride: nameOverride,
            emojiOverride: emojiOverride,
            contentSnapshot: contentSnapshot,
            isOneTime: isOneTime,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - Measurement Fixtures

    static func makeMeasurement(
        id: UUID = measurementId,
        userId: UUID = userId,
        goalId: UUID = goalId,
        occurrenceId: UUID? = nil,
        value: Double = 500.0,
        unit: UnitKind = .ml,
        recordedAt: Date = baseDate,
        createdAt: Date = baseDate,
        updatedAt: Date = baseDate
    ) -> Measurement {
        Measurement(
            id: id,
            userId: userId,
            goalId: goalId,
            occurrenceId: occurrenceId,
            value: value,
            unit: unit,
            recordedAt: recordedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func makeMeasurementDTO(
        id: UUID = measurementId,
        userId: UUID = userId,
        goalId: UUID = goalId,
        occurrenceId: UUID? = nil,
        value: Double = 500.0,
        unit: String = "ml",
        recordedAt: Date = baseDate,
        createdAt: Date = baseDate,
        updatedAt: Date = baseDate
    ) -> MeasurementDTO {
        MeasurementDTO(
            id: id,
            userId: userId,
            goalId: goalId,
            occurrenceId: occurrenceId,
            value: value,
            unit: unit,
            recordedAt: recordedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - GoalMeasureTarget Fixtures

    static func makeMeasureTarget(
        id: UUID = UUID(),
        userId: UUID = userId,
        goalId: UUID = goalId,
        targetValue: Double = 2000.0,
        unit: UnitKind = .ml,
        effectiveFrom: Date = baseDate,
        effectiveTo: Date? = nil,
        createdAt: Date = baseDate,
        updatedAt: Date = baseDate
    ) -> GoalMeasureTarget {
        GoalMeasureTarget(
            id: id,
            userId: userId,
            goalId: goalId,
            targetValue: targetValue,
            unit: unit,
            effectiveFrom: effectiveFrom,
            effectiveTo: effectiveTo,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func makeMeasureTargetDTO(
        id: UUID = UUID(),
        userId: UUID = userId,
        goalId: UUID = goalId,
        targetValue: Double = 2000.0,
        unit: String = "ml",
        effectiveFrom: Date = baseDate,
        effectiveTo: Date? = nil,
        createdAt: Date = baseDate,
        updatedAt: Date = baseDate
    ) -> GoalMeasureTargetDTO {
        GoalMeasureTargetDTO(
            id: id,
            userId: userId,
            goalId: goalId,
            targetValue: targetValue,
            unit: unit,
            effectiveFrom: effectiveFrom,
            effectiveTo: effectiveTo,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
