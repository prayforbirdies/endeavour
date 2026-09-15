import AppKit

// Super Shuttle runs as a menu-bar-only agent (no Dock icon). The bundled
// Info.plist sets LSUIElement, and we mirror that here so `swift run` behaves
// the same way when launched without the .app wrapper.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
