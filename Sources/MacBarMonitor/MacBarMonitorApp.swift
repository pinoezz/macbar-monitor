import SwiftUI

@main
struct MacBarMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var monitorStore: MonitorStore?
    private var onboardingController: OnboardingWindowController?
    private let settingsStore = SettingsStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let store = MonitorStore(settingsStore: settingsStore)
        monitorStore = store
        statusBarController = StatusBarController(store: store)
        statusBarController?.startMonitoring()

        showOnboardingIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusBarController?.stopMonitoring()
        statusBarController = nil
        monitorStore = nil
        onboardingController = nil
    }

    func showOnboarding(forced: Bool = false) {
        if let existing = onboardingController,
           existing.window?.isVisible == true {
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let controller = OnboardingWindowController(settingsStore: settingsStore)
        onboardingController = controller
        controller.showWindow(forced: forced)
    }

    private func showOnboardingIfNeeded() {
        showOnboarding(forced: false)
    }
}
