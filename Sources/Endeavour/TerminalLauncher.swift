import AppKit

/// Launches commands in Terminal.app or iTerm by generating AppleScript at
/// runtime (no shipped .scpt files). Ports the behavior of the original
/// Shuttle AppleScripts. iTerm targets the modern stable (v3+) scripting API.
enum TerminalLauncher {

    // MARK: Public entry point

    static func run(_ action: HostAction, settings: Settings) {
        let cmd = action.cmd

        // URL detection: if the command is a real URL (has a scheme), hand it to
        // the default handler instead of a terminal. Commands like "ssh host" or
        // "ps aux | grep x" contain spaces and never parse to a scheme, so they
        // fall through to the terminal path.
        if let url = URL(string: cmd), let scheme = url.scheme, !scheme.isEmpty,
           !cmd.contains(" ") {
            NSWorkspace.shared.open(url)
            return
        }

        let isITerm = settings.terminal.contains("iterm")

        // Resolve theme: explicit -> global default -> per-terminal fallback.
        let theme = action.theme
            ?? settings.defaultTheme
            ?? (isITerm ? "Default" : "basic")

        // Resolve title: explicit -> menu name.
        let title = action.title ?? action.name

        // Resolve window mode: explicit -> global open_in -> "tab".
        var window = action.window ?? settings.openIn
        if !["new", "tab", "current", "virtual"].contains(window) {
            window = "tab"
        }

        if window == "virtual" {
            runVirtual(cmd)
            return
        }

        let source: String = isITerm
            ? iTermScript(window: window, cmd: cmd, theme: theme, title: title)
            : terminalScript(window: window, cmd: cmd, theme: theme, title: title)

        execute(source)
    }

    // MARK: AppleScript execution

    private static func execute(_ source: String) {
        guard let script = NSAppleScript(source: source) else { return }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error = error {
            NSLog("Endeavour AppleScript error: \(error)")
        }
    }

    /// Escape a string for inclusion inside an AppleScript double-quoted literal.
    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
    }

    // MARK: Terminal.app scripts

    private static func terminalScript(window: String, cmd: String, theme: String, title: String) -> String {
        let c = esc(cmd), t = esc(theme), n = esc(title)
        switch window {
        case "new":
            return """
            tell application "Terminal"
                if it is not running then
                    set newTerm to do script "\(c)" in window 1
                else
                    set newTerm to do script "\(c)"
                end if
                activate
                set newTerm's current settings to settings set "\(t)"
                set custom title of front window to "\(n)"
            end tell
            """
        case "current":
            return """
            tell application "Terminal"
                reopen
                activate
                do script "\(c)" in front window
            end tell
            """
        default: // "tab"
            return """
            tell application "Terminal"
                if it is not running then
                    activate
                    set newTerm to do script "\(c)" in window 1
                    set newTerm's current settings to settings set "\(t)"
                    set custom title of front window to "\(n)"
                else
                    set windowCount to (count every window)
                    if windowCount = 0 then
                        reopen
                        activate
                        do script "\(c)" in selected tab of window 1
                    else
                        reopen
                        activate
                        tell application "System Events"
                            tell process "Terminal"
                                delay 0.3
                                keystroke "t" using {command down}
                            end tell
                        end tell
                        activate
                        do script "\(c)" in selected tab of front window
                    end if
                    set current settings of selected tab of front window to settings set "\(t)"
                    set title displays custom title of front window to true
                    set custom title of selected tab of front window to "\(n)"
                end if
            end tell
            """
        }
    }

    // MARK: iTerm scripts (stable v3+ API)

    private static func iTermScript(window: String, cmd: String, theme: String, title: String) -> String {
        let c = esc(cmd), t = esc(theme), n = esc(title)
        switch window {
        case "new":
            return """
            tell application "iTerm"
                if it is not running then
                    activate
                    if (count windows) is 0 then
                        try
                            create window with profile "\(t)"
                        on error
                            create window with profile "Default"
                        end try
                    end if
                else
                    try
                        create window with profile "\(t)"
                    on error
                        create window with profile "Default"
                    end try
                end if
                tell the current window
                    tell the current session
                        set name to "\(n)"
                        write text "\(c)"
                    end tell
                end tell
            end tell
            """
        case "current":
            return """
            tell application "iTerm"
                reopen
                activate
                tell the current window
                    tell the current session
                        set name to "\(n)"
                        write text "\(c)"
                    end tell
                end tell
            end tell
            """
        default: // "tab"
            return """
            tell application "iTerm"
                if it is not running then
                    activate
                    if (count windows) is 0 then
                        try
                            create window with profile "\(t)"
                        on error
                            create window with profile "Default"
                        end try
                    end if
                    tell the current window
                        tell the current session
                            set name to "\(n)"
                            write text "\(c)"
                        end tell
                    end tell
                else if (count windows) is 0 then
                    try
                        create window with profile "\(t)"
                    on error
                        create window with profile "Default"
                    end try
                    tell the current window
                        tell the current session
                            set name to "\(n)"
                            write text "\(c)"
                        end tell
                    end tell
                else
                    tell the current window
                        try
                            create tab with profile "\(t)"
                        on error
                            create tab with profile "Default"
                        end try
                    end tell
                    tell the current window
                        tell the current tab
                            tell the current session
                                set name to "\(n)"
                                write text "\(c)"
                            end tell
                        end tell
                    end tell
                end if
            end tell
            """
        }
    }

    // MARK: Virtual (detached background run via screen)

    private static func runVirtual(_ cmd: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        // Run detached inside a named screen session so it survives independently.
        process.arguments = ["-lc", "screen -d -m bash -lc \(shellQuote(cmd))"]
        try? process.run()
    }

    private static func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
