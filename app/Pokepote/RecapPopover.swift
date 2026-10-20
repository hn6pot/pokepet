import AppKit
import SwiftUI

/// The small window under the menu bar icon; a click elsewhere closes it.
@MainActor
final class RecapPopover: NSObject, NSPopoverDelegate {
    private let popover = NSPopover()
    private let model: PopoverModel

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
}
