import Foundation

// MARK: - Provider Protocols

protocol CPUProviding: Sendable {
    func readCPU() async -> MetricResult<CPUMetric>
}

protocol MemoryProviding: Sendable {
    func readMemory() async -> MetricResult<MemoryMetric>
}

protocol SwapProviding: Sendable {
    func readSwap() async -> MetricResult<SwapMetric>
}

protocol ThermalProviding: Sendable {
    func readThermal() async -> MetricResult<ThermalState>
}

protocol BatteryProviding: Sendable {
    func readBattery() async -> MetricResult<BatteryMetric>
}

protocol NetworkProviding: Sendable {
    func readNetworkUp() async -> MetricResult<NetworkMetric>
    func readNetworkDown() async -> MetricResult<NetworkMetric>
}

protocol DiskProviding: Sendable {
    func readDiskReadSpeed() async -> MetricResult<DiskSpeedMetric>
    func readDiskWriteSpeed() async -> MetricResult<DiskSpeedMetric>
    func readDiskCapacity() async -> MetricResult<DiskCapacityMetric>
}

// MARK: - Composite Provider

struct AllProviders: Sendable {
    let cpu: any CPUProviding
    let memory: any MemoryProviding
    let swap: any SwapProviding
    let thermal: any ThermalProviding
    let battery: any BatteryProviding
    let network: any NetworkProviding
    let disk: any DiskProviding

    static var live: AllProviders {
        AllProviders(
            cpu: LiveCPUProvider(),
            memory: LiveMemoryProvider(),
            swap: LiveSwapProvider(),
            thermal: LiveThermalProvider(),
            battery: LiveBatteryProvider(),
            network: LiveNetworkProvider(),
            disk: LiveDiskProvider()
        )
    }
}
