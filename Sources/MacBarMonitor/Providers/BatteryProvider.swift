import Foundation
import IOKit.ps

// MARK: - Live Battery Provider

struct LiveBatteryProvider: BatteryProviding {
    func readBattery() async -> MetricResult<BatteryMetric> {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any],
              let first = sources.first
        else {
            return .unavailable("No power source")
        }

        guard let info = IOPSGetPowerSourceDescription(snapshot, first as CFTypeRef)?.takeUnretainedValue() as? [String: Any]
        else {
            return .unavailable("Cannot read power source")
        }

        guard let capacity = info[kIOPSCurrentCapacityKey] as? Int,
              let maxCapacity = info[kIOPSMaxCapacityKey] as? Int,
              maxCapacity > 0
        else {
            return .unavailable("Invalid power data")
        }

        let isCharging = (info[kIOPSIsChargingKey] as? Bool) ?? false
        let chargePercent = Double(capacity) / Double(maxCapacity) * 100.0

        let timeToEmpty = info[kIOPSTimeToEmptyKey] as? Int
        let timeToFull = info[kIOPSTimeToFullChargeKey] as? Int

        return .available(BatteryMetric(
            chargePercent: MetricCalculations.clampPercent(chargePercent),
            isCharging: isCharging,
            timeToEmptyMinutes: timeToEmpty.flatMap { $0 > 0 ? $0 : nil },
            timeToFullMinutes: timeToFull.flatMap { $0 > 0 ? $0 : nil }
        ))
    }
}

// MARK: - Testable Battery Provider

struct TestableBatteryProvider: BatteryProviding {
    let result: MetricResult<BatteryMetric>

    func readBattery() async -> MetricResult<BatteryMetric> {
        result
    }
}
