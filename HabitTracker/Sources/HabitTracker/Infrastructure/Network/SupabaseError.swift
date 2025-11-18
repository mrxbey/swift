import Foundation
import Supabase

/// Comprehensive error handling for Supabase operations
///
/// Maps low-level Supabase errors to user-friendly messages and provides
/// specific error cases for common scenarios.
public enum SupabaseError: LocalizedError, Equatable, Sendable {
    /// User is not authenticated
    case unauthorized

    /// Network connectivity issue
    case networkError(String)

    /// Failed to decode response data
    case decodingError(String)

    /// Row Level Security policy violation (permission denied)
    case rlsViolation

    /// Requested resource not found
    case notFound

    /// Unique constraint violation (duplicate data)
    case duplicateEntry(String)

    /// Foreign key constraint violation
    case invalidReference(String)

    /// Check constraint violation
    case constraintViolation(String)

    /// Invalid query or parameters
    case invalidQuery(String)

    /// Server error (500+)
    case serverError(String)

    /// Timeout error
    case timeout

    /// Unknown error with message
    case unknown(String)

    /// MARK: - LocalizedError Conformance

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to continue"

        case .networkError(let message):
            return "Network error: \(message)"

        case .decodingError(let message):
            return "Data format error: \(message)"

        case .rlsViolation:
            return "Permission denied. You don't have access to this resource."

        case .notFound:
            return "Resource not found"

        case .duplicateEntry(let field):
            return "This \(field) already exists"

        case .invalidReference(let reference):
            return "Invalid reference: \(reference)"

        case .constraintViolation(let constraint):
            return "Constraint violation: \(constraint)"

        case .invalidQuery(let message):
            return "Invalid request: \(message)"

        case .serverError(let message):
            return "Server error: \(message)"

        case .timeout:
            return "Request timed out. Please try again."

        case .unknown(let message):
            return "Unexpected error: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "Try signing out and signing back in"

        case .networkError:
            return "Check your internet connection and try again"

        case .decodingError:
            return "This might be a temporary issue. Try again later."

        case .rlsViolation:
            return "Make sure you're signed in with the correct account"

        case .notFound:
            return "The item may have been deleted or moved"

        case .duplicateEntry:
            return "Try using a different value"

        case .invalidReference:
            return "Make sure the referenced item exists"

        case .constraintViolation:
            return "Check your input and try again"

        case .invalidQuery:
            return "This shouldn't happen. Please report this issue."

        case .serverError:
            return "Try again in a few moments"

        case .timeout:
            return "Check your connection and try again"

        case .unknown:
            return "Try restarting the app"
        }
    }

    /// MARK: - Error Mapping

    /// Maps a PostgrestError to a SupabaseError
    ///
    /// - Parameter error: The PostgrestError to map
    /// - Returns: A corresponding SupabaseError
    public static func from(_ error: PostgrestError) -> SupabaseError {
        // Check error code
        if let code = error.code {
            switch code {
            // Authentication errors
            case "PGRST301":
                return .unauthorized

            // Not found
            case "PGRST116":
                return .notFound

            // RLS violation
            case "42501", "PGRST301":
                return .rlsViolation

            // Constraint violations
            case "23505":
                // Unique violation
                let field = extractFieldFromMessage(error.message ?? "")
                return .duplicateEntry(field)

            case "23503":
                // Foreign key violation
                let reference = extractFieldFromMessage(error.message ?? "")
                return .invalidReference(reference)

            case "23514":
                // Check constraint violation
                let constraint = extractFieldFromMessage(error.message ?? "")
                return .constraintViolation(constraint)

            // Invalid query
            case "42P01", "42703":
                return .invalidQuery(error.message ?? "Invalid query")

            default:
                break
            }
        }

        // Check status code
        if let status = error.statusCode {
            switch status {
            case 401:
                return .unauthorized
            case 404:
                return .notFound
            case 403:
                return .rlsViolation
            case 500...599:
                return .serverError(error.message ?? "Server error")
            case 408:
                return .timeout
            default:
                break
            }
        }

        // Check message for common patterns
        if let message = error.message {
            let lowercased = message.lowercased()

            if lowercased.contains("jwt") || lowercased.contains("auth") {
                return .unauthorized
            }

            if lowercased.contains("timeout") {
                return .timeout
            }

            if lowercased.contains("not found") {
                return .notFound
            }

            if lowercased.contains("duplicate") {
                let field = extractFieldFromMessage(message)
                return .duplicateEntry(field)
            }

            if lowercased.contains("permission") || lowercased.contains("access denied") {
                return .rlsViolation
            }
        }

        // Default
        return .unknown(error.message ?? "Unknown error")
    }

    /// Maps a generic Error to a SupabaseError
    ///
    /// - Parameter error: The Error to map
    /// - Returns: A corresponding SupabaseError
    public static func from(_ error: Error) -> SupabaseError {
        if let postgrestError = error as? PostgrestError {
            return from(postgrestError)
        }

        if let decodingError = error as? DecodingError {
            return .decodingError(decodingError.localizedDescription)
        }

        // Check for network errors
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost:
                return .networkError("No internet connection")
            case NSURLErrorTimedOut:
                return .timeout
            default:
                return .networkError(nsError.localizedDescription)
            }
        }

        return .unknown(error.localizedDescription)
    }

    /// MARK: - Helpers

    /// Extracts field name from error message
    private static func extractFieldFromMessage(_ message: String) -> String {
        // Try to extract field name from common patterns
        // Example: "duplicate key value violates unique constraint \"areas_user_id_name_key\""
        if let match = message.range(of: #""([^"]+)""#, options: .regularExpression) {
            let field = String(message[match]).replacingOccurrences(of: "\"", with: "")
            // Extract the field name (last part before _key)
            if let lastUnderscore = field.lastIndex(of: "_") {
                return String(field[..<lastUnderscore])
            }
            return field
        }

        return "value"
    }

    /// MARK: - Equatable

    public static func == (lhs: SupabaseError, rhs: SupabaseError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized),
             (.rlsViolation, .rlsViolation),
             (.notFound, .notFound),
             (.timeout, .timeout):
            return true

        case (.networkError(let lMsg), .networkError(let rMsg)),
             (.decodingError(let lMsg), .decodingError(let rMsg)),
             (.duplicateEntry(let lMsg), .duplicateEntry(let rMsg)),
             (.invalidReference(let lMsg), .invalidReference(let rMsg)),
             (.constraintViolation(let lMsg), .constraintViolation(let rMsg)),
             (.invalidQuery(let lMsg), .invalidQuery(let rMsg)),
             (.serverError(let lMsg), .serverError(let rMsg)),
             (.unknown(let lMsg), .unknown(let rMsg)):
            return lMsg == rMsg

        default:
            return false
        }
    }
}
