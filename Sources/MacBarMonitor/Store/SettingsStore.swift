import Foundation
import ServiceManagement

/// Wraps UserDefaults for metric selection, refresh interval, and onboarding state.
/// Thread-safe: UserDefaults provides atomic reads/writes, and this type
/// holds only a `let` reference with no internal mutable state.
final class SettingsStore {
    private let defaults: UserDefaults

    private enum Keys {
        static let selectedMetrics = "selectedMetrics"
        static let refreshInterval = "refreshInterval"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        // Legacy key for migration from v1
        static let selectedMetric = "selectedMetric"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        migrateFromV1IfNeeded()
    }

    // MARK: - Multi-select Metrics

    var selectedMetrics: Set<MetricKey> {
        get {
            guard let rawArray = defaults.array(forKey: Keys.selectedMetrics) as? [String] else {
                return [.cpu]
            }
            let keys = rawArray.compactMap { MetricKey(rawValue: $0) }
            return keys.isEmpty ? [.cpu] : Set(keys)
        }
        set {
            let rawArray = newValue.map(\.rawValue)
            defaults.set(rawArray, forKey: Keys.selectedMetrics)
        }
    }

    // Legacy single-metric accessor (for backward compatibility)
    var selectedMetric: MetricKey {
        get {
            selectedMetrics.first ?? .cpu
        }
        set {
            selectedMetrics = [newValue]
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

    // MARK: - Launch at Login

    var launchAtLogin: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Silently fail — user may not have granted permission
                print("Launch at Login error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Migration

    private func migrateFromV1IfNeeded() {
        // If v1 single metric key exists but v2 multi key doesn't, migrate
        if defaults.object(forKey: Keys.selectedMetrics) == nil,
           let legacyRaw = defaults.string(forKey: Keys.selectedMetric),
           let legacyKey = MetricKey(rawValue: legacyRaw) {
            selectedMetrics = [legacyKey]
        }
    }
}
