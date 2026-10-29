import CoreGraphics

/// macOS ignores the cursor set by an app that is not in front, and Poképote never comes to the front.
/// This lets it set the cursor anyway (the pointing hand over the sprite).
/// shortcut: private window server property, undocumented; if Apple removes it, the hand simply no longer shows.
enum BackgroundCursor {
    static func allow() {
        let connection = _CGSDefaultConnection()
        _ = CGSSetConnectionProperty(connection, connection, "SetsCursorInBackground" as CFString, kCFBooleanTrue)
    }
}

@_silgen_name("_CGSDefaultConnection")
private func _CGSDefaultConnection() -> Int32

@_silgen_name("CGSSetConnectionProperty")
private func CGSSetConnectionProperty(_ connection: Int32, _ target: Int32, _ key: CFString, _ value: CFTypeRef) -> Int32
