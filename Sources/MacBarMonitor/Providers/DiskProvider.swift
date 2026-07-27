import Foundation

// MARK: - Live Disk Provider

struct LiveDiskProvider: DiskProviding {
    func readDiskReadSpeed() async -> MetricResult<DiskSpeedMetric> {
        // No stable documented API for aggregate disk throughput on Apple Silicon.
        // This remains unavailable in the MVP; the provider boundary is ready for
        // a future documented source (e.g., a sysctl or IOKit counter if one becomes stable).
        .unavailable("Disk speed not available via public APIs")
    }

    func readDiskWriteSpeed() async -> MetricResult<DiskSpeedMetric> {
        .unavailable("Disk speed not available via public APIs")
    }

    func readDiskCapacity() async -> MetricResult<DiskCapacityMetric> {
        let url = URL(fileURLWithPath: "/")
        do {
            let values = try url.resourceValues(
                forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]
            )
            guard let free = values.volumeAvailableCapacityForImportantUsage,
                  let total = values.volumeTotalCapacity
            else {
                return .unavailable("Cannot read volume capacity")
            }
            return .available(DiskCapacityMetric(
                freeBytes: UInt64(free),
                totalBytes: UInt64(total)
            ))
        } catch {
            return .unavailable("Volume capacity error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Testable Disk Provider

struct TestableDiskProvider: DiskProviding {
    let readSpeedResult: MetricResult<DiskSpeedMetric>
    let writeSpeedResult: MetricResult<DiskSpeedMetric>
    let capacityResult: MetricResult<DiskCapacityMetric>

    init(
        readSpeed: MetricResult<DiskSpeedMetric> = .unavailable("Test"),
        writeSpeed: MetricResult<DiskSpeedMetric> = .unavailable("Test"),
        capacity: MetricResult<DiskCapacityMetric> = .unavailable("Test")
    ) {
        self.readSpeedResult = readSpeed
        self.writeSpeedResult = writeSpeed
        self.capacityResult = capacity
    }

    func readDiskReadSpeed() async -> MetricResult<DiskSpeedMetric> { readSpeedResult }
    func readDiskWriteSpeed() async -> MetricResult<DiskSpeedMetric> { writeSpeedResult }
    func readDiskCapacity() async -> MetricResult<DiskCapacityMetric> { capacityResult }
}
