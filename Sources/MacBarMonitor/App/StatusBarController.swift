import AppKit
import Combine
import SwiftUI

extension Notification.Name {
    static let dismissPopover = Notification.Name("dismissPopover")
    static let showOnboarding = Notification.Name("showOnboarding")
}

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let store: MonitorStore
    private let popover: NSPopover
    private var cancellables = Set<AnyCancellable>()
    private var statusBarView: StatusBarView?

    init(store: MonitorStore) {
        self.store = store
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 420)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MonitorPopoverView(store: store))
        self.popover = popover
        super.init()
        setupStatusItem()
        observeStore()
        observeDismissNotification()
    }

    func startMonitoring() {
        store.startMonitoring()
    }

    func stopMonitoring() {
        store.stopMonitoring()
    }

    private func setupStatusItem() {
        let barView = StatusBarView()
        barView.onTogglePopover = { [weak self] in self?.togglePopover() }
        self.statusBarView = barView

        // Use KVC to set the view on the status item (avoids deprecated button.image for custom view)
        statusItem.setValue(barView, forKey: "view")

        updateContent()
    }

    private func observeStore() {
        store.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.updateContent()
                }
            }
            .store(in: &cancellables)
    }

    private func observeDismissNotification() {
        NotificationCenter.default.addObserver(
            forName: .dismissPopover,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.popover.performClose(nil)
        }
    }

    private func updateContent() {
        let metrics = store.menuBarDisplayData()
        statusBarView?.update(with: metrics)
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Position the popover relative to the status bar view
            if let statusView = statusItem.value(forKey: "view") as? NSView {
                popover.show(relativeTo: statusView.bounds, of: statusView, preferredEdge: .minY)
            }
        }
    }

    deinit {
    }
}
