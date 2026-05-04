import AppKit
import MacAppKit

// MARK: - Snippet conformance

extension Snippet: Pickable {
    var displayText: String {
        let first = text.prefix(while: { $0 != "\n" })
        return text.contains("\n") ? first + "…" : String(first)
    }
    var searchText: String { text }
}

// MARK: - SnippetPicker

final class SnippetPicker: PickerPanel<Snippet> {
    private static let keywordBonus = 10_000

    init() {
        super.init(title: "Snippets", placeholder: "Search snippets…",
                   searchKey: "SnippetPicker.lastSearch",
                   appearance: NSAppearance(named: .darkAqua))
        setFilter { [unowned self] query, items in
            self.fuzzyFilter(query: query, items: items)
        }
        onPick { _, snippet in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                EventEmitter.pasteText(snippet.text)
            }
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Fuzzy filter with keyword bonus

    private func fuzzyFilter(query: String, items: [Snippet]) -> [Snippet] {
        let q = query.lowercased()
        let scored = items.compactMap { s -> (Snippet, Int)? in
            if let kw = s.keyword, kw.lowercased() == q { return (s, Int.max) }
            let textScore = Fuzzy.score(query: q, target: s.text.lowercased())
            let kwScore = s.keyword.flatMap { Fuzzy.score(query: q, target: $0.lowercased()) }
            if let ks = kwScore {
                return (s, max(ks, textScore ?? 0) + Self.keywordBonus)
            }
            if let ts = textScore {
                return (s, ts)
            }
            return nil
        }
        return scored.sorted { $0.1 > $1.1 }.map { $0.0 }
    }

    // MARK: - Custom cell with keyword badge

    private static let snippetCellID = NSUserInterfaceItemIdentifier("snippet")
    private static let kwID = NSUserInterfaceItemIdentifier("keyword")

    override func tableView(_ tv: NSTableView, viewFor col: NSTableColumn?, row: Int) -> NSView? {
        let snippet = filtered[row]

        if let view = tv.makeView(withIdentifier: Self.snippetCellID, owner: nil) as? NSTableCellView {
            view.textField?.stringValue = snippet.displayText
            let kwLabel = view.subviews.first { $0.identifier == Self.kwID } as? NSTextField
            kwLabel?.stringValue = snippet.keyword ?? ""
            kwLabel?.isHidden = snippet.keyword == nil
            return view
        }

        let cell = NSTableCellView()
        cell.identifier = Self.snippetCellID

        let tf = NSTextField(labelWithString: snippet.displayText)
        tf.lineBreakMode = .byTruncatingTail
        tf.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(tf)
        cell.textField = tf

        let kw = NSTextField(labelWithString: snippet.keyword ?? "")
        kw.identifier = Self.kwID
        kw.textColor = .tertiaryLabelColor
        kw.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        kw.alignment = .right
        kw.isHidden = snippet.keyword == nil
        kw.translatesAutoresizingMaskIntoConstraints = false
        kw.setContentHuggingPriority(.required, for: .horizontal)
        kw.setContentCompressionResistancePriority(.required, for: .horizontal)
        cell.addSubview(kw)

        NSLayoutConstraint.activate([
            tf.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 12),
            tf.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            kw.leadingAnchor.constraint(greaterThanOrEqualTo: tf.trailingAnchor, constant: 8),
            kw.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -12),
            kw.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }
}
