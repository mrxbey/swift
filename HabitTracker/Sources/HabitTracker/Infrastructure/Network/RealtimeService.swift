import Foundation
import Supabase
import Realtime

/// Service for managing Supabase Realtime subscriptions
///
/// Provides a centralized interface for subscribing to database changes via WebSocket.
/// All subscriptions are automatically cleaned up when the service is deinitialized.
public actor RealtimeService {
    private let client: SupabaseClient
    private var channels: [String: RealtimeChannel] = [:]

    /// MARK: - Initialization

    public init(client: SupabaseClient) {
        self.client = client
    }

    public init() {
        self.client = SupabaseService.shared.getClient()
    }

    deinit {
        // Clean up all channels
        Task {
            await unsubscribeAll()
        }
    }

    /// MARK: - Occurrence Subscriptions

    /// Subscribes to changes in goal_occurrences for the current user
    ///
    /// Returns a stream of occurrence events (insert, update, delete).
    ///
    /// - Parameter userId: The UUID of the user to filter by
    /// - Returns: AsyncStream of OccurrenceEvent
    public func subscribeToOccurrences(userId: UUID) -> AsyncStream<OccurrenceEvent> {
        AsyncStream { continuation in
            Task {
                let channelName = "occurrences:\(userId.uuidString)"

                // Remove existing channel if present
                if let existingChannel = channels[channelName] {
                    await client.realtime.removeChannel(existingChannel)
                }

                // Create new channel
                let channel = await client.realtime.channel(channelName)

                // Subscribe to all events on goal_occurrences
                await channel
                    .on(
                        .postgresChanges(
                            event: .all,
                            schema: "public",
                            table: "goal_occurrences",
                            filter: "user_id=eq.\(userId.uuidString)"
                        )
                    ) { payload in
                        Task {
                            await self.handleOccurrenceChange(payload, continuation: continuation)
                        }
                    }
                    .subscribe()

                // Store channel reference
                await self.storeChannel(channelName, channel)

                // Handle cancellation
                continuation.onTermination = { @Sendable _ in
                    Task {
                        await self.unsubscribe(from: channelName)
                    }
                }
            }
        }
    }

    /// Subscribes to changes in goals for the current user
    ///
    /// Returns a stream of goal events (insert, update, delete).
    ///
    /// - Parameter userId: The UUID of the user to filter by
    /// - Returns: AsyncStream of GoalEvent
    public func subscribeToGoals(userId: UUID) -> AsyncStream<GoalEvent> {
        AsyncStream { continuation in
            Task {
                let channelName = "goals:\(userId.uuidString)"

                if let existingChannel = channels[channelName] {
                    await client.realtime.removeChannel(existingChannel)
                }

                let channel = await client.realtime.channel(channelName)

                await channel
                    .on(
                        .postgresChanges(
                            event: .all,
                            schema: "public",
                            table: "goals",
                            filter: "user_id=eq.\(userId.uuidString)"
                        )
                    ) { payload in
                        Task {
                            await self.handleGoalChange(payload, continuation: continuation)
                        }
                    }
                    .subscribe()

                await self.storeChannel(channelName, channel)

                continuation.onTermination = { @Sendable _ in
                    Task {
                        await self.unsubscribe(from: channelName)
                    }
                }
            }
        }
    }

    /// Subscribes to changes in areas for the current user
    ///
    /// Returns a stream of area events (insert, update, delete).
    ///
    /// - Parameter userId: The UUID of the user to filter by
    /// - Returns: AsyncStream of AreaEvent
    public func subscribeToAreas(userId: UUID) -> AsyncStream<AreaEvent> {
        AsyncStream { continuation in
            Task {
                let channelName = "areas:\(userId.uuidString)"

                if let existingChannel = channels[channelName] {
                    await client.realtime.removeChannel(existingChannel)
                }

                let channel = await client.realtime.channel(channelName)

                await channel
                    .on(
                        .postgresChanges(
                            event: .all,
                            schema: "public",
                            table: "areas",
                            filter: "user_id=eq.\(userId.uuidString)"
                        )
                    ) { payload in
                        Task {
                            await self.handleAreaChange(payload, continuation: continuation)
                        }
                    }
                    .subscribe()

                await self.storeChannel(channelName, channel)

                continuation.onTermination = { @Sendable _ in
                    Task {
                        await self.unsubscribe(from: channelName)
                    }
                }
            }
        }
    }

    /// MARK: - Channel Management

    private func storeChannel(_ name: String, _ channel: RealtimeChannel) {
        channels[name] = channel
    }

    /// Unsubscribes from a specific channel
    ///
    /// - Parameter channelName: The name of the channel to unsubscribe from
    public func unsubscribe(from channelName: String) async {
        guard let channel = channels[channelName] else { return }

        await client.realtime.removeChannel(channel)
        channels.removeValue(forKey: channelName)
    }

    /// Unsubscribes from all channels
    public func unsubscribeAll() async {
        for (_, channel) in channels {
            await client.realtime.removeChannel(channel)
        }
        channels.removeAll()
    }

    /// MARK: - Event Handlers

    private func handleOccurrenceChange(
        _ payload: RealtimeMessage,
        continuation: AsyncStream<OccurrenceEvent>.Continuation
    ) {
        do {
            let eventType = payload.eventType

            switch eventType {
            case "INSERT":
                if let newRecord = payload.newRecord {
                    let data = try JSONSerialization.data(withJSONObject: newRecord)
                    let dto = try JSONDecoder().decode(GoalOccurrenceDTO.self, from: data)
                    continuation.yield(.inserted(dto.toDomain))
                }

            case "UPDATE":
                if let newRecord = payload.newRecord {
                    let data = try JSONSerialization.data(withJSONObject: newRecord)
                    let dto = try JSONDecoder().decode(GoalOccurrenceDTO.self, from: data)
                    continuation.yield(.updated(dto.toDomain))
                }

            case "DELETE":
                if let oldRecord = payload.oldRecord,
                   let idString = oldRecord["id"] as? String,
                   let id = UUID(uuidString: idString) {
                    continuation.yield(.deleted(id))
                }

            default:
                break
            }
        } catch {
            print("Error decoding occurrence event: \(error)")
        }
    }

    private func handleGoalChange(
        _ payload: RealtimeMessage,
        continuation: AsyncStream<GoalEvent>.Continuation
    ) {
        do {
            let eventType = payload.eventType

            switch eventType {
            case "INSERT":
                if let newRecord = payload.newRecord {
                    let data = try JSONSerialization.data(withJSONObject: newRecord)
                    let dto = try JSONDecoder().decode(GoalDTO.self, from: data)
                    continuation.yield(.inserted(dto.toDomain))
                }

            case "UPDATE":
                if let newRecord = payload.newRecord {
                    let data = try JSONSerialization.data(withJSONObject: newRecord)
                    let dto = try JSONDecoder().decode(GoalDTO.self, from: data)
                    continuation.yield(.updated(dto.toDomain))
                }

            case "DELETE":
                if let oldRecord = payload.oldRecord,
                   let idString = oldRecord["id"] as? String,
                   let id = UUID(uuidString: idString) {
                    continuation.yield(.deleted(id))
                }

            default:
                break
            }
        } catch {
            print("Error decoding goal event: \(error)")
        }
    }

    private func handleAreaChange(
        _ payload: RealtimeMessage,
        continuation: AsyncStream<AreaEvent>.Continuation
    ) {
        do {
            let eventType = payload.eventType

            switch eventType {
            case "INSERT":
                if let newRecord = payload.newRecord {
                    let data = try JSONSerialization.data(withJSONObject: newRecord)
                    let dto = try JSONDecoder().decode(AreaDTO.self, from: data)
                    continuation.yield(.inserted(dto.toDomain))
                }

            case "UPDATE":
                if let newRecord = payload.newRecord {
                    let data = try JSONSerialization.data(withJSONObject: newRecord)
                    let dto = try JSONDecoder().decode(AreaDTO.self, from: data)
                    continuation.yield(.updated(dto.toDomain))
                }

            case "DELETE":
                if let oldRecord = payload.oldRecord,
                   let idString = oldRecord["id"] as? String,
                   let id = UUID(uuidString: idString) {
                    continuation.yield(.deleted(id))
                }

            default:
                break
            }
        } catch {
            print("Error decoding area event: \(error)")
        }
    }
}

/// MARK: - Event Types

/// Event types for occurrence changes
public enum OccurrenceEvent: Sendable, Equatable {
    case inserted(GoalOccurrence)
    case updated(GoalOccurrence)
    case deleted(UUID)
}

/// Event types for goal changes
public enum GoalEvent: Sendable, Equatable {
    case inserted(Goal)
    case updated(Goal)
    case deleted(UUID)
}

/// Event types for area changes
public enum AreaEvent: Sendable, Equatable {
    case inserted(Area)
    case updated(Area)
    case deleted(UUID)
}
