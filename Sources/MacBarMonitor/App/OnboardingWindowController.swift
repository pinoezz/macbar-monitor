import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController: NSWindowController, NSWindowDelegate {
    private let settingsStore: SettingsStore
    private var retainedSelf: OnboardingWindowController?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore

        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 360),
            styleMask: [.titled, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.title = "MacBar Monitor Setup"
        window.isReleasedWhenClosed = false
        window.setAccessibilityRole(NSAccessibility.Role(rawValue: "AXDialog"))
        window.setAccessibilityLabel("MacBar Monitor Setup")
        window.center()

        super.init(window: window)

        let hostingController = NSHostingController(
            rootView: OnboardingView { [weak self] in
                self?.completeOnboarding()
            }
        )
        window.contentViewController = hostingController
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func showWindow(forced: Bool) {
        guard let window = window else { return }

        if forced || !settingsStore.hasCompletedOnboarding {
            NSApp.setActivationPolicy(.regular)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            retainedSelf = self
        }
    }

    func completeOnboarding() {
        settingsStore.hasCompletedOnboarding = true
        window?.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        retainedSelf = nil
    }

    func windowWillClose(_ notification: Notification) {
        if !settingsStore.hasCompletedOnboarding {
            settingsStore.hasCompletedOnboarding = true
        }
        NSApp.setActivationPolicy(.accessory)
        retainedSelf = nil
    }
}
