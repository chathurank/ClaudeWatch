import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    // Service name must match Claude CLI's Keychain entry
    private let serviceName = "Claude Code-credentials"

    private init() {}

    /// Quick check if credentials exist in Keychain
    /// Security: Only checks existence - does NOT read or decode credential values
    /// Used for onboarding auto-detection polling
    func credentialsExist() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: false  // Don't return data, just check existence
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        return status == errSecSuccess
    }

    /// Retrieves OAuth credentials from macOS Keychain
    /// Note: Credentials are stored by Claude CLI, this app only reads them
    func getCredentials() throws -> ClaudeCredentials {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw UsageError.credentialsNotFound
        case errSecAuthFailed, errSecInteractionNotAllowed:
            // Keychain access denied or requires user interaction
            throw UsageError.credentialsInvalid
        default:
            throw UsageError.credentialsInvalid
        }

        guard let data = item as? Data else {
            throw UsageError.credentialsInvalid
        }

        do {
            let credentials = try JSONDecoder().decode(ClaudeCredentials.self, from: data)

            if credentials.claudeAiOauth.isExpired {
                throw UsageError.credentialsExpired
            }

            return credentials
        } catch is UsageError {
            throw UsageError.credentialsExpired
        } catch {
            throw UsageError.decodingError(error)
        }
    }
}
