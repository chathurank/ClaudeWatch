import Foundation

enum UsageError: Error, LocalizedError {
    case credentialsNotFound
    case credentialsExpired
    case credentialsInvalid
    case networkError(Error)
    case apiError(statusCode: Int, message: String?)
    case decodingError(Error)
    case authError(String)

    // User-facing error descriptions (sanitized - no sensitive details)
    var errorDescription: String? {
        switch self {
        case .credentialsNotFound:
            return "Claude Code credentials not found"
        case .credentialsExpired:
            return "Credentials have expired"
        case .credentialsInvalid:
            return "Unable to read credentials"
        case .networkError:
            return "Connection failed"
        case .apiError(let code, _):
            // Only show status code category, not full details
            switch code {
            case 401:
                return "Authentication failed"
            case 403:
                return "Access denied"
            case 429:
                return "Rate limited"
            case 500...599:
                return "Service temporarily unavailable"
            default:
                return "Request failed"
            }
        case .decodingError:
            return "Invalid response from server"
        case .authError(let message):
            return message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .credentialsNotFound, .credentialsExpired, .credentialsInvalid:
            return "Run 'claude' in Terminal to authenticate"
        case .networkError:
            return "Check your internet connection"
        case .apiError(let code, _):
            if code == 401 {
                return "Run 'claude' in Terminal to re-authenticate"
            } else if code == 429 {
                return "Please wait before trying again"
            }
            return "Try again later"
        case .decodingError:
            return "Try again later"
        case .authError:
            return "Run 'claude' in Terminal to re-authenticate"
        }
    }

    // Internal debug description (for logging only, not shown to users)
    var debugDescription: String {
        switch self {
        case .credentialsNotFound:
            return "Keychain item not found"
        case .credentialsExpired:
            return "OAuth token expired"
        case .credentialsInvalid:
            return "Failed to decode credentials from Keychain"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message ?? "no message")"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .authError(let message):
            return "Auth error: \(message)"
        }
    }
}
