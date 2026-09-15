import AppKit
import ServiceManagement

let appVersion = "2.0.0"

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    private var statusItem: NSStatusItem!
    private let menu = NSMenu()

    // Cached modification dates so we only rebuild the menu when something changed.
    private var configModified: Date?
    private var altConfigModified: Date?
    private var sshUserModified: Date?
    private var sshSystemModified: Date?

    private var settings = Settings.from([:])

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        ConfigStore.resolvePaths()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let icon = NSImage(systemSymbolName: "terminal", accessibilityDescription: "Super Shuttle")
            icon?.isTemplate = true
            button.image = icon
        }

        menu.delegate = self
        statusItem.menu = menu
        rebuildMenu()
    }

    // MARK: NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        if needsUpdate(ConfigStore.configPath, since: configModified)
            || needsUpdate(ConfigStore.altConfigPath, since: altConfigModified)
            || needsUpdate("/etc/ssh/ssh_config", since: sshSystemModified)
            || needsUpdate("~/.ssh/config", since: sshUserModified) {
            configModified = ConfigStore.modificationDate(for: ConfigStore.configPath)
            altConfigModified = ConfigStore.modificationDate(for: ConfigStore.altConfigPath)
            sshSystemModified = ConfigStore.modificationDate(for: "/etc/ssh/ssh_config")
            sshUserModified = ConfigStore.modificationDate(for: "~/.ssh/config")
            rebuildMenu()
        }
    }

    private func needsUpdate(_ path: String, since old: Date?) -> Bool {
        guard let current = ConfigStore.modificationDate(for: path) else { return false }
        guard let old = old else { return true }
        return current > old
    }

    // MARK: Menu building

    private func rebuildMenu() {
        menu.removeAllItems()

        guard let (settings, hosts) = ConfigStore.load() else {
            let item = NSMenuItem(title: "Error parsing config", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            addFooter()
            return
        }
        self.settings = settings

        if settings.showSSHConfigHosts {
            mergeSSHHosts(into: hosts)
        }

        build(from: hosts, into: menu)
        addFooter()
    }

    /// Recursively turn the hosts tree into menu items. Submenus and leaves are
    /// bucketed separately so each group can be sorted independently.
    private func build(from data: NSArray, into m: NSMenu) {
        var menus: [String: NSArray] = [:]
        var leaves: [String: [String: Any]] = [:]

        for case let item as [String: Any] in data {
            if item["cmd"] != nil, let name = item["name"] as? String {
                leaves[name] = item
            } else {
                for (key, value) in item {
                    if let arr = value as? NSArray {
                        menus[key] = arr
                    }
                }
            }
        }

        let menuKeys = menus.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        let leafKeys = leaves.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        for key in menuKeys {
            let (name, separator) = MenuName.parse(key)
            let submenu = NSMenu()
            let item = NSMenuItem()
            item.title = name
            item.submenu = submenu
            m.addItem(item)
            if separator { m.addItem(.separator()) }
            build(from: menus[key]!, into: submenu)
        }

        for key in leafKeys {
            let cfg = leaves[key]!
            let (name, separator) = MenuName.parse((cfg["name"] as? String) ?? key)
            let action = HostAction(
                cmd: (cfg["cmd"] as? String) ?? "",
                theme: cfg["theme"] as? String,
                title: cfg["title"] as? String,
                window: cfg["inTerminal"] as? String,
                name: name
            )
            let item = NSMenuItem(title: name, action: #selector(openHost(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = action
            m.addItem(item)
            if separator { m.addItem(.separator()) }
        }
    }

    /// Merge hosts discovered from ssh_config into the JSON hosts tree, mirroring
    /// the original: `/`-separated names become nested submenus.
    private func mergeSSHHosts(into hosts: NSMutableArray) {
        let servers = SSHConfigParser.parseDefault()

        for key in servers.keys {
            let cfg = servers[key] ?? [:]
            let name = cfg["name"] ?? key

            if name.contains("*") { continue }
            if name.hasPrefix(".") { continue }
            if settings.ignoreHosts.contains(name) { continue }
            if settings.ignoreKeywords.contains(where: { name.contains($0) }) { continue }

            var path = name.components(separatedBy: "/")
            guard let leaf = path.last else { continue }
            path.removeLast()

            var itemList: NSMutableArray? = hosts
            for part in path {
                guard let list = itemList else { break }
                var createList = true
                for case let item as NSDictionary in list {
                    if item["cmd"] != nil || item["name"] != nil { continue }
                    if let existing = item[part] {
                        if let arr = existing as? NSMutableArray {
                            itemList = arr
                            createList = false
                        } else {
                            itemList = nil
                        }
                        break
                    }
                }
                guard itemList != nil else { break }
                if createList {
                    let newList = NSMutableArray()
                    itemList!.add([part: newList])
                    itemList = newList
                }
            }

            if let list = itemList {
                list.add(["name": leaf, "cmd": "ssh \(key)"])
            }
        }
    }

    private func addFooter() {
        menu.addItem(.separator())

        let edit = NSMenuItem(title: "Edit Configuration…", action: #selector(editConfig), keyEquivalent: ",")
        edit.target = self
        menu.addItem(edit)

        let reload = NSMenuItem(title: "Reload", action: #selector(reload), keyEquivalent: "r")
        reload.target = self
        menu.addItem(reload)

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        login.target = self
        login.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())

        let about = NSMenuItem(title: "About Super Shuttle", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    // MARK: Actions

    @objc private func openHost(_ sender: NSMenuItem) {
        guard let action = sender.representedObject as? HostAction else { return }
        TerminalLauncher.run(action, settings: settings)
    }

    @objc private func editConfig() {
        let path = ConfigStore.configPath
        if settings.editor.contains("default") {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        } else {
            let action = HostAction(
                cmd: "\(settings.editor) \(path)",
                theme: nil,
                title: "Editing Super Shuttle config",
                window: "new",
                name: "Edit Configuration"
            )
            TerminalLauncher.run(action, settings: settings)
        }
    }

    @objc private func reload() {
        rebuildMenu()
    }

    @objc private func toggleLaunchAtLogin() {
        setLaunchAtLogin(!isLaunchAtLoginEnabled())
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Super Shuttle \(appVersion)"
        alert.informativeText = """
        A simple shortcut menu for macOS.

        A native Apple Silicon port of Shuttle, originally created by \
        Trevor Fitzgerald and contributors (MIT licensed).

        Config: \(ConfigStore.configPath)
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Project Homepage")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertSecondButtonReturn,
           let url = URL(string: "https://github.com/fitztrev/shuttle") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quit() {
        NSStatusBar.system.removeStatusItem(statusItem)
        NSApp.terminate(nil)
    }

    // MARK: Launch at login (SMAppService, macOS 13+)

    private func isLaunchAtLoginEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Super Shuttle launch-at-login error: \(error)")
        }
    }
}
