import Foundation

/// A concrete, clickable menu entry: a command plus its display/terminal options.
/// Stored on `NSMenuItem.representedObject` so the click handler has everything
/// it needs without re-parsing the config.
final class HostAction: NSObject {
    let cmd: String
    let theme: String?
    let title: String?
    /// One of: "new", "tab", "current", "virtual". `nil` means "use the global default".
    let window: String?
    let name: String

    init(cmd: String, theme: String?, title: String?, window: String?, name: String) {
        self.cmd = cmd
        self.theme = theme
        self.title = title
        self.window = window
        self.name = name
    }
}

/// Global preferences read from the top level of the JSON config.
struct Settings {
    var terminal: String          // "iTerm" or "Terminal.app"
    var editor: String            // "default" or a CLI editor (vi, nano, ...)
    var openIn: String            // "tab" or "new"
    var defaultTheme: String?
    var launchAtLogin: Bool
    var showSSHConfigHosts: Bool
    var ignoreHosts: [String]
    var ignoreKeywords: [String]

    static func from(_ json: [String: Any]) -> Settings {
        Settings(
            terminal: ((json["terminal"] as? String) ?? "Terminal.app").lowercased(),
            editor: ((json["editor"] as? String) ?? "default").lowercased(),
            openIn: ((json["open_in"] as? String) ?? "tab").lowercased(),
            defaultTheme: json["default_theme"] as? String,
            launchAtLogin: (json["launch_at_login"] as? Bool) ?? false,
            // Match the original default: merge ssh_config hosts unless explicitly disabled.
            showSSHConfigHosts: (json["show_ssh_config_hosts"] as? Bool) ?? true,
            ignoreHosts: (json["ssh_config_ignore_hosts"] as? [String]) ?? [],
            ignoreKeywords: (json["ssh_config_ignore_keywords"] as? [String]) ?? []
        )
    }
}
