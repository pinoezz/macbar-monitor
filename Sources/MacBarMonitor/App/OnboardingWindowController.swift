import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController: NSWindowController, NSWindowDelegate {
    private let settingsStore: SettingsStore
    private var retainedSelf: OnboardingWindowController?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacBar Monitor Setup"
        window.isReleasedWhenClosed = false
        window.setAccessibilityRole(NSAccessibility.Role(rawValue: "AXDialog"))
        window.setAccessibilityLabel("MacBar Monitor Setup")
        window.center()

        super.init(window: window)

        window.contentViewController = makeHostingController()
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func showWindow(forced: Bool) {
        guard let window = window else { return }

        if forced || !settingsStore.hasCompletedOnboarding {
            // Re-create content view controller to ensure fresh state
            window.contentViewController = makeHostingController()

            NSApp.setActivationPolicy(.regular)
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
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

    private func makeHostingController() -> NSHostingController<OnboardingView> {
        NSHostingController(
            rootView: OnboardingView { [weak self] in
                self?.completeOnboarding()
            }
        )
    }
}
