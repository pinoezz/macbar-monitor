import SwiftUI

@MainActor
final class MonitorStore: ObservableObject {
    @Published private(set) var snapshot = SystemSnapshot()
    @Published private(set) var selectedMetrics: Set<MetricKey>

    let settingsStore: SettingsStore
    private let providers: AllProviders
    private var refreshTask: Task<Void, Never>?

    init(
        providers: AllProviders = .live,
        settingsStore: SettingsStore = SettingsStore()
    ) {
        self.providers = providers
        self.settingsStore = settingsStore
        self.selectedMetrics = settingsStore.selectedMetrics
    }

    // Legacy single-metric accessor
    var selectedMetric: MetricKey {
        selectedMetrics.first ?? .cpu
    }

    func startMonitoring() {
        Task { @MainActor in
            await refresh()
            scheduleRefresh()
        }
    }

    func stopMonitoring() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func addMetric(_ metric: MetricKey) {
        selectedMetrics.insert(metric)
        settingsStore.selectedMetrics = selectedMetrics
    }

    func removeMetric(_ metric: MetricKey) {
        // Don't allow removing the last metric
        guard selectedMetrics.count > 1 else { return }
        selectedMetrics.remove(metric)
        settingsStore.selectedMetrics = selectedMetrics
    }

    func selectMetric(_ metric: MetricKey) {
        selectedMetrics = [metric]
        settingsStore.selectedMetrics = selectedMetrics
    }

    func setRefreshInterval(_ interval: TimeInterval) {
        settingsStore.refreshInterval = interval
        scheduleRefresh()
    }

    /// Build the concatenated menu bar display text for all selected metrics.
    func menuBarDisplayText() -> String {
        let orderedKeys = MetricKey.allCases.filter { selectedMetrics.contains($0) }
        let parts = orderedKeys.map { key -> String in
            let label = key.menuBarLabel
            let value = snapshot.value(for: key)
            return "\(label) \(value)"
        }
        return parts.joined(separator: "  ")
    }

    /// Build structured display data (label + value pairs) for the stacked status bar view.
    func menuBarDisplayData() -> [(label: String, value: String)] {
        let orderedKeys = MetricKey.allCases.filter { selectedMetrics.contains($0) }
        return orderedKeys.map { key in
            (label: key.menuBarLabel, value: snapshot.value(for: key))
        }
    }

    private func scheduleRefresh() {
        refreshTask?.cancel()
        let interval = settingsStore.refreshInterval
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await self?.refresh()
            }
        }
    }

    private func refresh() async {
        let p = providers
        // Sample network counters atomically before reading rates
        p.network.sample()

        async let c = p.cpu.readCPU()
        async let m = p.memory.readMemory()
        async let s = p.swap.readSwap()
        async let t = p.thermal.readThermal()
        async let b = p.battery.readBattery()
        async let nu = p.network.readNetworkUp()
        async let nd = p.network.readNetworkDown()
        async let dr = p.disk.readDiskReadSpeed()
        async let dw = p.disk.readDiskWriteSpeed()
        async let df = p.disk.readDiskCapacity()

        let (cpuR, memR, swapR, thermR, battR, netUpR, netDownR, dReadR, dWriteR, dFreeR) =
            await (c, m, s, t, b, nu, nd, dr, dw, df)

        self.snapshot = SystemSnapshot(
            cpu: cpuR, memory: memR, swap: swapR, thermal: thermR, battery: battR,
            networkUp: netUpR, networkDown: netDownR,
            diskRead: dReadR, diskWrite: dWriteR, diskFree: dFreeR
        )
    }
}
