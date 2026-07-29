import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: MonitorStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Menu Bar Metrics Section
                settingsSection(title: "Menu Bar Display") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Select metrics to show in the menu bar:")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        ForEach(MetricKey.allCases) { metric in
                            Toggle(isOn: Binding(
                                get: { store.selectedMetrics.contains(metric) },
                                set: { isOn in
                                    if isOn {
                                        store.addMetric(metric)
                                    } else {
                                        store.removeMetric(metric)
                                    }
                                }
                            )) {
                                HStack(spacing: 6) {
                                    Image(systemName: iconForMetric(metric))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 14)
                                    Text(metric.displayName)
                                        .font(.system(size: 12))
                                }
                            }
                            .toggleStyle(.checkbox)
                        }
                    }
                }

                // Refresh Rate Section
                settingsSection(title: "Refresh Rate") {
                    Picker("Interval", selection: Binding(
                        get: { store.settingsStore.refreshInterval },
                        set: { store.setRefreshInterval($0) }
                    )) {
                        Text("1 second").tag(1.0)
                        Text("2 seconds").tag(2.0)
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                // Launch at Login Section
                settingsSection(title: "General") {
                    Toggle("Launch at Login", isOn: Binding(
                        get: { store.settingsStore.launchAtLogin },
                        set: { store.settingsStore.launchAtLogin = $0 }
                    ))
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
                }

                // Tutorial Section
                settingsSection(title: "Help") {
                    Button {
                        reopenOnboarding()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 11))
                            Text("Show Tutorial")
                                .font(.system(size: 12))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .accessibilityLabel("Show onboarding tutorial")
                }

                // Version
                HStack {
                    Spacer()
                    Text("MacBar Monitor v2.2.1")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
            .padding(16)
        }
        .frame(width: 268, height: 380)
    }

    // MARK: - Settings Section Helper

    @ViewBuilder
    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.04))
            )
        }
    }

    private func reopenOnboarding() {
        // Dismiss the popover first, then show onboarding via notification
        NotificationCenter.default.post(name: .dismissPopover, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(name: .showOnboarding, object: nil)
        }
    }

    private func iconForMetric(_ metric: MetricKey) -> String {
        switch metric {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .swap: return "arrow.triangle.swap"
        case .thermal: return "thermometer.medium"
        case .battery: return "battery.75"
        case .networkUp: return "arrow.up.circle"
        case .networkDown: return "arrow.down.circle"
        case .diskRead: return "arrow.up.doc"
        case .diskWrite: return "arrow.down.doc"
        case .diskFree: return "internaldrive"
        }
    }
}
