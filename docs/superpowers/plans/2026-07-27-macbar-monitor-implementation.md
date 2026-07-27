# MacBar Monitor MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a free, local-only native macOS menu bar monitor for Apple Silicon with configurable compact status text and a SwiftUI detail popover.

**Architecture:** Use a Swift Package Manager executable target compatible with Xcode, with an explicit release script that wraps the binary into a macOS `.app` bundle and installs `LSUIElement` in the bundled `Info.plist`. Keep pure models/calculations independent from platform providers; inject provider protocols into an actor-isolated monitor store; bridge the store to an AppKit `NSStatusItem` and SwiftUI `NSPopover`. Use documented/public APIs where possible and expose unsupported thermal or disk-I/O readings as typed unavailable values.

**Tech Stack:** Swift 5.9+, macOS 14+, SwiftUI, AppKit, Foundation, IOKit power sources, Mach host statistics, POSIX `getifaddrs`, XCTest, Swift Package Manager.

---

### Task 1: Bootstrap the package and executable target

**Files:**
- Create: `Package.swift`
- Create: `Sources/MacBarMonitor/MacBarMonitorApp.swift`
- Create: `Sources/MacBarMonitor/Info.plist`
- Create: `Tests/MacBarMonitorTests/PlaceholderTests.swift`

- [ ] Define a macOS 14 executable target and test target with no third-party dependencies.
- [ ] Add a reproducible bundling script that creates `MacBarMonitor.app/Contents/MacOS`, `Contents/Resources`, and `Contents/Info.plist`, copies the release binary, and sets `LSUIElement` to true.
- [ ] Configure the app as an agent application through the bundled `Info.plist` and keep all UI work on `MainActor`.
- [ ] Add only a temporary compile test, then replace it with behavior tests in later tasks.
- [ ] Run `swift build` and `swift test`; expected result is a successful executable and test bundle on a macOS host with Swift installed.

### Task 2: Define typed metrics and pure calculations using TDD

**Files:**
- Create: `Sources/MacBarMonitor/Domain/Metrics.swift`
- Create: `Sources/MacBarMonitor/Domain/MetricCalculations.swift`
- Create: `Tests/MacBarMonitorTests/MetricCalculationsTests.swift`

- [ ] Write failing tests for byte-rate calculation, zero/negative elapsed time, percentage clamping, byte formatting, temperature-state formatting, and unavailable-vs-zero display.
- [ ] Implement `MetricKey`, typed metric structs, `MetricResult<Value>`, `SystemSnapshot`, and pure helpers with `Sendable` conformance.
- [ ] Keep the first rate sample unavailable; never manufacture a zero rate.
- [ ] Run the focused XCTest suite red, implement the minimum, then rerun green before refactoring.

### Task 3: Add provider protocols and deterministic sample sources

**Files:**
- Create: `Sources/MacBarMonitor/Providers/MetricProviders.swift`
- Create: `Sources/MacBarMonitor/Providers/SampleSources.swift`
- Create: `Tests/MacBarMonitorTests/ProviderFixtureTests.swift`

- [ ] Define one provider protocol per metric group with async typed reads and no SwiftUI dependency.
- [ ] Define injected source protocols for counter-based providers so network and disk rate logic can be tested without live machine state.
- [ ] Add deterministic fixtures covering valid, unavailable, and source-error outcomes.
- [ ] Verify provider fixtures fail independently and preserve unavailable state.

### Task 4: Implement CPU, memory, and swap providers

**Files:**
- Create: `Sources/MacBarMonitor/Providers/CPUProvider.swift`
- Create: `Sources/MacBarMonitor/Providers/MemoryProvider.swift`
- Create: `Sources/MacBarMonitor/Providers/SwapProvider.swift`
- Modify: `Tests/MacBarMonitorTests/ProviderFixtureTests.swift`

- [ ] Use Mach host statistics for CPU and memory counters, calculating deltas from injected or retained prior samples.
- [ ] Use `sysctlbyname("vm.swapusage")` for swap, returning unavailable when the system does not expose usable totals.
- [ ] Handle return codes and invalid counter totals without force unwraps or suppression.
- [ ] Add deterministic tests for percentages, first samples, and unavailable values.

### Task 5: Implement thermal, battery, network, disk-speed, and disk-capacity providers

**Files:**
- Create: `Sources/MacBarMonitor/Providers/ThermalProvider.swift`
- Create: `Sources/MacBarMonitor/Providers/BatteryProvider.swift`
- Create: `Sources/MacBarMonitor/Providers/NetworkProvider.swift`
- Create: `Sources/MacBarMonitor/Providers/DiskProvider.swift`
- Modify: `Tests/MacBarMonitorTests/ProviderFixtureTests.swift`

- [ ] Represent thermal data with documented `ProcessInfo.thermalState` categories; do not label them as degrees Celsius or depend on private sensor APIs.
- [ ] Read battery charge and charging state through IOPowerSources and return unavailable on desktop/no-battery systems.
- [ ] Aggregate receive/transmit counters from eligible interfaces via `getifaddrs`, excluding loopback and virtual interfaces, and compute deltas using elapsed time.
- [ ] Read startup-volume capacity through URL resource values/FileManager.
- [ ] Keep disk throughput behind a source boundary; the MVP provider returns typed unavailable when no stable documented counter exists, with an explicit comment preventing private-API substitution.
- [ ] Add fixtures for no battery, first network sample, interface filtering, capacity errors, and unsupported disk speed.

### Task 6: Coordinate providers and persist settings

**Files:**
- Create: `Sources/MacBarMonitor/Store/SettingsStore.swift`
- Create: `Sources/MacBarMonitor/Store/MonitorStore.swift`
- Create: `Tests/MacBarMonitorTests/MonitorStoreTests.swift`

- [ ] Write failing async tests for snapshot merging, independent provider failures, selected primary metric updates, and settings persistence using an isolated UserDefaults suite.
- [ ] Implement a `@MainActor` observable store with injected providers, refresh method, and cancellable refresh task; providers performing blocking system reads must be `Sendable`/actor-isolated and must not be `@MainActor`.
- [ ] Use a default two-second interval and ensure refresh cancellation does not leave a task running.
- [ ] Update the status-label model from the selected metric without coupling the store to AppKit.

### Task 7: Add AppKit status item and SwiftUI popover/settings

**Files:**
- Create: `Sources/MacBarMonitor/App/StatusBarController.swift`
- Create: `Sources/MacBarMonitor/UI/MonitorPopoverView.swift`
- Create: `Sources/MacBarMonitor/UI/MetricRowView.swift`
- Create: `Sources/MacBarMonitor/UI/SettingsView.swift`
- Modify: `Sources/MacBarMonitor/MacBarMonitorApp.swift`

- [ ] Create an `NSStatusItem` with a template SF Symbol and concise selected-metric title.
- [ ] Host SwiftUI content in an `NSPopover`, toggle it on click, and close it when the app resigns active as appropriate.
- [ ] Render grouped rows for compute, memory/swap, thermal/battery, network, and storage; show `—` for unavailable values and distinguish valid zero.
- [ ] Add controls for primary metric and refresh interval, plus Quit.
- [ ] When opening a Settings window from an `LSUIElement` app, temporarily use `.regular` activation policy and restore `.accessory` after dismissal.
- [ ] Verify UI updates are main-actor isolated and no Dock icon is created.

### Task 8: Add build, test, and manual verification coverage

**Files:**
- Create: `README.md`
- Create: `.gitignore`
- Modify: `Tests/MacBarMonitorTests/*` as needed for failures found during verification.

- [ ] Run `swift test` and record the complete result.
- [ ] Run `swift build -c release` and record the complete result.
- [ ] Run `swiftformat`/lint only if already installed; do not introduce an untracked tool dependency.
- [ ] Launch the built app on macOS, verify the status item, popover, refresh, settings persistence, and clean termination manually.
- [ ] Check changed-file diagnostics and review the final diff for forbidden type escapes, empty catches, private-API assumptions, and accidental network access.
- [ ] Document supported macOS version, Apple Silicon scope, local-only behavior, and known unavailable metrics in `README.md`.
- [ ] Validate the generated `.app` bundle with `plutil`, verify `LSUIElement`, and run it from the release bundle rather than only the raw SPM binary.

## Verification gates

Every task must pass its focused tests before the next dependent task. Final completion requires clean diagnostics for changed Swift files, passing `swift test`, successful release build, and a manual menu-bar smoke test. Any limitation that cannot be verified on the current host must be reported explicitly rather than described as fixed.

## Known platform constraints

Apple Silicon temperature sensors and disk throughput counters are not consistently available through stable documented APIs. The implementation must display the documented thermal state category (not a fabricated numeric temperature) and show `—` for numeric temperature and disk speed when unavailable, while keeping provider boundaries ready for future documented sources. The project is intended for direct open-source distribution, not an App Store claim that depends on private APIs. Swap usage must validate `sysctlbyname` output and return unavailable on failure or invalid totals.
