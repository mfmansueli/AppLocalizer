//
//  InAppTextsViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The In-App Texts view: subscription group, subscription and in-app
/// purchase names (30) and descriptions (45) per locale, loaded when the
/// view first opens. Edits are queued like the listing's.
@MainActor
@Observable
final class InAppTextsViewModel {
    let app: StoreApp
    private let services: any StorePageServices
    private let queue: ChangeQueue

    private(set) var state: LoadState<InAppTextsContent> = .idle
    /// App Store Connect's values with queued changes on top.
    private(set) var matrix: InAppTextMatrix?
    private var listingLocales: [StoreLocale] = []
    private var primaryLocale: StoreLocale = .englishUS

    init(app: StoreApp, services: any StorePageServices, queue: ChangeQueue) {
        self.app = app
        self.services = services
        self.queue = queue
    }

    /// Fetches the texts once (or again with `force`), listing the store
    /// page's locales.
    func load(listing: StoreListing?, force: Bool = false) async {
        if let listing {
            listingLocales = listing.displayLocales
            primaryLocale = listing.primaryLocale
        }
        guard force || state.value == nil, !state.isLoading else { return }
        state = .loading
        do {
            state = try await .loaded(services.inAppTexts(for: app))
            rebuild()
            // Changes queued before App Store Connect moved these texts into
            // versions (API 4.4.1), or for a version that's since gone,
            // become what pushing them now takes.
            if let matrix { sync(matrix) }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    var content: InAppTextsContent? { state.value }

    private var builder: InAppTextChangeBuilder? {
        content.map { InAppTextChangeBuilder(appID: app.id, content: $0) }
    }

    func queueDidChange() {
        rebuild()
    }

    private func rebuild() {
        guard let content, let builder else { return }
        var rebuilt = content.matrix(primaryLocale: primaryLocale, locales: listingLocales)
        builder.apply(queue.changes(for: app.id, section: .storePage), to: &rebuilt)
        matrix = rebuilt
    }

    func value(_ column: InAppTextColumn, in locale: StoreLocale) -> String {
        matrix?.value(column, in: locale) ?? ""
    }

    /// You edited a cell: queued like any other change.
    func edit(_ column: InAppTextColumn, in locale: StoreLocale, to value: String) {
        guard var matrix, matrix.value(column, in: locale) != value else { return }
        matrix.edit(column, in: locale, to: value)
        self.matrix = matrix
        sync(matrix)
    }

    /// Makes the queue hold exactly the matrix's changes, keeping when each
    /// was first queued.
    private func sync(_ matrix: InAppTextMatrix) {
        guard let builder else { return }
        let desired = builder.changes(for: matrix)
        let existing = queue.changes(for: app.id, section: .storePage).filter(builder.owns)
        let desiredIDs = Set(desired.map(\.id))
        queue.discard(ids: existing.map(\.id).filter { !desiredIDs.contains($0) })
        let current = Dictionary(existing.map { ($0.id, $0) }) { first, _ in first }
        queue.upsert(contentsOf: desired.compactMap { change in
            guard let old = current[change.id] else { return change }
            var change = change
            change.createdAt = old.createdAt
            return change == old ? nil : change
        })
    }

    /// "Display name 30 characters, description 45" counters.
    func counter(_ column: InAppTextColumn, in locale: StoreLocale) -> ListingFieldCounter {
        ListingFieldCounter(value(column, in: locale), limit: column.field.limit)
    }

    func isPending(_ column: InAppTextColumn, in locale: StoreLocale) -> Bool {
        matrix?.draft(column, in: locale).isPending ?? false
    }
}
