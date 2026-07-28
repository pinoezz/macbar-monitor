import Foundation
import os.log

// MARK: - Type Aliases for Private IOKit HID Types

private typealias IOHIDEventSystemClient = OpaquePointer
private typealias IOHIDServiceClient = OpaquePointer
private typealias IOHIDEvent = OpaquePointer

// MARK: - IOKit HID Protocol

protocol IOKitHIDProviding: Sendable {
    func readTemperature() -> Double?
}

// MARK: - Live IOKit HID Temperature Reader

/// Reads CPU/chip temperature from Apple Silicon (and Intel) via IOKit HID private API.
///
/// This uses private IOKit HID event system functions (IOHIDEventSystemClientCreate,
/// IOHIDEventSystemClientSetMatching, IOHIDServiceClientCopyEvent, IOHIDEventGetFloatValue,
/// IOHIDServiceClientCopyProperty) to read temperature sensors. These are the same
/// APIs used by iStat Menus, TG Pro, ThermalBar, and apple_sensors.
///
/// - Important: No public API exists for reading temperature on macOS. This SPI can
///   change between macOS versions. Graceful nil fallback is always provided.
///
/// - Requires: macOS 12+ for stable IOHIDEventSystemClient behavior.
@available(macOS 12.0, *)
final class LiveIOKitHID: IOKitHIDProviding {
    private let log = OSLog(subsystem: "com.macbarmonitor", category: "thermal.hid")
    private let queue: DispatchQueue
    private let handle: UnsafeMutableRawPointer?
    private var lastTemperature: (value: Double, timestamp: Date)?
    private let temperatureCacheTTL: TimeInterval = 3.0

    // MARK: - Constants

    private static let tempEventType: Int64 = 15           // kIOHIDEventTypeTemperature
    private static let tempFieldBase: UInt32 = 983040       // IOHIDEventFieldBase(kIOHIDEventTypeTemperature)
    private static let primaryUsagePage: Int32 = 0xff00     // AppleVendor page
    private static let primaryUsage: Int32 = 0x0005         // TemperatureSensor usage

    // MARK: - Cached function pointers

    private let _createClient: (@convention(c) (CFAllocator?) -> IOHIDEventSystemClient?)?
    private let _setMatching: (@convention(c) (IOHIDEventSystemClient?, CFDictionary?) -> Void)?
    private let _copyServices: (@convention(c) (IOHIDEventSystemClient?) -> Unmanaged<CFArray>?)?
    private let _serviceCopyEvent: (@convention(c) (IOHIDServiceClient, Int64, Int32, Int64) -> IOHIDEvent?)?
    private let _eventGetFloatValue: (@convention(c) (IOHIDEvent?, UInt32) -> Double)?
    private let _serviceCopyProperty: (@convention(c) (IOHIDServiceClient, CFString) -> Unmanaged<CFString>?)?

    init() {
        self.queue = DispatchQueue(label: "com.macbarmonitor.thermal.hid", qos: .utility)

        // Use RTLD_NOW to fail fast: if any symbol is missing we detect at init
        let h = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW)
        self.handle = h

        guard let h else {
            os_log(.debug, log: self.log, "IOKitHID: failed to dlopen IOKit.framework")
            self._createClient = nil
            self._setMatching = nil
            self._copyServices = nil
            self._serviceCopyEvent = nil
            self._eventGetFloatValue = nil
            self._serviceCopyProperty = nil
            return
        }

        self._createClient = Self.symbol(h, "IOHIDEventSystemClientCreate")
        self._setMatching = Self.symbol(h, "IOHIDEventSystemClientSetMatching")
        self._copyServices = Self.symbol(h, "IOHIDEventSystemClientCopyServices")
        self._serviceCopyEvent = Self.symbol(h, "IOHIDServiceClientCopyEvent")
        self._eventGetFloatValue = Self.symbol(h, "IOHIDEventGetFloatValue")
        self._serviceCopyProperty = Self.symbol(h, "IOHIDServiceClientCopyProperty")
    }

    deinit {
        if let handle { dlclose(handle) }
    }

    // MARK: - Public API

    func readTemperature() -> Double? {
        // All cache + IOKit access happens on the serial queue to prevent data races
        queue.sync {
            // Cache hit within TTL
            if let cached = self.lastTemperature,
               Date().timeIntervalSince(cached.timestamp) < self.temperatureCacheTTL {
                return cached.value
            }

            let temp = self._performRead()
            if let temp {
                self.lastTemperature = (temp, Date())
            }
            return temp
        }
    }

    // MARK: - Internal (must be called on queue)

    private func _performRead() -> Double? {
        guard let createClient = _createClient, let setMatching = _setMatching,
              let copyServices = _copyServices, let serviceCopyEvent = _serviceCopyEvent,
              let eventGetFloatValue = _eventGetFloatValue else {
            os_log(.debug, log: log, "IOKitHID: function pointers not loaded")
            return nil
        }

        guard let client = createClient(kCFAllocatorDefault) else {
            os_log(.debug, log: log, "IOKitHID: createClient returned nil")
            return nil
        }

        // Try matching combinations for different macOS versions.
        // macOS 26+ uses 0xff00 for AppleARMPMUTempSensor (verified via ioreg).
        let sensorMatchers: [(Int32, Int32)] = [
            (0xff00, 0x0005),  // AppleVendor page, TemperatureSensor usage
            (0xff05, 0x0005),  // AppleVendorTemperatureSensor page (older macOS)
        ]

        for (page, usage) in sensorMatchers {
            let matching: CFDictionary = [
                "PrimaryUsagePage" as CFString: page as CFNumber,
                "PrimaryUsage" as CFString: usage as CFNumber
            ] as CFDictionary
            setMatching(client, matching)

            guard let servicesUnmanaged = copyServices(client) else {
                os_log(.debug, log: log, "IOKitHID: copyServices nil for page=0x%x", page)
                continue
            }

            let cfServices = servicesUnmanaged.takeRetainedValue()
            let count = CFArrayGetCount(cfServices)
            guard count > 0 else {
                os_log(.debug, log: log, "IOKitHID: 0 services for page=0x%x", page)
                continue
            }

            var totalTemp: Double = 0
            var validCount: Int = 0

            for i in 0..<count {
                let rawPtr = CFArrayGetValueAtIndex(cfServices, i)
                let service = unsafeBitCast(rawPtr, to: IOHIDServiceClient.self)

                guard let event = serviceCopyEvent(service, Self.tempEventType, 0, 0) else {
                    continue
                }
                let temp = eventGetFloatValue(event, Self.tempFieldBase)
                guard temp.isFinite, temp > 0, temp < 150 else {
                    continue
                }
                totalTemp += temp
                validCount += 1
            }

            if validCount > 0 {
                let average = totalTemp / Double(validCount)
                os_log(.debug, log: log, "IOKitHID: %.1f°C from %d/%d sensors", average, validCount, count)
                return average
            } else {
                os_log(.debug, log: log, "IOKitHID: %d services, 0 valid temps for page=0x%x", count, page)
            }
        }

        os_log(.debug, log: log, "IOKitHID: all matching pages exhausted")
        return nil
    }

    private static func symbol<T>(_ handle: UnsafeMutableRawPointer, _ name: String) -> T? {
        guard let sym = dlsym(handle, name) else { return nil }
        return unsafeBitCast(sym, to: T.self)
    }
}
