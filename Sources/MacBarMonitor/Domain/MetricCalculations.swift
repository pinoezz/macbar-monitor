import Foundation

enum MetricCalculations {

    // MARK: - Byte Rate Calculation

    static func calculateRate(
        currentBytes: UInt64,
        previousBytes: UInt64?,
        elapsedSeconds: TimeInterval
    ) -> UInt64? {
        guard elapsedSeconds > 0 else { return nil }
        guard let prev = previousBytes else { return nil }
        guard currentBytes >= prev else { return nil }
        let delta = currentBytes - prev
        return UInt64(Double(delta) / elapsedSeconds)
    }

    // MARK: - Percentage Clamping

    static func clampPercent(_ value: Double) -> Double {
        min(max(value, 0), 100)
    }

    // MARK: - Byte Formatting

    static func formatBytes(_ bytes: UInt64) -> String {
        let kb = 1_000.0
        let mb = 1_000_000.0
        let gb = 1_000_000_000.0
        let value = Double(bytes)

        if value >= gb {
            return String(format: "%.1f GB", value / gb)
        } else if value >= mb {
            return String(format: "%.1f MB", value / mb)
        } else if value >= kb {
            return String(format: "%.0f KB", value / kb)
        } else {
            return "\(bytes) B"
        }
    }

    static func formatBytesPerSecond(_ bytesPerSecond: UInt64) -> String {
        let kb = 1_000.0
        let mb = 1_000_000.0
        let gb = 1_000_000_000.0
        let value = Double(bytesPerSecond)

        if value >= gb {
            return String(format: "%.1f GB/s", value / gb)
        } else if value >= mb {
            return String(format: "%.1f MB/s", value / mb)
        } else if value >= kb {
            return String(format: "%.0f KB/s", value / kb)
        } else {
            return "\(bytesPerSecond) B/s"
        }
    }

    // MARK: - Elapsed Time Guard

    static func validElapsedSeconds(_ elapsed: TimeInterval) -> Bool {
        elapsed > 0
    }
}
