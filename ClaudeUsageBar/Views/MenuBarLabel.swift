import SwiftUI
import AppKit

struct MenuBarLabel: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(viewModel.usageColor, .primary)

            Text(viewModel.menuBarTitle)
                .font(.system(.caption, design: .monospaced))
                .monospacedDigit()
        }
        .onAppear {
            updateStatusItemTooltip()
        }
        .onChange(of: viewModel.displayMode) { _ in
            updateStatusItemTooltip()
        }
    }

    private func updateStatusItemTooltip() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for window in NSApp.windows {
                guard let statusItem = window.value(forKey: "statusItem") as? NSStatusItem else {
                    continue
                }
                statusItem.button?.toolTip = tooltipText
                return
            }
        }
    }

    private var tooltipText: String {
        let mode = viewModel.currentDisplayMode
        switch mode {
        case .maximum:
            return "Showing: Maximum of 5-hour and 7-day"
        case .fiveHour:
            return "Showing: 5-Hour Window"
        case .sevenDay:
            return "Showing: 7-Day Window"
        }
    }

    private var iconName: String {
        if viewModel.error != nil {
            return "exclamationmark.triangle.fill"
        }

        let percent = viewModel.primaryUsagePercent
        switch percent {
        case 0..<25: return "gauge.with.dots.needle.0percent"
        case 25..<50: return "gauge.with.dots.needle.33percent"
        case 50..<75: return "gauge.with.dots.needle.50percent"
        case 75..<100: return "gauge.with.dots.needle.67percent"
        default: return "gauge.with.dots.needle.100percent"
        }
    }
}
