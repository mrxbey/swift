import Foundation
import SwiftData
@testable import HabitTracker

/// Mock CacheService for testing repositories
///
/// Provides in-memory storage without requiring SwiftData container.
/// Thread-safe for testing concurrent operations.
@MainActor
final class MockCacheService {
    // In-memory storage
    private var areas: [UUID: (area: Area, syncState: SyncState)] = [:]
    private var goals: [UUID: (goal: Goal, syncState: SyncState)] = [:]
    private var occurrences: [UUID: (occurrence: GoalOccurrence, syncState: SyncState)] = [:]
    private var measurements: [UUID: (measurement: Measurement, syncState: SyncState)] = [:]

    // Call tracking
    var saveAreaCalled = false
    var fetchAreasCalled = false
    var fetchAreaByIdCalled = false
    var deleteAreaCalled = false

    var saveGoalCalled = false
    var fetchGoalsCalled = false
    var fetchGoalByIdCalled = false
    var deleteGoalCalled = false

    var saveOccurrenceCalled = false
    var fetchOccurrencesCalled = false
    var deleteOccurrenceCalled = false

    var saveMeasurementCalled = false
    var fetchMeasurementsCalled = false
    var deleteMeasurementCalled = false

    // MARK: - Area Operations

    func saveArea(_ area: Area, syncState: SyncState) throws {
        saveAreaCalled = true
        areas[area.id] = (area, syncState)
    }

    func fetchAreas(userId: UUID) throws -> [Area] {
        fetchAreasCalled = true
        return areas.values
            .filter { $0.area.userId == userId }
            .map { $0.area }
    }

    func fetchArea(id: UUID) throws -> Area? {
        fetchAreaByIdCalled = true
        return areas[id]?.area
    }

    func deleteArea(id: UUID) throws {
        deleteAreaCalled = true
        areas.removeValue(forKey: id)
    }

    func fetchPendingAreas() throws -> [Area] {
        return areas.values
            .filter { $0.syncState == .pending }
            .map { $0.area }
    }

    // MARK: - Goal Operations

    func saveGoal(_ goal: Goal, syncState: SyncState) throws {
        saveGoalCalled = true
        goals[goal.id] = (goal, syncState)
    }

    func fetchGoals(userId: UUID) throws -> [Goal] {
        fetchGoalsCalled = true
        return goals.values
            .filter { $0.goal.userId == userId }
            .map { $0.goal }
    }

    func fetchGoals(areaId: UUID) throws -> [Goal] {
        fetchGoalsCalled = true
        return goals.values
            .filter { $0.goal.areaId == areaId }
            .map { $0.goal }
    }

    func fetchGoal(id: UUID) throws -> Goal? {
        fetchGoalByIdCalled = true
        return goals[id]?.goal
    }

    func deleteGoal(id: UUID) throws {
        deleteGoalCalled = true
        goals.removeValue(forKey: id)
    }

    func fetchPendingGoals() throws -> [Goal] {
        return goals.values
            .filter { $0.syncState == .pending }
            .map { $0.goal }
    }

    // MARK: - Occurrence Operations

    func saveOccurrence(_ occurrence: GoalOccurrence, syncState: SyncState) throws {
        saveOccurrenceCalled = true
        occurrences[occurrence.id] = (occurrence, syncState)
    }

    func fetchOccurrences(userId: UUID, date: Date) throws -> [GoalOccurrence] {
        fetchOccurrencesCalled = true
        let calendar = Calendar.current
        return occurrences.values
            .filter { $0.occurrence.userId == userId }
            .filter { calendar.isDate($0.occurrence.scheduledDate, inSameDayAs: date) }
            .map { $0.occurrence }
    }

    func fetchOccurrence(id: UUID) throws -> GoalOccurrence? {
        return occurrences[id]?.occurrence
    }

    func deleteOccurrence(id: UUID) throws {
        deleteOccurrenceCalled = true
        occurrences.removeValue(forKey: id)
    }

    func fetchPendingOccurrences() throws -> [GoalOccurrence] {
        return occurrences.values
            .filter { $0.syncState == .pending }
            .map { $0.occurrence }
    }

    // MARK: - Measurement Operations

    func saveMeasurement(_ measurement: Measurement, syncState: SyncState) throws {
        saveMeasurementCalled = true
        measurements[measurement.id] = (measurement, syncState)
    }

    func fetchMeasurements(goalId: UUID) throws -> [Measurement] {
        fetchMeasurementsCalled = true
        return measurements.values
            .filter { $0.measurement.goalId == goalId }
            .map { $0.measurement }
    }

    func fetchMeasurement(id: UUID) throws -> Measurement? {
        return measurements[id]?.measurement
    }

    func deleteMeasurement(id: UUID) throws {
        deleteMeasurementCalled = true
        measurements.removeValue(forKey: id)
    }

    func fetchPendingMeasurements() throws -> [Measurement] {
        return measurements.values
            .filter { $0.syncState == .pending }
            .map { $0.measurement }
    }

    // MARK: - Utility

    func reset() {
        areas.removeAll()
        goals.removeAll()
        occurrences.removeAll()
        measurements.removeAll()

        saveAreaCalled = false
        fetchAreasCalled = false
        fetchAreaByIdCalled = false
        deleteAreaCalled = false

        saveGoalCalled = false
        fetchGoalsCalled = false
        fetchGoalByIdCalled = false
        deleteGoalCalled = false

        saveOccurrenceCalled = false
        fetchOccurrencesCalled = false
        deleteOccurrenceCalled = false

        saveMeasurementCalled = false
        fetchMeasurementsCalled = false
        deleteMeasurementCalled = false
    }
}
