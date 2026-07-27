import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: MonitorStore

    var body: some View {
        Form {
            Section("Menu Bar Metric") {
                Picker("Display", selection: Binding(
                    get: { store.selectedMetric },
                    set: { store.selectMetric($0) }
                )) {
                    ForEach(MetricKey.allCases) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Refresh Rate") {
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
            }

            Section {
                Button {
                    reopenOnboarding()
                } label: {
                    Label("Show Tutorial", systemImage: "questionmark.circle")
                }
                .accessibilityLabel("Show onboarding tutorial")
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 300, height: 240)
    }

    private func reopenOnboarding() {
        guard let delegate = NSApp.delegate as? AppDelegate else { return }
        delegate.showOnboarding(forced: true)
    }
}
