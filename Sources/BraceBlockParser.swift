import Foundation

// MARK: - Brace-balanced block parser

/// Shared utility for parsing `network={…}` blocks from wpa_supplicant-style
/// configuration files. Both `RealtekProfiles` and `EnterpriseCertStore`
/// need this logic; extracting it here eliminates code duplication.
enum BraceBlockParser {

    /// Find all `prefix{…}` blocks in `text`, where braces are balanced.
    /// Returns the full matched substring including the prefix and braces.
    ///
    /// - Parameters:
    ///   - prefix: The block-starting prefix, e.g. `"network={"`.
    ///   - text: The full configuration text.
    /// - Returns: Array of matched block strings.
    static func parseBlocks(withPrefix prefix: String, in text: String) -> [String] {
        var blocks: [String] = []
        var search = text.startIndex
        while search < text.endIndex,
              let start = text.range(of: prefix, range: search..<text.endIndex) {
            var depth = 0
            var i = start.lowerBound
            var end = text.endIndex
            while i < text.endIndex {
                let ch = text[i]
                if ch == "{" { depth += 1 }
                else if ch == "}" {
                    depth -= 1
                    if depth == 0 {
                        end = text.index(after: i)
                        break
                    }
                }
                i = text.index(after: i)
            }
            blocks.append(String(text[start.lowerBound..<end]))
            search = end
        }
        return blocks
    }
}
