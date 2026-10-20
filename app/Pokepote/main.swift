import AppKit

// Entry point: an "accessory" app, with no Dock icon and no menus; its only presence
// in the menu bar is the Pokémon icon (`MenuBarIcon`).
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
