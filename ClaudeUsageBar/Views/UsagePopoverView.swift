import SwiftUI

struct UsagePopoverView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.error {
                ErrorStateView(error: error) {
                    Task { await viewModel.retryAfterError() }
                }
            } else if viewModel.usageData != nil {
                usageContentView
            } else {
                // Fallback: show loading if no other state
                LoadingView()
            }

            Divider()

            // Footer
            footerView
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
        .padding(.bottom, 36)
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ClaudeWatch")
                    .font(.headline)
                Text("\(viewModel.subscriptionType) \u{2022} \(viewModel.rateLimitTier)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Button {
                    Task { await viewModel.refreshUsage() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 12)
    }

    private var usageContentView: some View {
        VStack(spacing: 16) {
            // Primary gauge
            UsageGaugeView(
                value: viewModel.primaryUsagePercent,
                color: viewModel.usageColor
            )
            .frame(height: 100)

            // Detail rows
            VStack(spacing: 8) {
                UsageDetailRow(
                    title: "5-Hour Window",
                    percentage: viewModel.fiveHourUsagePercent,
                    resetTime: viewModel.fiveHourResetTime
                )

                UsageDetailRow(
                    title: "7-Day Window",
                    percentage: viewModel.sevenDayUsagePercent,
                    resetTime: viewModel.sevenDayResetTime
                )
            }
        }
        .padding(.vertical, 12)
    }

    private var footerView: some View {
        VStack(spacing: 8) {
            // Display mode picker
            HStack {
                Text("Show in menu bar:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Picker("", selection: $viewModel.currentDisplayMode) {
                    ForEach(DisplayMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 130)
            }

            // Last updated and quit
            HStack {
                if let lastUpdated = viewModel.lastUpdated {
                    Text("Updated \(lastUpdated, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 12)
    }
}
