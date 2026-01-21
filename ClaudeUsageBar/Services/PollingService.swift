import Foundation
import Combine

final class PollingService: ObservableObject {
    @Published private(set) var isPolling = false

    private var timer: Timer?
    var pollInterval: TimeInterval = 300 // 5 minutes default
    var onPoll: (() async -> Void)?

    deinit {
        stop()
    }

    func start() {
        guard !isPolling else { return }
        isPolling = true

        // Fire immediately
        Task {
            await onPoll?()
        }

        // Schedule periodic updates on common RunLoop mode for UI responsiveness
        timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.onPoll?()
            }
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isPolling = false
    }

    func refreshNow() async {
        await onPoll?()
    }
}
