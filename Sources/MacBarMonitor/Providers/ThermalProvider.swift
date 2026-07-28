import Foundation

// MARK: - Live Thermal Provider

struct LiveThermalProvider: ThermalProviding {
    private let hid: IOKitHIDProviding

    init(hid: IOKitHIDProviding = LiveIOKitHID()) {
        self.hid = hid
    }

    func readThermal() async -> MetricResult<ThermalReading> {
        let state = ProcessInfo.processInfo.thermalState
        let mapped: ThermalState
        switch state {
        case .nominal: mapped = .nominal
        case .fair: mapped = .fair
        case .serious: mapped = .serious
        case .critical: mapped = .critical
        @unknown default: mapped = .nominal
        }

        // Read actual temperature via IOKit HID sensors
        let temperatureCelsius: Double?
        if #available(macOS 12.0, *) {
            temperatureCelsius = hid.readTemperature()
        } else {
            temperatureCelsius = nil
        }

        return .available(ThermalReading(state: mapped, temperatureCelsius: temperatureCelsius))
    }
}

// MARK: - Testable Thermal Provider

struct TestableThermalProvider: ThermalProviding {
    let result: MetricResult<ThermalReading>

    func readThermal() async -> MetricResult<ThermalReading> {
        result
    }
}
