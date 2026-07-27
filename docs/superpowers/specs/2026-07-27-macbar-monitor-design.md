# MacBar Monitor — MVP Design Specification

## Goal

MacBar Monitor is a free, open-source native macOS menu bar application for Apple Silicon MacBooks. It provides lightweight, local-only visibility into system health without requiring an account, background server, or paid service.

## Scope

The MVP monitors CPU utilization, memory utilization, swap usage, system temperature, battery status, network upload/download throughput, disk read/write throughput, and remaining disk capacity.

The menu bar remains compact: it displays one user-selected primary metric, such as `CPU 24%`. Clicking the status item opens a popover containing all supported metrics. The primary metric is configurable and persisted locally.

The MVP does not include process-level inspection, fan-speed control, notifications, historical charts, cloud synchronization, telemetry, or automatic updates.

## Platform and Architecture

The app is implemented as a native SwiftUI application with AppKit integration. AppKit owns the menu bar status item, popover presentation, application lifecycle, and menu commands. SwiftUI renders the popover and settings views.

The application is divided into four boundaries:

1. **MenuBarApp** creates the application, status item, popover, and lifecycle actions.
2. **MonitorStore** owns the current immutable snapshot, refresh scheduling, provider coordination, and selected primary metric.
3. **Metric providers** independently read macOS-local system sources and return typed metric values. Providers must not depend on the SwiftUI view layer.
4. **SettingsStore** persists user preferences with `UserDefaults`, including the selected primary metric and refresh interval.

Each provider is isolated so an unavailable metric cannot prevent other metrics from updating. The app targets Apple Silicon while retaining a clear minimum macOS deployment target in the project settings.

## Data Flow

On launch, the app creates the status item and starts the monitor store. At a configurable interval, the store requests a new snapshot from all providers. Provider results are normalized into display-ready typed values, and the store publishes the snapshot to SwiftUI and updates the status item title.

The first refresh may display an unavailable state until all providers return. Subsequent refreshes replace only the current snapshot; the app does not retain history in the MVP. Byte rates are calculated from successive samples and elapsed time, with the first sample reported as unavailable rather than misleadingly showing zero.

## Metric Definitions

- CPU: total utilization as a percentage.
- Memory: used physical memory as a percentage and human-readable quantity.
- Swap: used swap as a percentage or human-readable quantity when the OS exposes sufficient totals.
- Temperature: documented system thermal state category (`Nominal`, `Fair`, `Serious`, or `Critical`); numeric degrees Celsius are unavailable through stable public Apple Silicon APIs and display `—`.
- Battery: charge percentage, charging state, and time estimate when available.
- Network: aggregate upload and download bytes per second across active interfaces.
- Disk speed: aggregate read and write bytes per second for the monitored local storage volume.
- Disk free: available capacity and total capacity for the startup volume.

## UI Behavior

The status item uses a concise label for the selected metric. The popover contains grouped rows for compute, memory, thermal/battery, network, and storage. Values use consistent decimal formatting, units, and color thresholds. Color is supplemental; every value remains readable without color.

The popover provides access to a settings screen for choosing the primary metric and refresh interval, plus a Quit action. The app does not require a Dock icon and behaves as a menu bar utility.

## Error Handling and Privacy

All readings occur locally through macOS APIs or documented system interfaces. No metrics, identifiers, or user data leave the device. Provider failures are represented as unavailable typed results and logged locally at an appropriate level; they do not crash the app or stop unrelated providers.

The UI distinguishes unavailable data from a valid zero. Permission-restricted or unsupported sensors show `—` with a short explanatory tooltip where useful. The app must avoid privileged operations and must not request administrator credentials for the MVP.

## Testing Strategy

Pure unit tests cover percentage calculations, byte-rate calculations, elapsed-time edge cases, capacity formatting, temperature formatting, and threshold classification. Provider tests use deterministic fixtures or injected sample sources rather than live machine state.

Integration tests verify that the monitor store merges independent provider results, preserves unavailable states, updates the selected primary metric, and persists settings. A macOS smoke test verifies status-item creation, popover presentation, refresh updates, and clean termination.

## Acceptance Criteria

1. The app runs as a native menu bar utility on an Apple Silicon MacBook.
2. The popover displays all nine requested monitoring areas, including RAM and swap separately where supported.
3. Network and disk speeds are derived from samples and presented as rates.
4. Disk free space is shown for the startup volume.
5. One configurable metric appears in the menu bar and survives relaunch.
6. Unsupported readings show `—` without crashing or blocking other readings.
7. The application performs no network requests and requires no paid service.
8. Unit, integration, and smoke tests cover the core observable behaviors.
