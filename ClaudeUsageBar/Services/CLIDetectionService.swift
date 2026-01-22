import Foundation

/// Service for detecting Claude Code CLI installation
/// Security: Only uses hardcoded paths and commands - no user input
final class CLIDetectionService {
    static let shared = CLIDetectionService()

    /// Known installation paths for Claude CLI
    /// These are the standard locations where npm installs global packages
    private let knownPaths: [String] = [
        "/usr/local/bin/claude",
        "/opt/homebrew/bin/claude",
        "/usr/bin/claude",
        "~/.npm-global/bin/claude"
    ]

    private init() {}

    /// Checks if Claude CLI is installed
    /// Returns true if CLI is found in known paths or via `which` command
    func isCLIInstalled() -> Bool {
        // First check known paths directly (faster)
        for path in knownPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if FileManager.default.isExecutableFile(atPath: expandedPath) {
                return true
            }
        }

        // Fallback: use `which` command
        // Security: Hardcoded executable path and static argument - no user input
        return checkWithWhichCommand()
    }

    /// Uses /usr/bin/which to find claude in PATH
    /// Security: Uses hardcoded executable and static argument only
    private func checkWithWhichCommand() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["claude"]  // Static, hardcoded - no injection risk

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            // If `which` fails to run, assume CLI not found
            return false
        }
    }

    /// Gets the path to the Claude CLI if installed
    /// Returns nil if not found
    func getCLIPath() -> String? {
        // Check known paths first
        for path in knownPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if FileManager.default.isExecutableFile(atPath: expandedPath) {
                return expandedPath
            }
        }

        // Fallback: use `which` command to get path
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["claude"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    return path
                }
            }
        } catch {
            // Ignore errors
        }

        return nil
    }
}
