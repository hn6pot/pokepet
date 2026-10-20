import AppKit
import SwiftUI

/// The small window under the menu bar icon; a click elsewhere closes it.
@MainActor
final class RecapPopover: NSObject, NSPopoverDelegate {
    private let popover = NSPopover()
    private let model: PopoverModel
    /// While the window is open, the figures are refreshed every minute.
    private var timer: Timer?

    init(model: PopoverModel) {
        self.model = model
        super.init()
        let content = NSHostingController(rootView: PopoverView(model: model))
        content.sizingOptions = .preferredContentSize
        popover.contentViewController = content
        popover.behavior = .transient
        popover.delegate = self
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        model.refresh()
        // An accessory app must be active for a click elsewhere to close the window.
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func popoverDidShow(_ notification: Notification) {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.refresh() }
        }
    }

    func popoverDidClose(_ notification: Notification) {
        timer?.invalidate()
        timer = nil
    }
}
