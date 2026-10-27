//
//  TranslationJob.swift
//  AppLocalizer
//

import Foundation

/// A batch of cells to translate and its progress, behind the Translate
/// sheet and the batch progress bar. The runner (Apple Translation, an AI
/// provider) takes `nextQueued`, calls `start`, then `complete` or `fail`.
/// Copy items can be finished at once with `completeCopies()`.
struct TranslationJob: Hashable, Sendable {
    let sourceLocale: StoreLocale
    private(set) var items: [TranslationItem]

    var isEmpty: Bool { items.isEmpty }
    var totalCount: Int { items.count }
    var doneCount: Int { items.count(where: { $0.result != nil }) }
    var failedCount: Int { items.count(where: { if case .failed = $0.state { true } else { false } }) }
    var finishedCount: Int { items.count(where: { $0.state.isFinished }) }
    var isFinished: Bool { finishedCount == totalCount }

    var fractionCompleted: Double {
        totalCount == 0 ? 1 : Double(finishedCount) / Double(totalCount)
    }

    /// The item being translated now.
    var current: TranslationItem? { items.first { $0.state == .translating } }
    var nextQueued: TranslationItem? { items.first { $0.state == .queued } }

    /// Locales with something to fill, in plan order.
    var locales: [StoreLocale] {
        var seen = Set<StoreLocale>()
        return items.map(\.key.locale).filter { seen.insert($0).inserted }
    }

    /// The Translate sheet's per-locale count, e.g. Korean · 9 fields.
    func itemCount(in locale: StoreLocale) -> Int {
        items.count(where: { $0.key.locale == locale })
    }

    /// "38 empty fields in 12 locales. URLs are copied from English (U.S.), not translated."
    var summary: String {
        let fields = totalCount == 1 ? String(localized: "1 empty field") : String(localized: "\(totalCount) empty fields")
        let localeCount = locales.count
        let inLocales = localeCount == 1 ? String(localized: "in 1 locale") : String(localized: "in \(localeCount) locales")
        guard items.contains(where: \.key.field.isURL) else { return "\(fields) \(inLocales)." }
        return "\(fields) \(inLocales). " + String(localized: "URLs are copied from \(sourceLocale.name), not translated.")
    }

    /// "17 of 41 · Korean · Description".
    var progressLine: String {
        let count = String(localized: "\(finishedCount) of \(totalCount)")
        guard let current else { return count }
        return "\(count) · \(current.title)"
    }

    mutating func start(_ id: ListingFieldKey) {
        setState(.translating, for: id)
    }

    /// Stores the result. Restore glossary terms before passing it in.
    mutating func complete(_ id: ListingFieldKey, with text: String) {
        setState(.done(text), for: id)
    }

    mutating func fail(_ id: ListingFieldKey, message: String) {
        setState(.failed(message), for: id)
    }

    /// Finishes every queued copy item with its source text.
    mutating func completeCopies() {
        for index in items.indices where items[index].method == .copy && items[index].state == .queued {
            items[index].state = .done(items[index].sourceText)
        }
    }

    /// "Retry Failed": failed items go back in the queue.
    mutating func retryFailed() {
        for index in items.indices {
            if case .failed = items[index].state { items[index].state = .queued }
        }
    }

    /// "Cancel": drops what hasn't finished, keeping finished results.
    mutating func cancelRemaining() {
        items.removeAll { !$0.state.isFinished }
    }

    private mutating func setState(_ state: TranslationItemState, for id: ListingFieldKey) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].state = state
    }
}
