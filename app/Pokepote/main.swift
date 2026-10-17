import AppKit

// Entry point: an "accessory" app, with no Dock icon and no menu bar.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
