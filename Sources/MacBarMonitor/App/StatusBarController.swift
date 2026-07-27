import AppKit
import Combine
import SwiftUI

extension Notification.Name {
    static let dismissPopover = Notification.Name("dismissPopover")
}

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let store: MonitorStore
    private let popover: NSPopover
    private var cancellables = Set<AnyCancellable>()

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
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gauge.medium", accessibilityDescription: "MacBarMonitor")
            button.target = self
            button.action = #selector(togglePopover)
        }
    }

    private func observeStore() {
        store.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.updateTitle()
                }
            }
            .store(in: &cancellables)
        updateTitle()
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

    private func updateTitle() {
        statusItem.button?.title = store.menuBarDisplayText()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    deinit {
    }
}
