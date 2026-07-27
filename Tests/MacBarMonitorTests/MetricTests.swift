import XCTest
@testable import MacBarMonitor

final class MetricTests: XCTestCase {

    // MARK: - calculateRate Tests

    func testCalculateRateWithValidInputs() {
        // Given
        let currentBytes: UInt64 = 1000
        let previousBytes: UInt64 = 500
        let elapsedSeconds: TimeInterval = 1.0

        // When
        let rate = MetricCalculations.calculateRate(
            currentBytes: currentBytes,
            previousBytes: previousBytes,
            elapsedSeconds: elapsedSeconds
        )

        // Then
        XCTAssertEqual(rate, 500)
    }

    func testCalculateRateWithZeroElapsedSeconds() {
        // Given
        let currentBytes: UInt64 = 1000
        let previousBytes: UInt64 = 500
        let elapsedSeconds: TimeInterval = 0

        // When
        let rate = MetricCalculations.calculateRate(
            currentBytes: currentBytes,
            previousBytes: previousBytes,
            elapsedSeconds: elapsedSeconds
        )

        // Then
        XCTAssertNil(rate)
    }

    func testCalculateRateWithNilPreviousBytes() {
        // Given
        let currentBytes: UInt64 = 1000
        let elapsedSeconds: TimeInterval = 1.0

        // When
        let rate = MetricCalculations.calculateRate(
            currentBytes: currentBytes,
            previousBytes: nil,
            elapsedSeconds: elapsedSeconds
        )

        // Then
        XCTAssertNil(rate)
    }

    func testCalculateRateWithDecreasedBytes() {
        // Given
        let currentBytes: UInt64 = 500
        let previousBytes: UInt64 = 1000
        let elapsedSeconds: TimeInterval = 1.0

        // When
        let rate = MetricCalculations.calculateRate(
            currentBytes: currentBytes,
            previousBytes: previousBytes,
            elapsedSeconds: elapsedSeconds
        )

        // Then
        XCTAssertNil(rate)
    }

    // MARK: - clampPercent Tests

    func testClampPercentWithinRange() {
        // Given
        let value: Double = 50.0

        // When
        let clamped = MetricCalculations.clampPercent(value)

        // Then
        XCTAssertEqual(clamped, 50.0)
    }

    func testClampPercentAboveMaximum() {
        // Given
        let value: Double = 150.0

        // When
        let clamped = MetricCalculations.clampPercent(value)

        // Then
        XCTAssertEqual(clamped, 100.0)
    }

    func testClampPercentBelowMinimum() {
        // Given
        let value: Double = -10.0

        // When
        let clamped = MetricCalculations.clampPercent(value)

        // Then
        XCTAssertEqual(clamped, 0.0)
    }

    func testClampPercentAtBoundaries() {
        // Given
        let lowerValue: Double = 0.0
        let upperValue: Double = 100.0

        // When
        let lowerClamped = MetricCalculations.clampPercent(lowerValue)
        let upperClamped = MetricCalculations.clampPercent(upperValue)

        // Then
        XCTAssertEqual(lowerClamped, 0.0)
        XCTAssertEqual(upperClamped, 100.0)
    }

    // MARK: - formatBytes Tests

    func testFormatBytesZero() {
        // Given
        let bytes: UInt64 = 0

        // When
        let formatted = MetricCalculations.formatBytes(bytes)

        // Then
        XCTAssertEqual(formatted, "0 bytes")
    }

    func testFormatBytesKilobytes() {
        // Given
        let bytes: UInt64 = 1024

        // When
        let formatted = MetricCalculations.formatBytes(bytes)

        // Then
        XCTAssertTrue(formatted.contains("KB"))
    }

    func testFormatBytesMegabytes() {
        // Given
        let bytes: UInt64 = 1_048_576

        // When
        let formatted = MetricCalculations.formatBytes(bytes)

        // Then
        XCTAssertTrue(formatted.contains("MB"))
    }

    func testFormatBytesGigabytes() {
        // Given
        let bytes: UInt64 = 1_073_741_824

        // When
        let formatted = MetricCalculations.formatBytes(bytes)

        // Then
        XCTAssertTrue(formatted.contains("GB"))
    }

    // MARK: - formatBytesPerSecond Tests

    func testFormatBytesPerSecond() {
        // Given
        let bytesPerSecond: UInt64 = 1_048_576

        // When
        let formatted = MetricCalculations.formatBytesPerSecond(bytesPerSecond)

        // Then
        XCTAssertTrue(formatted.hasSuffix("/s"))
        XCTAssertTrue(formatted.contains("MB"))
    }

    // MARK: - validElapsedSeconds Tests

    func testValidElapsedSecondsPositive() {
        // Given
        let elapsed: TimeInterval = 1.0

        // When
        let isValid = MetricCalculations.validElapsedSeconds(elapsed)

        // Then
        XCTAssertTrue(isValid)
    }

    func testValidElapsedSecondsZero() {
        // Given
        let elapsed: TimeInterval = 0

        // When
        let isValid = MetricCalculations.validElapsedSeconds(elapsed)

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidElapsedSecondsNegative() {
        // Given
        let elapsed: TimeInterval = -1.0

        // When
        let isValid = MetricCalculations.validElapsedSeconds(elapsed)

        // Then
        XCTAssertFalse(isValid)
    }

    // MARK: - MemoryMetric Tests

    func testMemoryMetricUtilization() {
        // Given
        let usedBytes: UInt64 = 4_000_000_000
        let totalBytes: UInt64 = 16_000_000_000

        // When
        let metric = MemoryMetric(usedBytes: usedBytes, totalBytes: totalBytes)

        // Then
        XCTAssertEqual(metric.utilizationPercent, 25.0, accuracy: 0.01)
    }

    func testMemoryMetricUtilizationWithZeroTotal() {
        // Given
        let usedBytes: UInt64 = 4_000_000_000
        let totalBytes: UInt64 = 0

        // When
        let metric = MemoryMetric(usedBytes: usedBytes, totalBytes: totalBytes)

        // Then
        XCTAssertEqual(metric.utilizationPercent, 0)
    }

    // MARK: - SwapMetric Tests

    func testSwapMetricUtilization() {
        // Given
        let usedBytes: UInt64 = 1_000_000_000
        let totalBytes: UInt64 = 4_000_000_000

        // When
        let metric = SwapMetric(usedBytes: usedBytes, totalBytes: totalBytes)

        // Then
        XCTAssertEqual(metric.utilizationPercent, 25.0, accuracy: 0.01)
    }

    func testSwapMetricUtilizationWithZeroTotal() {
        // Given
        let usedBytes: UInt64 = 1_000_000_000
        let totalBytes: UInt64 = 0

        // When
        let metric = SwapMetric(usedBytes: usedBytes, totalBytes: totalBytes)

        // Then
        XCTAssertNil(metric.utilizationPercent)
    }

    // MARK: - DiskCapacityMetric Tests

    func testDiskCapacityMetric() {
        // Given
        let freeBytes: UInt64 = 100_000_000_000
        let totalBytes: UInt64 = 500_000_000_000

        // When
        let metric = DiskCapacityMetric(freeBytes: freeBytes, totalBytes: totalBytes)

        // Then
        XCTAssertEqual(metric.usedBytes, 400_000_000_000)
        XCTAssertEqual(metric.utilizationPercent, 80.0, accuracy: 0.01)
    }

    func testDiskCapacityMetricWithZeroTotal() {
        // Given
        let freeBytes: UInt64 = 100_000_000_000
        let totalBytes: UInt64 = 0

        // When
        let metric = DiskCapacityMetric(freeBytes: freeBytes, totalBytes: totalBytes)

        // Then
        XCTAssertEqual(metric.utilizationPercent, 0)
    }
}
