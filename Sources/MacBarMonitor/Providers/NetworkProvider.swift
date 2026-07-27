import Foundation
import os

// MARK: - Live Network Provider

final class LiveNetworkProvider: NetworkProviding, Sendable {
    private let source: any NetworkSampleSource
    private let state: OSAllocatedUnfairLock<NetworkState>

    struct NetworkState {
        var previousRx: UInt64?
        var previousTx: UInt64?
        var previousTimestamp: Date?
    }

    init(source: any NetworkSampleSource = LiveNetworkSampleSource()) {
        self.source = source
        self.state = OSAllocatedUnfairLock(initialState: NetworkState())
    }

    func readNetworkUp() async -> MetricResult<NetworkMetric> {
        readRate(isTx: true)
    }

    func readNetworkDown() async -> MetricResult<NetworkMetric> {
        readRate(isTx: false)
    }

    private func readRate(isTx: Bool) -> MetricResult<NetworkMetric> {
        guard let counters = source.readNetworkCounters() else {
            return .unavailable("Failed to read network counters")
        }

        let current = isTx ? counters.txBytes : counters.rxBytes
        let now = Date()

        return state.withLock { s in
            let previous = isTx ? s.previousTx : s.previousRx

            guard let prev = previous, let prevTime = s.previousTimestamp else {
                s.previousRx = counters.rxBytes
                s.previousTx = counters.txBytes
                s.previousTimestamp = now
                return .unavailable("First sample")
            }

            let elapsed = now.timeIntervalSince(prevTime)
            guard elapsed > 0 else {
                return .unavailable("Zero elapsed time")
            }

            guard current >= prev else {
                s.previousRx = counters.rxBytes
                s.previousTx = counters.txBytes
                s.previousTimestamp = now
                return .unavailable("Counter reset")
            }

            let rate = UInt64(Double(current - prev) / elapsed)

            // Update stored values on first call per pair
            if isTx {
                s.previousTx = current
            } else {
                s.previousRx = current
            }
            s.previousTimestamp = now

            return .available(NetworkMetric(bytesPerSecond: rate))
        }
    }
}

// MARK: - Testable Network Provider

struct TestableNetworkProvider: NetworkProviding {
    let upResult: MetricResult<NetworkMetric>
    let downResult: MetricResult<NetworkMetric>

    func readNetworkUp() async -> MetricResult<NetworkMetric> { upResult }
    func readNetworkDown() async -> MetricResult<NetworkMetric> { downResult }
}
