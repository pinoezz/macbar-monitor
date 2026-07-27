import SwiftUI

@MainActor
final class MonitorStore: ObservableObject {
    @Published private(set) var snapshot = SystemSnapshot()
    @Published private(set) var selectedMetric: MetricKey

    let settingsStore: SettingsStore
    private let providers: AllProviders
    private var refreshTask: Task<Void, Never>?

    init(
        providers: AllProviders = .live,
        settingsStore: SettingsStore = SettingsStore()
    ) {
        self.providers = providers
        self.settingsStore = settingsStore
        self.selectedMetric = settingsStore.selectedMetric
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

    func selectMetric(_ metric: MetricKey) {
        selectedMetric = metric
        settingsStore.selectedMetric = metric
    }

    func setRefreshInterval(_ interval: TimeInterval) {
        settingsStore.refreshInterval = interval
        scheduleRefresh()
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
