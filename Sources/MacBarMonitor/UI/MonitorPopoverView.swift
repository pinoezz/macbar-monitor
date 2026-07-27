import SwiftUI

struct MonitorPopoverView: View {
    @ObservedObject var store: MonitorStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MacBar Monitor")
                .font(.headline)
                .padding(.bottom, 4)

            Divider()

            ForEach(MetricKey.allCases) { metric in
                HStack {
                    Text(metric.displayName)
                        .frame(width: 80, alignment: .leading)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(store.snapshot.value(for: metric))
                        .font(.system(.body, design: .monospaced))
                }
                .padding(.vertical, 2)
            }

            Divider()

            NavigationLink(destination: SettingsView(store: store)) {
                Label("Settings", systemImage: "gear")
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding()
        .frame(width: 320)
    }
}
