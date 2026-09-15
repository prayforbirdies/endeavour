import Foundation

/// Resolves and loads the Shuttle JSON config, preserving drop-in compatibility
/// with the original app:
///   - `~/.shuttle.path`     -> file containing an alternate path to the config
///   - `~/.shuttle.json`     -> default config (created from a template if missing)
///   - `~/.shuttle-alt.path` -> file containing a path to a second config to merge
///   - `~/.shuttle-alt.json` -> default second config, merged if present
enum ConfigStore {
    static var configPath: String = ""
    static var altConfigPath: String = ""
    static var parseAlt: Bool = false

    private static func home(_ component: String) -> String {
        (NSHomeDirectory() as NSString).appendingPathComponent(component)
    }

    /// Resolve all paths and ensure a default config exists. Call once at launch.
    static func resolvePaths() {
        let fm = FileManager.default
        let pathPref = home(".shuttle.path")
        let altPathPref = home(".shuttle-alt.path")

        if fm.fileExists(atPath: pathPref),
           let custom = try? String(contentsOfFile: pathPref, encoding: .utf8) {
            configPath = custom.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            configPath = home(".shuttle.json")
            if !fm.fileExists(atPath: configPath) {
                try? DefaultConfig.json.write(toFile: configPath, atomically: true, encoding: .utf8)
            }
        }

        if fm.fileExists(atPath: altPathPref),
           let custom = try? String(contentsOfFile: altPathPref, encoding: .utf8) {
            altConfigPath = custom.trimmingCharacters(in: .whitespacesAndNewlines)
            parseAlt = true
        } else {
            altConfigPath = home(".shuttle-alt.json")
            parseAlt = fm.fileExists(atPath: altConfigPath)
        }
    }

    static func modificationDate(for path: String) -> Date? {
        let expanded = (path as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expanded) else { return nil }
        let attrs = try? FileManager.default.attributesOfItem(atPath: expanded)
        return attrs?[.modificationDate] as? Date
    }

    /// Load the primary config (and merge the alternate host list if present).
    /// Returns the raw settings dict plus a mutable hosts tree, or nil on parse error.
    static func load() -> (settings: Settings, hosts: NSMutableArray)? {
        guard let data = FileManager.default.contents(atPath: configPath),
              let json = (try? JSONSerialization.jsonObject(
                with: data, options: [.mutableContainers])) as? [String: Any]
        else {
            return nil
        }

        let settings = Settings.from(json)
        let hosts = (json["hosts"] as? NSMutableArray) ?? NSMutableArray()

        if parseAlt,
           let altData = FileManager.default.contents(atPath: altConfigPath),
           let altJSON = (try? JSONSerialization.jsonObject(
               with: altData, options: [.mutableContainers])) as? [String: Any],
           let altHosts = altJSON["hosts"] as? [Any] {
            hosts.addObjects(from: altHosts)
        }

        return (settings, hosts)
    }
}
