//
//  ScreenshotMatrixBuilder.swift
//  AppLocalizer
//

import Foundation

/// Builds the Sets matrix from a snapshot: lays out and checks every
/// localized cell, compares it with what's live, and fills the other rows
/// with the live set or the primary locale's renders. Pure and
/// thread-safe; the view model runs it off the main actor.
struct ScreenshotMatrixBuilder {
    func build(_ snapshot: ScreenshotsSnapshot) -> ScreenshotMatrix {
        let document = snapshot.document
        let scope = document.scope
        let order = snapshot.locales.map(\.code)
        let localized = scope.orderedLocales(in: order).filter { !scope.isPinned($0) }
        let restored = order.filter { scope.isPinned($0) }
        let fallback = order.filter { !scope.contains($0) && !scope.isPinned($0) }
        var matrix = ScreenshotMatrix(
            slotCount: document.slotCount, cells: [:], localizedLocales: localized, restoredLocales: restored,
            fallbackLocales: fallback, hasTemplate: document.template != nil, hasCaptures: !document.captures.isEmpty
        )
        for display in ScreenshotDisplayType.ownScreens {
            let count = document.slotCount(on: display)
            if count > 0 { matrix.ownSlotCounts[display] = count }
        }
        let engine = ScreenshotLayoutEngine(catalog: snapshot.fonts)
        for display in document.displays {
            for slot in 0..<document.slotCount(on: display) {
                for code in localized {
                    guard let locale = snapshot.locale(code: code) else { continue }
                    let key = ScreenshotCellKey(locale: code, displayType: display, slot: slot)
                    matrix.cells[key] = managedCell(key, locale: locale, snapshot: snapshot, engine: engine)
                }
                let primary = matrix.cell(locale: scope.primary, displayType: display, slot: slot)
                for code in restored + fallback {
                    let key = ScreenshotCellKey(locale: code, displayType: display, slot: slot)
                    matrix.cells[key] = otherCell(key, isPinned: scope.isPinned(code), primary: primary, live: snapshot.live)
                }
            }
        }
        return matrix
    }

    /// A cell rendered from the template.
    private func managedCell(_ key: ScreenshotCellKey, locale: StoreLocale, snapshot: ScreenshotsSnapshot, engine: ScreenshotLayoutEngine) -> ScreenshotCell {
        let document = snapshot.document
        let live = snapshot.live.screenshot(locale: key.locale, displayType: key.displayType, slot: key.slot)
        var cell = ScreenshotCell(
            key: key, state: .empty, image: .none, caption: nil, capture: nil, checks: [],
            showsPrimaryInterface: false, proposal: document.proposal(locale: key.locale, slot: key.slot)?.source, live: live
        )
        guard let template = document.template else {
            if let live {
                cell.state = .uploadedByHand
                cell.image = .live(live)
            }
            return cell
        }
        let capture = document.captures.capture(locale: key.locale, displayType: key.displayType, slot: key.slot, primary: document.scope.primary)
        let captionSlot = document.captionSlot(key.slot, on: key.displayType)
        let caption = captionSlot.flatMap { document.captions.caption(locale: key.locale, slot: $0) }
        let templateSlot = min(captionSlot ?? key.slot, max(0, template.slots.count - 1))
        let layout = engine.layout(
            template, slot: templateSlot, locale: locale, displayType: key.displayType, caption: caption,
            captureSize: capture?.capture.pixelSize
        )
        let renderKey = RenderKey(
            templateHash: template.contentHash, locale: key.locale, displayType: key.displayType, slot: key.slot,
            caption: caption, captureID: capture?.capture.id
        )
        cell.caption = caption
        cell.capture = capture
        cell.showsPrimaryInterface = capture.map { !$0.isInterfaceLocalized } ?? false
        cell.checks = ScreenshotChecker.checks(for: layout, capture: capture, primaryLocaleName: snapshot.primaryLocale.name, ratings: snapshot.ratings)
        cell.image = .render(RenderJob(key: renderKey, layout: layout, capture: capture?.capture))
        cell.state = state(of: cell, renderKey: renderKey, pushed: document.pushedRender(for: key))
        return cell
    }

    private func state(of cell: ScreenshotCell, renderKey: RenderKey, pushed: PushedRender?) -> ScreenshotCellState {
        if cell.capture == nil { return .noCapture }
        if cell.caption == nil, cell.key.displayType.hasCaptions { return .noCaption }
        if let failure = cell.firstFailure { return .failed(reason: failure.shortReason ?? String(localized: "Check failed")) }
        if let live = cell.live, let pushed, pushed.renderKey == renderKey, pushed.checksum == live.checksum { return .live }
        return .notPushed
    }

    /// A restored row's or an out-of-scope row's cell: what's live there,
    /// else the primary locale's render, dimmed.
    private func otherCell(_ key: ScreenshotCellKey, isPinned: Bool, primary: ScreenshotCell?, live: LiveScreenshots) -> ScreenshotCell {
        let shot = live.screenshot(locale: key.locale, displayType: key.displayType, slot: key.slot)
        var cell = ScreenshotCell(
            key: key, state: .fallback, image: primary?.image ?? .none, caption: nil, capture: nil, checks: [],
            showsPrimaryInterface: false, proposal: nil, live: shot
        )
        if isPinned {
            cell.state = .restored
            cell.image = shot.map(CellImageSource.live) ?? .none
        } else if let shot {
            cell.state = .uploadedByHand
            cell.image = .live(shot)
        } else if live.hasOwnSet(locale: key.locale) {
            cell.state = .uploadedByHand
            cell.image = .none
        }
        return cell
    }
}
