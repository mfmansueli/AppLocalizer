//
//  ScreenshotsViewModel+Scope.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotsViewModel {
    func openScope() {
        guard let document else { return }
        scopeDraft = LocaleScopeDraft(scope: document.scope)
    }

    /// The sheet's rows, in App Store Connect's order.
    var scopeRows: [LocaleScopeRow] {
        guard let document, let draft = scopeDraft else { return [] }
        let slotCount = document.slotCount
        return locales.map { locale in
            let code = locale.code
            let live: LocaleScopeRow.Live = if let set = live.screenshotSets.first(where: { $0.locale == code && !$0.screenshots.isEmpty }) {
                isManaged(set) ? .localizedSet : .uploadedByHand
            } else {
                .usesPrimary
            }
            return LocaleScopeRow(
                locale: locale, isIncluded: draft.contains(code), isPrimary: code == document.scope.primary,
                isPinned: document.scope.isPinned(code), captionCount: document.captions.count(locale: code, slotCount: slotCount),
                slotCount: slotCount, hasOwnInterface: document.captures.hasOwnInterface(locale: code), live: live
            )
        }
    }

    /// A live set AppLocalizer pushed at least one screenshot of.
    private func isManaged(_ set: LiveScreenshotSet) -> Bool {
        let checksums = Set(set.screenshots.compactMap(\.checksum))
        return document?.pushed.contains { $0.cell.locale == set.locale && checksums.contains($0.checksum) } ?? false
    }

    /// "12 locales × 5 slots × 2 display types = 120 images · about 600
    /// requests, 17% of the hourly limit".
    var scopeEstimate: String {
        guard let draft = scopeDraft, let document else { return "" }
        let slots = document.slotCount
        // iPhone Duo only counts once it has captures: until then its
        // cells have nothing to push.
        let hasDuo = document.captures.captures.contains { $0.displayType == .iPhoneDuo }
        let displays = renderedDisplays.count { $0 != .iPhoneDuo || hasDuo }
        let liveImages = live.screenshotSets.filter { draft.contains($0.locale) }.reduce(0) { $0 + $1.screenshots.count }
        let estimate = PushCostEstimate.scope(localeCount: draft.count, slotCount: slots, displayTypeCount: displays, liveImages: liveImages)
        return String(localized: "\(draft.count) locales × \(slots) slots × \(displays) display types = \(estimate.images) images · \(estimate.requestsSummary)")
    }

    func setScope(_ locale: String, included: Bool) {
        scopeDraft?.set(locale, included: included)
    }

    /// Locales with Localized Captures.
    func selectLocalesWithCaptures() {
        guard let document else { return }
        scopeDraft?.select(document.captures.localesWithOwnInterface())
    }

    /// All 39.
    func selectAllLocales() {
        scopeDraft?.select(locales.map(\.code))
    }

    /// Only the primary locale.
    func selectOnlyPrimary() {
        scopeDraft?.select([])
    }

    func saveScope() async {
        guard var document, let draft = scopeDraft else { return }
        document.scope.setLocalized(draft.localized)
        scopeDraft = nil
        await commit(document)
    }

    /// Use Template Again: a restored locale goes back to being rendered.
    func useTemplateAgain(_ locale: String) async {
        guard var document else { return }
        document.scope.unpin(locale)
        await commit(document)
    }
}
