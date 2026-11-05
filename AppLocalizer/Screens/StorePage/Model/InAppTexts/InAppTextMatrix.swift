//
//  InAppTextMatrix.swift
//  AppLocalizer
//

import Foundation

/// The In-App Texts view: locales × (group name, each product's name and
/// description), with the same counters, edit rules and pending changes as
/// the listing (`ListingFieldDraft`).
struct InAppTextMatrix: Hashable, Sendable {
    let columns: [InAppTextColumn]
    let primaryLocale: StoreLocale
    private(set) var locales: [StoreLocale]
    private var drafts: [CellKey: ListingFieldDraft]

    /// `remote` is keyed by locale, then by column ID.
    init(products: [InAppTextProduct], primaryLocale: StoreLocale, locales: [StoreLocale], remote: [StoreLocale: [String: String]]) {
        columns = InAppTextColumn.columns(for: products)
        self.primaryLocale = primaryLocale
        self.locales = locales.contains(primaryLocale) ? locales : [primaryLocale] + locales
        drafts = [:]
        for (locale, values) in remote {
            for (columnID, value) in values {
                drafts[CellKey(locale: locale, columnID: columnID)] = ListingFieldDraft(remote: value)
            }
        }
    }

    /// The primary locale first, then by English name.
    var displayLocales: [StoreLocale] {
        [primaryLocale] + locales.filter { $0 != primaryLocale }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func draft(_ column: InAppTextColumn, in locale: StoreLocale) -> ListingFieldDraft {
        drafts[CellKey(locale: locale, columnID: column.id)] ?? ListingFieldDraft()
    }

    func value(_ column: InAppTextColumn, in locale: StoreLocale) -> String {
        draft(column, in: locale).local
    }

    func validation(of column: InAppTextColumn, in locale: StoreLocale) -> ListingFieldValidation {
        ListingFieldValidator.validate(value(column, in: locale), for: column.field)
    }

    /// "10/30", red over the limit.
    func counter(_ column: InAppTextColumn, in locale: StoreLocale) -> ListingFieldCounter {
        ListingFieldCounter(value(column, in: locale), limit: column.field.limit)
    }

    var missingCount: Int {
        cells.count(where: { value($0.column, in: $0.locale).isEmpty })
    }

    var overLimitCount: Int {
        cells.count(where: { validation(of: $0.column, in: $0.locale).isBlocking })
    }

    mutating func addLocale(_ locale: StoreLocale) {
        guard !locales.contains(locale) else { return }
        locales.append(locale)
    }

    mutating func edit(_ column: InAppTextColumn, in locale: StoreLocale, to value: String) {
        addLocale(locale)
        drafts[CellKey(locale: locale, columnID: column.id), default: ListingFieldDraft()].edit(value)
    }

    /// An assistant's value (`propose_in_app_texts`), tagged with who
    /// proposed it while it's pending.
    mutating func propose(_ value: String, for column: InAppTextColumn, in locale: StoreLocale, by client: String) -> ListingProposalOutcome {
        addLocale(locale)
        return drafts[CellKey(locale: locale, columnID: column.id), default: ListingFieldDraft()].propose(value, by: client)
    }

    mutating func acceptMachineTranslation(_ value: String, for column: InAppTextColumn, in locale: StoreLocale) {
        addLocale(locale)
        drafts[CellKey(locale: locale, columnID: column.id), default: ListingFieldDraft()].acceptMachineTranslation(value)
    }

    mutating func discard(_ column: InAppTextColumn, in locale: StoreLocale) {
        drafts[CellKey(locale: locale, columnID: column.id)]?.discard()
    }

    /// Pending in-app text changes for Review & Push.
    var changes: [InAppTextChange] {
        cells.compactMap { cell in
            let draft = draft(cell.column, in: cell.locale)
            guard draft.isPending else { return nil }
            let blockReason: ListingBlockReason? = switch validation(of: cell.column, in: cell.locale) {
            case let .overLimit(count, limit): .overLimit(count: count, limit: limit)
            case .invalidURL: .invalidURL
            case .valid, .empty: nil
            }
            return InAppTextChange(
                locale: cell.locale,
                column: cell.column,
                oldValue: draft.remote,
                newValue: draft.local,
                source: draft.source,
                blockReason: blockReason
            )
        }
    }

    /// Every cell, locales in display order.
    private var cells: [(locale: StoreLocale, column: InAppTextColumn)] {
        displayLocales.flatMap { locale in columns.map { (locale, $0) } }
    }

    private struct CellKey: Hashable, Sendable {
        let locale: StoreLocale
        let columnID: String
    }
}
