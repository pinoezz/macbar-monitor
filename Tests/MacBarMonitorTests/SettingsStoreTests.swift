import XCTest
@testable import MacBarMonitor

final class SettingsStoreTests: XCTestCase {

    private var sut: SettingsStore!
    private var defaults: UserDefaults!
    private let suiteName = "SettingsStoreTests_\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        guard let created = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite: \(suiteName)")
            return
        }
        defaults = created
        sut = SettingsStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        UserDefaults().removePersistentDomain(forName: suiteName)
        sut = nil
        defaults = nil
        super.tearDown()
    }

    // MARK: - hasCompletedOnboarding

    func testOnboardingDefaultsToFalse() {
        // Given: fresh isolated UserDefaults (no value set)
        // When
        let result = sut.hasCompletedOnboarding

        // Then
        XCTAssertFalse(result, "hasCompletedOnboarding should default to false")
    }

    func testOnboardingRoundTripToTrue() {
        // Given
        XCTAssertFalse(sut.hasCompletedOnboarding)

        // When
        sut.hasCompletedOnboarding = true

        // Then
        XCTAssertTrue(sut.hasCompletedOnboarding)
    }

    func testOnboardingRoundTripToFalse() {
        // Given
        sut.hasCompletedOnboarding = true
        XCTAssertTrue(sut.hasCompletedOnboarding)

        // When
        sut.hasCompletedOnboarding = false

        // Then
        XCTAssertFalse(sut.hasCompletedOnboarding)
    }

    func testOnboardingPersistsAcrossInstances() {
        // Given
        sut.hasCompletedOnboarding = true

        // When: create a new SettingsStore backed by the same suite
        let anotherStore = SettingsStore(defaults: defaults)

        // Then
        XCTAssertTrue(anotherStore.hasCompletedOnboarding,
                      "Onboarding flag should persist across SettingsStore instances sharing the same UserDefaults")
    }

    // MARK: - selectedMetric

    func testSelectedMetricDefaultsToCPU() {
        // Given: fresh isolated UserDefaults
        // When
        let result = sut.selectedMetric

        // Then
        XCTAssertEqual(result, .cpu, "selectedMetric should default to .cpu")
    }

    func testSelectedMetricRoundTrip() {
        // Given
        sut.selectedMetric = .memory

        // When
        let result = sut.selectedMetric

        // Then
        XCTAssertEqual(result, .memory)
    }

    // MARK: - refreshInterval

    func testRefreshIntervalDefaultsToTwoSeconds() {
        // Given: fresh isolated UserDefaults
        // When
        let result = sut.refreshInterval

        // Then
        XCTAssertEqual(result, 2.0, "refreshInterval should default to 2.0 seconds")
    }

    func testRefreshIntervalRoundTrip() {
        // Given
        sut.refreshInterval = 5.0

        // When
        let result = sut.refreshInterval

        // Then
        XCTAssertEqual(result, 5.0)
    }

    func testRefreshIntervalFallsBackToDefaultForZero() {
        // Given: write 0 directly into UserDefaults (bypass setter)
        defaults.set(0.0, forKey: "refreshInterval")

        // When
        let result = sut.refreshInterval

        // Then
        XCTAssertEqual(result, 2.0, "refreshInterval should fall back to 2.0 when stored value is 0")
    }
}
