//
//  CaptionTranslationJob.swift
//  AppLocalizer
//

import Foundation

/// Translate Missing… for captions: the empty captions in scope, filled
/// one at a time and measured as each arrives.
struct CaptionTranslationJob: Hashable, Sendable {
    let sourceLocale: StoreLocale
    private(set) var items: [CaptionTranslationItem]

    var isEmpty: Bool { items.isEmpty }
    var totalCount: Int { items.count }
    var doneCount: Int { items.count { $0.result != nil } }
    var finishedCount: Int { items.count { $0.state.isFinished } }
    var failedCount: Int { items.count { if case .failed = $0.state { true } else { false } } }

    var fractionCompleted: Double {
        totalCount == 0 ? 1 : Double(finishedCount) / Double(totalCount)
    }

    var current: CaptionTranslationItem? { items.first { $0.state == .translating } }
    var nextQueued: CaptionTranslationItem? { items.first { $0.state == .queued } }

    /// Locales with an empty caption, in plan order.
    var locales: [StoreLocale] {
        var seen = Set<StoreLocale>()
        return items.map(\.locale).filter { seen.insert($0).inserted }
    }

    func itemCount(in locale: StoreLocale) -> Int {
        items.count { $0.locale == locale }
    }

    /// "20 empty captions in 4 locales."
    var summary: String {
        let captions = totalCount == 1 ? String(localized: "1 empty caption") : String(localized: "\(totalCount) empty captions")
        let inLocales = locales.count == 1 ? String(localized: "in 1 locale") : String(localized: "in \(locales.count) locales")
        return "\(captions) \(inLocales)."
    }

    /// "7 of 20 · Polish · slot 3".
    var progressLine: String {
        let count = String(localized: "\(finishedCount) of \(totalCount)")
        guard let current else { return count }
        return "\(count) · \(current.title)"
    }

    mutating func start(_ key: LocaleSlot) {
        update(key) { $0.state = .translating }
    }

    mutating func complete(_ key: LocaleSlot, with caption: ScreenshotCaption) {
        update(key) {
            $0.state = .done(caption.headline)
            $0.result = caption
        }
    }

    mutating func fail(_ key: LocaleSlot, message: String) {
        update(key) { $0.state = .failed(message) }
    }

    /// Cancel: drops what hasn't finished; what arrived stays written.
    mutating func cancelRemaining() {
        items.removeAll { !$0.state.isFinished }
    }

    private mutating func update(_ key: LocaleSlot, _ change: (inout CaptionTranslationItem) -> Void) {
        guard let index = items.firstIndex(where: { $0.key == key }) else { return }
        change(&items[index])
    }
}
