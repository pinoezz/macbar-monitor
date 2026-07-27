import Foundation

/// Wraps UserDefaults for metric selection, refresh interval, and onboarding state.
/// Thread-safe: UserDefaults provides atomic reads/writes, and this type
/// holds only a `let` reference with no internal mutable state.
final class SettingsStore {
    private let defaults: UserDefaults

    private enum Keys {
        static let selectedMetric = "selectedMetric"
        static let refreshInterval = "refreshInterval"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var selectedMetric: MetricKey {
        get {
            let raw = defaults.string(forKey: Keys.selectedMetric) ?? MetricKey.cpu.rawValue
            return MetricKey(rawValue: raw) ?? .cpu
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.selectedMetric)
        }
    }

    var refreshInterval: TimeInterval {
        get {
            let value = defaults.double(forKey: Keys.refreshInterval)
            return value > 0 ? value : 2.0
        }
        set {
            defaults.set(newValue, forKey: Keys.refreshInterval)
        }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }
}
