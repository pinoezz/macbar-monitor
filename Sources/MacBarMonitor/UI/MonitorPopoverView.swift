import SwiftUI

struct MonitorPopoverView: View {
    @ObservedObject var store: MonitorStore
    @State private var showingSettings = false

    var body: some View {
        if showingSettings {
            settingsPanel
        } else {
            metricsPanel
        }
    }

    // MARK: - Metrics Panel

    private var metricsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gauge.medium")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("MacBar Monitor")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("v2.0.4")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 12)

            // Metric Rows
            ScrollView {
                VStack(spacing: 2) {
                    cpuRow
                    memoryRow
                    swapRow
                    thermalRow
                    batteryRow
                    networkUpRow
                    networkDownRow
                    diskFreeRow
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }

            Divider()
                .padding(.horizontal, 12)

            // Footer
            HStack {
                Button {
                    showingSettings = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gear")
                            .font(.system(size: 11))
                        Text("Settings")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    NSApp.terminate(nil)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 11))
                        Text("Quit")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 300)
    }

    // MARK: - Settings Panel

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Settings Header with Back
            HStack {
                Button {
                    showingSettings = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Settings")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()
                // Invisible spacer for centering
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 12))
                }
                .hidden()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 12)

            SettingsView(store: store)
        }
        .frame(width: 300)
    }

    // MARK: - Metric Rows

    private var cpuRow: some View {
        Group {
            switch store.snapshot.cpu {
            case .available(let m):
                MetricRowView(
                    icon: "cpu",
                    label: "CPU",
                    value: String(format: "%.0f%%", m.utilizationPercent),
                    progress: m.utilizationPercent / 100.0,
                    color: colorForPercent(m.utilizationPercent)
                )
            case .unavailable:
                MetricRowView(icon: "cpu", label: "CPU", value: "—", progress: nil, color: .secondary)
            }
        }
    }

    private var memoryRow: some View {
        Group {
            switch store.snapshot.memory {
            case .available(let m):
                let usedGB = String(format: "%.1f", Double(m.usedBytes) / 1_073_741_824)
                let totalGB = String(format: "%.0f", Double(m.totalBytes) / 1_073_741_824)
                MetricRowView(
                    icon: "memorychip",
                    label: "Memory",
                    value: "\(usedGB) / \(totalGB) GB",
                    progress: m.utilizationPercent / 100.0,
                    color: colorForPercent(m.utilizationPercent)
                )
            case .unavailable:
                MetricRowView(icon: "memorychip", label: "Memory", value: "—", progress: nil, color: .secondary)
            }
        }
    }

    private var swapRow: some View {
        Group {
            switch store.snapshot.swap {
            case .available(let m):
                let usedGB = String(format: "%.1f", Double(m.usedBytes) / 1_073_741_824)
                let totalGB = String(format: "%.1f", Double(m.totalBytes) / 1_073_741_824)
                let pct = m.utilizationPercent ?? 0
                if m.totalBytes > 0 {
                    MetricRowView(
                        icon: "arrow.triangle.swap",
                        label: "Swap",
                        value: "\(usedGB) / \(totalGB) GB",
                        progress: pct / 100.0,
                        color: colorForPercent(pct)
                    )
                } else {
                    MetricRowView(
                        icon: "arrow.triangle.swap",
                        label: "Swap",
                        value: "\(usedGB) GB used",
                        progress: nil,
                        color: .secondary
                    )
                }
            case .unavailable:
                MetricRowView(icon: "arrow.triangle.swap", label: "Swap", value: "—", progress: nil, color: .secondary)
            }
        }
    }

    private var thermalRow: some View {
        Group {
            switch store.snapshot.thermal {
            case .available(let state):
                MetricRowView(
                    icon: "thermometer.medium",
                    label: "Thermal",
                    value: "",
                    progress: nil,
                    color: colorForThermal(state),
                    badge: state.displayName,
                    badgeColor: colorForThermal(state)
                )
            case .unavailable:
                MetricRowView(icon: "thermometer.medium", label: "Thermal", value: "—", progress: nil, color: .secondary)
            }
        }
    }

    private var batteryRow: some View {
        Group {
            switch store.snapshot.battery {
            case .available(let m):
                let icon = m.isCharging ? "battery.100.bolt" : batteryIcon(for: m.chargePercent)
                let chargingText = m.isCharging ? " ⚡" : ""
                MetricRowView(
                    icon: icon,
                    label: "Battery",
                    value: "\(Int(m.chargePercent))%\(chargingText)",
                    progress: m.chargePercent / 100.0,
                    color: colorForBattery(m.chargePercent)
                )
            case .unavailable:
                MetricRowView(icon: "battery.0", label: "Battery", value: "—", progress: nil, color: .secondary)
            }
        }
    }

    private var networkUpRow: some View {
        Group {
            switch store.snapshot.networkUp {
            case .available(let m):
                MetricRowView(
                    icon: "arrow.up.circle",
                    label: "Upload",
                    value: MetricCalculations.formatBytesPerSecond(m.bytesPerSecond),
                    progress: nil,
                    color: .blue
                )
            case .unavailable:
                MetricRowView(icon: "arrow.up.circle", label: "Upload", value: "—", progress: nil, color: .secondary)
            }
        }
    }

    private var networkDownRow: some View {
        Group {
            switch store.snapshot.networkDown {
            case .available(let m):
                MetricRowView(
                    icon: "arrow.down.circle",
                    label: "Download",
                    value: MetricCalculations.formatBytesPerSecond(m.bytesPerSecond),
                    progress: nil,
                    color: .cyan
                )
            case .unavailable:
                MetricRowView(icon: "arrow.down.circle", label: "Download", value: "—", progress: nil, color: .secondary)
            }
        }
    }

    private var diskFreeRow: some View {
        Group {
            switch store.snapshot.diskFree {
            case .available(let m):
                let freeGB = String(format: "%.0f", Double(m.freeBytes) / 1_073_741_824)
                let totalGB = String(format: "%.0f", Double(m.totalBytes) / 1_073_741_824)
                MetricRowView(
                    icon: "internaldrive",
                    label: "Disk",
                    value: "\(freeGB) / \(totalGB) GB free",
                    progress: m.utilizationPercent / 100.0,
                    color: colorForPercent(m.utilizationPercent)
                )
            case .unavailable:
                MetricRowView(icon: "internaldrive", label: "Disk", value: "—", progress: nil, color: .secondary)
            }
        }
    }

    // MARK: - Color Helpers

    private func colorForPercent(_ percent: Double) -> Color {
        switch percent {
        case 0..<50: return .green
        case 50..<75: return .yellow
        case 75..<90: return .orange
        default: return .red
        }
    }

    private func colorForThermal(_ state: ThermalState) -> Color {
        switch state {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        }
    }

    private func colorForBattery(_ percent: Double) -> Color {
        switch percent {
        case 0..<20: return .red
        case 20..<50: return .orange
        default: return .green
        }
    }

    private func batteryIcon(for percent: Double) -> String {
        switch percent {
        case 0..<13: return "battery.0"
        case 13..<38: return "battery.25"
        case 38..<63: return "battery.50"
        case 63..<88: return "battery.75"
        default: return "battery.100"
        }
    }
}
