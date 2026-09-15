import Foundation

/// Parses `~/.ssh/config` (or `/etc/ssh_config`) into a map of host alias ->
/// metadata dict. Mirrors the original Shuttle behavior:
///   - only the first alias of a multi-alias `Host` line is kept
///   - `Include` directives are followed
///   - `# shuttle.<key> <value>` comment lines attach metadata to the current host
enum SSHConfigParser {
    /// Regex matches: optional leading `#`, a key token, then the rest as value.
    private static let line = try! NSRegularExpression(
        pattern: "^(#?)[ \\t]*([^ \\t=]+)[ \\t=]+(.*)$", options: [])

    static func parseDefault() -> [String: [String: String]] {
        let fm = FileManager.default
        var configFile: String?

        if fm.fileExists(atPath: "/etc/ssh_config") {
            configFile = "/etc/ssh_config"
        }
        let userConfig = ("~/.ssh/config" as NSString).expandingTildeInPath
        if fm.fileExists(atPath: userConfig) {
            configFile = userConfig
        }

        guard let path = configFile else { return [:] }
        return parse(path)
    }

    static func parse(_ filepath: String) -> [String: [String: String]] {
        guard let contents = try? String(contentsOfFile: filepath, encoding: .utf8) else {
            return [:]
        }

        var servers: [String: [String: String]] = [:]
        var currentKey: String?

        for raw in contents.components(separatedBy: "\n") {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            let range = NSRange(trimmed.startIndex..., in: trimmed)
            guard let match = line.firstMatch(in: trimmed, options: [], range: range),
                  match.numberOfRanges == 4,
                  let r1 = Range(match.range(at: 1), in: trimmed),
                  let r2 = Range(match.range(at: 2), in: trimmed),
                  let r3 = Range(match.range(at: 3), in: trimmed)
            else { continue }

            let isComment = trimmed[r1] == "#"
            let first = String(trimmed[r2])
            let second = String(trimmed[r3])

            // `# shuttle.<key> <value>` metadata for the current host block.
            if isComment, let key = currentKey, first.hasPrefix("shuttle.") {
                servers[key]?[String(first.dropFirst("shuttle.".count))] = second
            }
            if isComment { continue }

            if first == "Include" {
                let includePath: String
                if (second as NSString).isAbsolutePath {
                    includePath = (second as NSString).expandingTildeInPath
                } else {
                    includePath = (filepath as NSString)
                        .deletingLastPathComponent
                        .appending("/\(second)")
                }
                for (k, v) in parse(includePath) {
                    servers[k] = v
                }
            }

            if first == "Host" {
                // Keep only the first alias of a multi-alias Host line.
                let aliases = second
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                if let key = aliases.first {
                    currentKey = key
                    if servers[key] == nil { servers[key] = [:] }
                }
            }
        }

        return servers
    }
}
