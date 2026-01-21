import Foundation

/// Error thrown when API response validation fails
enum ValidationError: Error {
    case invalidUtilizationRange(field: String, value: Double)
    case invalidResetDate(field: String, date: Date)
}

final class APIService {
    static let shared = APIService()

    private let baseURL = "https://api.anthropic.com"
    private let usageEndpoint = "/api/oauth/usage"
    private let userAgent = "ClaudeWatch/1.0"

    /// Secure URLSession with ephemeral configuration (no caching, no cookies)
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    /// Rate limiting: minimum interval between requests
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 5.0

    /// Exponential backoff state for 429 responses
    private var consecutiveRateLimitHits = 0
    private let maxBackoffInterval: TimeInterval = 300 // 5 minutes max

    private init() {}

    func fetchUsage(accessToken: String) async throws -> UsageData {
        // Rate limiting check
        if let lastRequest = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastRequest)
            if elapsed < minimumRequestInterval {
                let waitTime = minimumRequestInterval - elapsed
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
        lastRequestTime = Date()

        guard let url = URL(string: baseURL + usageEndpoint) else {
            throw UsageError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UsageError.networkError(URLError(.badServerResponse))
            }

            // Handle rate limiting with exponential backoff
            if httpResponse.statusCode == 429 {
                consecutiveRateLimitHits += 1
                let backoffInterval = min(
                    pow(2.0, Double(consecutiveRateLimitHits)) * minimumRequestInterval,
                    maxBackoffInterval
                )
                throw UsageError.apiError(
                    statusCode: 429,
                    message: "Rate limited. Retry after \(Int(backoffInterval)) seconds."
                )
            }

            // Reset backoff counter on successful response
            consecutiveRateLimitHits = 0

            guard (200...299).contains(httpResponse.statusCode) else {
                throw UsageError.apiError(statusCode: httpResponse.statusCode, message: nil)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let usage = try decoder.decode(UsageData.self, from: data)

            // Validate response data
            try validateUsageData(usage)

            return usage
        } catch let error as DecodingError {
            throw UsageError.decodingError(error)
        } catch let error as UsageError {
            throw error
        } catch let error as ValidationError {
            throw UsageError.decodingError(error)
        } catch {
            throw UsageError.networkError(error)
        }
    }

    /// Validates that usage data values are within expected ranges
    private func validateUsageData(_ usage: UsageData) throws {
        // Utilization should be between 0 and 100
        guard (0...100).contains(usage.fiveHour.utilization) else {
            throw ValidationError.invalidUtilizationRange(
                field: "five_hour.utilization",
                value: usage.fiveHour.utilization
            )
        }

        guard (0...100).contains(usage.sevenDay.utilization) else {
            throw ValidationError.invalidUtilizationRange(
                field: "seven_day.utilization",
                value: usage.sevenDay.utilization
            )
        }

        // Note: Reset dates are not validated as they may be in the past
        // if the user has hit their limit. They're just for display purposes.
    }

    /// Resets rate limit backoff state (call after successful credential refresh)
    func resetBackoffState() {
        consecutiveRateLimitHits = 0
        lastRequestTime = nil
    }
}
