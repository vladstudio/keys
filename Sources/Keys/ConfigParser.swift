import Foundation

enum ConfigParser {
    enum Error: Swift.Error, CustomStringConvertible {
        case unterminatedQuote(Int)

        var description: String {
            switch self {
            case .unterminatedQuote(let n): return "Line \(n): unterminated quoted field"
            }
        }
    }

    private enum Section {
        case remap, snippet, skipped
    }

    /// Parse the config. Unknown sections, keys, and malformed lines are reported as
    /// warnings on the returned `Config` and skipped — one bad line doesn't sink the
    /// whole file. Only an unterminated quote aborts, since the parser can't tell where
    /// the string was meant to end.
    static func parse(_ content: String) throws -> Config {
        var config = Config()
        var warnings: [String] = []
        var section: Section?
        let lines = content.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                i += 1
                continue
            }

            // [section]
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                let raw = String(trimmed.dropFirst(1).dropLast(1))
                    .trimmingCharacters(in: .whitespaces)
                let name = raw.lowercased()
                switch name {
                case "remap":
                    section = .remap
                case "snippet":
                    section = .snippet
                case "remap:internal", "remap:external":
                    warnings.append("Line \(i + 1): '\(raw)' is no longer supported, ignoring its rules")
                    section = .skipped
                default:
                    warnings.append("Line \(i + 1): unknown section '\(raw)', ignoring")
                    section = .skipped
                }
                i += 1
                continue
            }

            guard let sec = section else {
                warnings.append("Line \(i + 1): rule before any [section], ignoring")
                i += 1
                continue
            }

            switch sec {
            case .skipped:
                i += 1
                continue

            case .remap:
                // input: output — split on first ":"
                guard let colonIdx = trimmed.firstIndex(of: ":") else {
                    warnings.append("Line \(i + 1): invalid syntax '\(trimmed)', ignoring")
                    i += 1
                    continue
                }
                let inputStr = String(trimmed[..<colonIdx]).trimmingCharacters(in: .whitespaces)
                let outputStr = String(trimmed[trimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                guard !inputStr.isEmpty, !outputStr.isEmpty else {
                    warnings.append("Line \(i + 1): invalid syntax '\(trimmed)', ignoring")
                    i += 1
                    continue
                }
                guard let input = KeyCodes.parseInput(inputStr) else {
                    warnings.append("Line \(i + 1): unknown key '\(inputStr)', ignoring")
                    i += 1
                    continue
                }
                guard let output = KeyCodes.parseOutput(outputStr) else {
                    warnings.append("Line \(i + 1): unknown output '\(outputStr)', ignoring")
                    i += 1
                    continue
                }
                if case .sequence(let combos) = input,
                   !(combos.count == 2 && combos[0].keyCode == combos[1].keyCode) {
                    warnings.append("Line \(i + 1): only double-tap sequences supported, ignoring")
                    i += 1
                    continue
                }
                config.remaps.append(RemapRule(input: input, output: output))
                i += 1

            case .snippet:
                if trimmed.hasPrefix("\"") {
                    // Quoted snippet (may contain colons, may span lines). No alias.
                    let remaining = ([trimmed] + lines[(i+1)...]).joined(separator: "\n")
                    let (text, afterIdx) = try readQuoted(remaining, from: remaining.index(after: remaining.startIndex), line: i + 1)
                    let linesConsumed = remaining[remaining.startIndex..<afterIdx].filter { $0 == "\n" }.count + 1
                    config.snippets.append(Snippet(text: text, keyword: nil))
                    i += linesConsumed
                } else if let colonIdx = trimmed.firstIndex(of: ":") {
                    // alias: text
                    let alias = String(trimmed[..<colonIdx]).trimmingCharacters(in: .whitespaces)
                    let text = String(trimmed[trimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                    guard !alias.isEmpty, !text.isEmpty else {
                        warnings.append("Line \(i + 1): invalid syntax '\(trimmed)', ignoring")
                        i += 1
                        continue
                    }
                    config.snippets.append(Snippet(text: text, keyword: alias))
                    i += 1
                } else {
                    // Plain text, no alias
                    config.snippets.append(Snippet(text: trimmed, keyword: nil))
                    i += 1
                }
            }
        }

        config.warnings = warnings
        return config
    }

    // MARK: - Private

    /// Read quoted string starting after the opening `"`. Returns (text, indexAfterClosingQuote).
    /// Supports multiline. `""` escapes a literal `"`.
    private static func readQuoted(_ s: String, from start: String.Index, line: Int) throws -> (String, String.Index) {
        var pos = start
        var result = ""
        while pos < s.endIndex {
            if s[pos] == "\"" {
                let next = s.index(after: pos)
                if next < s.endIndex && s[next] == "\"" {
                    result.append("\"")
                    pos = s.index(after: next)
                } else {
                    return (result, next)
                }
            } else {
                result.append(s[pos])
                pos = s.index(after: pos)
            }
        }
        throw Error.unterminatedQuote(line)
    }
}
