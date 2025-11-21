import Foundation
import OSLog

/// Centralized logging framework using OSLog
///
/// Provides consistent, structured logging across the entire application.
/// Logs are automatically categorized by subsystem and component for easy filtering in Console.app.
public struct Logger {
    private let logger: os.Logger

    /// MARK: - Initialization

    /// Creates a logger for a specific category
    ///
    /// - Parameter category: The category (component) for this logger
    public init(category: String) {
        self.logger = os.Logger(subsystem: "com.habittracker.app", category: category)
    }

    /// MARK: - Logging Methods

    /// Logs a debug message
    ///
    /// Use for detailed information during development and debugging.
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    public func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logger.debug("\(message) [\(fileName(from: file)):\(line) \(function)]")
    }

    /// Logs an informational message
    ///
    /// Use for general informational messages about app state or flow.
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    public func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logger.info("\(message) [\(fileName(from: file)):\(line)]")
    }

    /// Logs a notice (significant but not error-level event)
    ///
    /// Use for important state changes or notable events.
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    public func notice(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logger.notice("\(message) [\(fileName(from: file)):\(line)]")
    }

    /// Logs a warning message
    ///
    /// Use for recoverable errors or unexpected situations that don't prevent continued operation.
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    public func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logger.warning("\(message) [\(fileName(from: file)):\(line)]")
    }

    /// Logs an error message
    ///
    /// Use for errors that prevent an operation from completing but don't crash the app.
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    public func error(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if let error = error {
            logger.error("\(message): \(error.localizedDescription) [\(fileName(from: file)):\(line)]")
        } else {
            logger.error("\(message) [\(fileName(from: file)):\(line)]")
        }
    }

    /// Logs a critical error
    ///
    /// Use for severe errors that may lead to app termination.
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    public func critical(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if let error = error {
            logger.critical("\(message): \(error.localizedDescription) [\(fileName(from: file)):\(line)]")
        } else {
            logger.critical("\(message) [\(fileName(from: file)):\(line)]")
        }
    }

    /// Logs a fault (system-level error)
    ///
    /// Use for bugs or system-level errors that should never happen.
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    public func fault(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if let error = error {
            logger.fault("\(message): \(error.localizedDescription) [\(fileName(from: file)):\(line)]")
        } else {
            logger.fault("\(message) [\(fileName(from: file)):\(line)]")
        }
    }

    /// MARK: - Helper Methods

    /// Extracts file name from full path
    private func fileName(from path: String) -> String {
        (path as NSString).lastPathComponent
    }
}

/// MARK: - Pre-configured Loggers

public extension Logger {
    /// Logger for network operations
    static let network = Logger(category: "Network")

    /// Logger for database operations
    static let database = Logger(category: "Database")

    /// Logger for sync operations
    static let sync = Logger(category: "Sync")

    /// Logger for cache operations
    static let cache = Logger(category: "Cache")

    /// Logger for realtime subscriptions
    static let realtime = Logger(category: "Realtime")

    /// Logger for repository operations
    static let repository = Logger(category: "Repository")

    /// Logger for authentication
    static let auth = Logger(category: "Auth")

    /// Logger for general app events
    static let app = Logger(category: "App")
}
