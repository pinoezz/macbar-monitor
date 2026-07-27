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

        // Use ProcessInfo for accurate total physical memory
        // (Mach VM stats pages don't include compressed/speculative pages)
        let totalPhysical = UInt64(ProcessInfo.processInfo.physicalMemory)

        // Used = active + wired + compressed (matches Activity Monitor's "Memory Used")
        let usedBytes = info.active + info.wired + info.compressed

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
