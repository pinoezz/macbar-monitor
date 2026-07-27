import Foundation

// MARK: - Live Swap Provider

struct LiveSwapProvider: SwapProviding {
    func readSwap() async -> MetricResult<SwapMetric> {
        // vm.swapusage returns an xsw_usage struct, not a string
        var swapUsage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size

        guard sysctlbyname("vm.swapusage", &swapUsage, &size, nil, 0) == 0 else {
            return .unavailable("Failed to read swapusage")
        }

        let totalBytes = swapUsage.xsu_total
        let usedBytes = swapUsage.xsu_used

        // If total swap is 0, system might not have swap configured
        // But still report it — show "0 / 0" rather than unavailable
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
