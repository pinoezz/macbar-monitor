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
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    static func formatBytesPerSecond(_ bytesPerSecond: UInt64) -> String {
        formatBytes(bytesPerSecond) + "/s"
    }

    // MARK: - Elapsed Time Guard

    static func validElapsedSeconds(_ elapsed: TimeInterval) -> Bool {
        elapsed > 0
    }
}
