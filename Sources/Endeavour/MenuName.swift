import Foundation

/// Handles the two special tags the original Shuttle recognizes inside a menu name:
///   - `[aaa]` (3 lowercase letters) — a sort hint that is stripped from the label
///   - `[---]` — request a separator line after this item; stripped from the label
enum MenuName {
    private static let sortTag = try! NSRegularExpression(pattern: "([\\[][a-z]{3}[\\]])", options: [])
    private static let separatorTag = try! NSRegularExpression(pattern: "([\\[][-]{3}[\\]])", options: [])

    /// Returns the cleaned display name and whether a trailing separator was requested.
    static func parse(_ name: String) -> (name: String, addSeparator: Bool) {
        let full = NSRange(name.startIndex..., in: name)
        let sortMatches = sortTag.numberOfMatches(in: name, options: [], range: full)
        let sepMatches = separatorTag.numberOfMatches(in: name, options: [], range: full)

        var cleaned = name
        var addSeparator = false

        if sortMatches == 1 {
            cleaned = sortTag.stringByReplacingMatches(
                in: cleaned, options: [],
                range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
        }
        if sepMatches == 1 {
            cleaned = separatorTag.stringByReplacingMatches(
                in: cleaned, options: [],
                range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
            addSeparator = true
        }

        return (cleaned, addSeparator)
    }
}
