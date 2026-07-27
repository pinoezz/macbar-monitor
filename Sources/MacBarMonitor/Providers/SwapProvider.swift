import Foundation

// MARK: - Live Swap Provider

struct LiveSwapProvider: SwapProviding {
    func readSwap() async -> MetricResult<SwapMetric> {
        // sysctl vm.swapusage is not formally documented by Apple.
        // We parse the human-readable output as a best-effort approach.
        var size: size_t = 0
        guard sysctlbyname("vm.swapusage", nil, &size, nil, 0) == 0, size > 0 else {
            return .unavailable("swapusage not available")
        }

        var data = [CChar](repeating: 0, count: size)
        guard sysctlbyname("vm.swapusage", &data, &size, nil, 0) == 0 else {
            return .unavailable("Failed to read swapusage")
        }

        let output = String(cString: data)
        // Parse: "total = 6144.00M  used = 4096.00M  free = 2048.00M"
        guard let totalRange = output.range(of: #"total = (\d+\.?\d*)M"#, options: .regularExpression),
              let usedRange = output.range(of: #"used = (\d+\.?\d*)M"#, options: .regularExpression)
        else {
            return .unavailable("Could not parse swap output")
        }

        let totalStr = output[totalRange].replacingOccurrences(of: "total = ", with: "").replacingOccurrences(of: "M", with: "")
        let usedStr = output[usedRange].replacingOccurrences(of: "used = ", with: "").replacingOccurrences(of: "M", with: "")

        guard let totalMB = Double(totalStr), let usedMB = Double(usedStr) else {
            return .unavailable("Invalid swap values")
        }

        let totalBytes = UInt64(totalMB * 1024 * 1024)
        let usedBytes = UInt64(usedMB * 1024 * 1024)

        guard totalBytes > 0 else {
            return .unavailable("Zero total swap")
        }

        return .available(SwapMetric(usedBytes: usedBytes, totalBytes: totalBytes))
    }
}

// MARK: - Testable Swap Provider

struct TestableSwapProvider: SwapProviding {
    let result: MetricResult<SwapMetric>

    func readSwap() async -> MetricResult<SwapMetric> {
        result
    }
}
