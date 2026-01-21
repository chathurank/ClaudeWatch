import Foundation
import CommonCrypto
import Security
import os.log

/// URLSession delegate that implements certificate pinning for the Anthropic API.
/// Uses SPKI (Subject Public Key Info) pinning for resilience against certificate rotation.
///
/// Fallback behavior: If pinning fails but standard TLS validation passes, the connection
/// is allowed to proceed. This ensures the app continues to work if Anthropic updates
/// their certificate chain, while still providing MITM protection via standard TLS.
final class CertificatePinningDelegate: NSObject, URLSessionDelegate {

    /// Logger for security events
    private let logger = Logger(subsystem: "com.claudewatch.app", category: "CertificatePinning")

    /// SHA-256 hashes of the public keys we trust.
    /// These are the SPKI hashes for api.anthropic.com's certificate chain.
    ///
    /// To update these hashes, run:
    /// ```
    /// openssl s_client -connect api.anthropic.com:443 -servername api.anthropic.com 2>/dev/null | \
    ///   openssl x509 -pubkey -noout | openssl pkey -pubin -outform DER | \
    ///   openssl dgst -sha256 -binary | base64
    /// ```
    ///
    /// For the full chain:
    /// ```
    /// openssl s_client -connect api.anthropic.com:443 -servername api.anthropic.com -showcerts 2>/dev/null | \
    ///   awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ print }' | \
    ///   while openssl x509 -pubkey -noout 2>/dev/null; do :; done | \
    ///   openssl pkey -pubin -outform DER 2>/dev/null | openssl dgst -sha256 -binary | base64
    /// ```
    private let pinnedPublicKeyHashes: Set<String> = [
        // Cloudflare Inc ECC CA-3 (intermediate)
        "Fo9FLlk/vfS8ROs9EDRgYMIPVlprGMIuC5FNAtoSEko=",
        // DigiCert Global Root CA (root)
        "i7WTqTvh0OioIruIfFR4kMPnBqrS2rdiVPl/s2uC/CY=",
        // Baltimore CyberTrust Root (backup root)
        "Y9mvm0exBk1JoQ57f9Vm28jKo5lFm/woKcVxrYxu80o=",
        // DigiCert Global Root G2 (additional root)
        "cb3ccbb76031e5e0138f8dd39a23f9de47ffc35e43c1144cea27d46a5ab1cb5f",
        // Cloudflare Origin CA (backup)
        "PbMGAwhNgz2p1zOVqFLAGCNw/IxQJwpahK3/gXPBANQ="
    ]

    /// The hostname we expect to connect to
    private let expectedHost = "api.anthropic.com"

    /// Track whether pinning has failed (for diagnostics)
    private(set) var pinningFailed = false

    /// UserDefaults key for tracking pinning failures
    private let pinningFailureKey = "certificatePinningFailedAt"

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only handle server trust authentication
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Verify the hostname matches
        guard challenge.protectionSpace.host == expectedHost else {
            logger.warning("Unexpected host: \(challenge.protectionSpace.host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Evaluate the server trust using standard TLS validation
        var error: CFError?
        let tlsValid = SecTrustEvaluateWithError(serverTrust, &error)

        guard tlsValid else {
            logger.error("TLS validation failed: \(String(describing: error))")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Check if any certificate in the chain has a pinned public key
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            // Can't get certificate chain, but TLS is valid - allow with warning
            logger.warning("Could not extract certificate chain, falling back to TLS validation")
            recordPinningFailure()
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            return
        }

        // Try to match against pinned certificates
        for certificate in certificateChain {
            if let publicKeyHash = publicKeyHash(for: certificate),
               pinnedPublicKeyHashes.contains(publicKeyHash) {
                // Found a matching pinned public key - clear any previous failure
                clearPinningFailure()
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }

        // Pinning failed, but TLS validation passed
        // Allow the connection but record the failure for diagnostics
        logger.warning("Certificate pinning failed - no matching pin found. Falling back to TLS validation.")
        logCertificateChain(certificateChain)
        recordPinningFailure()

        // FALLBACK: Allow connection since TLS validation passed
        // This ensures the app continues to work if Anthropic updates their certificates
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }

    /// Extracts and hashes the public key from a certificate.
    /// Uses SPKI (Subject Public Key Info) format for the hash.
    private func publicKeyHash(for certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            return nil
        }

        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }

        // Hash the public key data with SHA-256
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        publicKeyData.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }

        return Data(hash).base64EncodedString()
    }

    /// Logs the certificate chain for debugging when pinning fails
    private func logCertificateChain(_ chain: [SecCertificate]) {
        logger.info("Certificate chain (\(chain.count) certificates):")
        for (index, cert) in chain.enumerated() {
            if let summary = SecCertificateCopySubjectSummary(cert) as String? {
                let hash = publicKeyHash(for: cert) ?? "unknown"
                logger.info("  [\(index)] \(summary) - hash: \(hash)")
            }
        }
    }

    /// Records that pinning failed (for user notification)
    private func recordPinningFailure() {
        pinningFailed = true
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: pinningFailureKey)
    }

    /// Clears pinning failure state
    private func clearPinningFailure() {
        pinningFailed = false
        UserDefaults.standard.removeObject(forKey: pinningFailureKey)
    }

    /// Returns true if pinning has failed recently (within the last 24 hours)
    static var hasPinningFailedRecently: Bool {
        guard let timestamp = UserDefaults.standard.object(forKey: "certificatePinningFailedAt") as? TimeInterval else {
            return false
        }
        let failureDate = Date(timeIntervalSince1970: timestamp)
        return Date().timeIntervalSince(failureDate) < 86400 // 24 hours
    }
}
