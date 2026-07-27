import Foundation
import os

// MARK: - Live CPU Provider

final class LiveCPUProvider: CPUProviding, Sendable {
    private let source: any CPUSampleSource
    private let state: OSAllocatedUnfairLock<CPUState>

    struct CPUState {
        var previousTotal: UInt64?
        var previousIdle: UInt64?
    }

    init(source: any CPUSampleSource = LiveCPUSampleSource()) {
        self.source = source
        self.state = OSAllocatedUnfairLock(initialState: CPUState())
    }

    func readCPU() async -> MetricResult<CPUMetric> {
        guard let ticks = source.readCPUTicks() else {
            return .unavailable("Failed to read CPU ticks")
        }
        let total = ticks.total
        let idle = ticks.idle

        return state.withLock { s in
            guard let prevTotal = s.previousTotal, let prevIdle = s.previousIdle,
                  total > prevTotal else {
                s.previousTotal = total
                s.previousIdle = idle
                return .unavailable("First sample")
            }

            let deltaTotal = total - prevTotal
            let deltaIdle = idle - prevIdle
            s.previousTotal = total
            s.previousIdle = idle

            guard deltaTotal > 0 else {
                return .unavailable("Zero delta")
            }

            let usage = Double(deltaTotal - deltaIdle) / Double(deltaTotal) * 100.0
            return .available(CPUMetric(utilizationPercent: MetricCalculations.clampPercent(usage)))
        }
    }
}

// MARK: - Testable CPU Provider

struct TestableCPUProvider: CPUProviding {
    let result: MetricResult<CPUMetric>

    func readCPU() async -> MetricResult<CPUMetric> {
        result
    }
}
