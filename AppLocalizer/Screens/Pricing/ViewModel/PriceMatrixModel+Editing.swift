//
//  PriceMatrixModel+Editing.swift
//  AppLocalizer
//

import Foundation

/// Edits to one row or the selection. Each loads Apple's price points
/// first if needed, snaps to them, and queues the result: hand edits as
/// `.you`, applied suggestions as `.suggestion`.
extension PriceMatrixModel {
    /// One price point up or down from the shown price.
    func step(_ id: PricingRow.ID, by steps: Int) async {
        guard !isReadOnly, await ensureLadders(for: [id]), let row = row(id: id),
              let point = ladder(for: row).step(from: row.shownPrice, by: steps, rounding: strategy.rounding) else { return }
        write([id: point], source: .you)
    }

    /// Sets a price picked from the nearby points or the source comparison.
    func setPrice(_ id: PricingRow.ID, to price: Decimal) async {
        guard !isReadOnly, await ensureLadders(for: [id]), let row = row(id: id) else { return }
        let ladder = ladder(for: row)
        guard let point = ladder.point(at: price) ?? ladder.nearest(to: price) else { return }
        write([id: point], source: .you)
    }

    /// Queues each territory's suggestion (or custom strategy price).
    func applySuggestion(to ids: [PricingRow.ID]) async {
        guard !isReadOnly, await ensureLadders(for: ids) else { return }
        var points: [String: PricePoint] = [:]
        for id in ids {
            guard let row = row(id: id), row.hasSuggestion else { continue }
            points[id] = row.target
        }
        write(points, source: .suggestion)
    }

    /// Drops hand edits back to what the strategy gives, as the breakdown's
    /// “Back to Suggestion” does.
    func backToSuggestion(_ id: PricingRow.ID) async {
        guard let row = row(id: id) else { return }
        if row.hasSuggestion, isFollowing || mode == .applyRecommended {
            await applySuggestion(to: [id])
        } else if let queued = row.queued {
            queue.discard(id: queued.changeID)
            queueDidChange()
        }
    }

    func multiply(_ ids: [PricingRow.ID], by factor: Decimal) async {
        await bulkEdit(ids) { rows, rounding in PriceBulkEditor.multiply(rows, by: factor, rounding: rounding) }
    }

    /// Sets each territory to feel like the base price locally.
    func feelLikeBase(_ ids: [PricingRow.ID]) async {
        let basePrice = sheet.basePrice
        await bulkEdit(ids) { rows, rounding in PriceBulkEditor.feelLikeBase(rows, basePrice: basePrice, rounding: rounding) }
    }

    func resetToEqualized(_ ids: [PricingRow.ID]) async {
        await bulkEdit(ids) { rows, _ in PriceBulkEditor.resetToEqualized(rows) }
    }

    /// Copies another subscription's prices times a ratio, such as the
    /// monthly prices × 8 for an annual plan.
    func copy(_ ids: [PricingRow.ID], from prices: [String: Decimal], ratio: Decimal) async {
        await bulkEdit(ids) { rows, rounding in PriceBulkEditor.copy(rows, from: prices, ratio: ratio, rounding: rounding) }
    }

    /// The price each territory shows, queued or current, for copying to a sibling.
    var shownPrices: [String: Decimal] {
        Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0.shownPrice) })
    }

    func selectAllVisible() {
        selection = Set(visibleRows.map(\.id))
    }

    func clearSelection() {
        selection = []
    }

    private func bulkEdit(
        _ ids: [PricingRow.ID],
        edit: ([PriceBulkRow], PriceRounding) -> [String: PricePoint]
    ) async {
        guard !isReadOnly, !ids.isEmpty, await ensureLadders(for: ids) else { return }
        let rows = ids.compactMap { row(id: $0) }.map { row in
            PriceBulkRow(
                territory: row.territory,
                ladder: ladder(for: row),
                currentPrice: row.current.customerPrice,
                proposedPrice: row.queued?.price,
                equalizedPrice: row.equalized,
                equalizationMultiplier: row.equalizationMultiplier,
                feelsLikeFactor: row.recommendation?.factor ?? 1
            )
        }
        write(edit(rows, strategy.rounding), source: .you)
    }
}
