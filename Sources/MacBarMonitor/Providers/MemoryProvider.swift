import Foundation

// MARK: - Live Memory Provider

struct LiveMemoryProvider: MemoryProviding {
    private let source: any MemorySampleSource

    init(source: any MemorySampleSource = LiveMemorySampleSource()) {
        self.source = source
    }

    func readMemory() async -> MetricResult<MemoryMetric> {
        guard let info = source.readMemoryInfo() else {
            return .unavailable("Failed to read memory info")
        }
        let usedBytes = info.active + info.wired
        let totalPhysical = info.active + info.inactive + info.wired + info.free
        guard totalPhysical > 0 else {
            return .unavailable("Zero total physical memory")
        }
        return .available(MemoryMetric(usedBytes: usedBytes, totalBytes: totalPhysical))
    }
}

// MARK: - Testable Memory Provider

struct TestableMemoryProvider: MemoryProviding {
    let result: MetricResult<MemoryMetric>

    func readMemory() async -> MetricResult<MemoryMetric> {
        result
    }
}
