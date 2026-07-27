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
        var lastRxRate: UInt64 = 0
        var lastTxRate: UInt64 = 0
    }

    init(source: any NetworkSampleSource = LiveNetworkSampleSource()) {
        self.source = source
        self.state = OSAllocatedUnfairLock(initialState: NetworkState())
    }

    /// Sample network counters and calculate rates atomically.
    /// Must be called once per refresh cycle, before readNetworkUp/Down.
    func sample() {
        guard let counters = source.readNetworkCounters() else { return }
        let now = Date()

        state.withLock { s in
            guard let prevRx = s.previousRx,
                  let prevTx = s.previousTx,
                  let prevTime = s.previousTimestamp else {
                // First sample — store baseline
                s.previousRx = counters.rxBytes
                s.previousTx = counters.txBytes
                s.previousTimestamp = now
                s.lastRxRate = 0
                s.lastTxRate = 0
                return
            }

            let elapsed = now.timeIntervalSince(prevTime)
            guard elapsed > 0.1 else { return } // Skip if less than 100ms

            let rxDelta = counters.rxBytes >= prevRx ? counters.rxBytes - prevRx : 0
            let txDelta = counters.txBytes >= prevTx ? counters.txBytes - prevTx : 0

            s.lastRxRate = UInt64(Double(rxDelta) / elapsed)
            s.lastTxRate = UInt64(Double(txDelta) / elapsed)

            // Update ALL counters and timestamp atomically
            s.previousRx = counters.rxBytes
            s.previousTx = counters.txBytes
            s.previousTimestamp = now
        }
    }

    func readNetworkUp() async -> MetricResult<NetworkMetric> {
        let rate = state.withLock { $0.lastTxRate }
        guard state.withLock({ $0.previousTimestamp != nil }) else {
            return .unavailable("First sample")
        }
        return .available(NetworkMetric(bytesPerSecond: rate))
    }

    func readNetworkDown() async -> MetricResult<NetworkMetric> {
        let rate = state.withLock { $0.lastRxRate }
        guard state.withLock({ $0.previousTimestamp != nil }) else {
            return .unavailable("First sample")
        }
        return .available(NetworkMetric(bytesPerSecond: rate))
    }
}

// MARK: - Testable Network Provider

struct TestableNetworkProvider: NetworkProviding {
    let upResult: MetricResult<NetworkMetric>
    let downResult: MetricResult<NetworkMetric>

    func sample() {}
    func readNetworkUp() async -> MetricResult<NetworkMetric> { upResult }
    func readNetworkDown() async -> MetricResult<NetworkMetric> { downResult }
}
