//
//  StudioPreviewBuilder.swift
//  AppLocalizer
//

import Foundation

/// Builds the App Store preview for one device, language and set from
/// what's live and the Sets matrix: what the App Store shows in that
/// language (the primary language's set when it has none, the iPhone set
/// on iPad with no iPad set), or the new set waiting in Review & Push.
struct StudioPreviewBuilder {
    var displayType: ScreenshotDisplayType
    var locale: String
    var primaryLocale: StoreLocale
    var choice: StudioSetChoice
    var matrix: ScreenshotMatrix
    var live: LiveScreenshots
    var slotNames: [String]
    /// Apple Watch's and Apple Vision Pro's screen names.
    var ownSlotNames: [ScreenshotDisplayType: [String]] = [:]
    var storeTexts: StudioStoreTexts
    var appName: String
    /// The template's name and version, e.g. "Quiet Indigo" and 5.
    var templateName: String?
    var run: AutopilotRun?
    /// The checksums of what AppLocalizer pushed: a live Apple Watch or
    /// Apple Vision Pro set is AppLocalizer's only when all of it is here.
    var pushedChecksums: Set<String> = []

    /// Rendered, not pushed: the header's New is enabled.
    var hasNewSet: Bool {
        matrix.hasTemplate && matrix.pendingCount > 0
    }

    /// New without a new set shows Live.
    var effectiveChoice: StudioSetChoice {
        choice == .new && hasNewSet ? .new : .live
    }

    func preview() -> StudioPreview {
        let primary = primaryLocale.code
        var preview = StudioPreview(
            name: storeTexts.name(for: locale, primary: primary) ?? appName,
            subtitle: storeTexts.subtitle(for: locale, primary: primary),
            getTitle: StoreGetTitle.title(for: locale),
            statsLine: nil,
            isRightToLeft: localeInfo(locale)?.isRTL ?? false,
            displayType: displayType,
            note: "",
            shots: [],
            searchNote: ""
        )
        switch effectiveChoice {
        case .live: fillLive(&preview)
        case .new: fillNew(&preview)
        }
        return preview
    }

    // MARK: - Live

    private func fillLive(_ preview: inout StudioPreview) {
        if displayType.hasOwnScreens {
            fillLiveOwn(&preview)
            return
        }
        guard let found = liveSet() else {
            preview.note = String(localized: "Nothing live yet")
            preview.searchNote = String(localized: "Search results show the first screenshots once there are some.")
            return
        }
        preview.displayType = found.display
        let chip: StudioShotChip? = found.fellBack ? .fallback(language: primaryLocale.shortName) : nil
        let ownLocale = found.fellBack ? primaryLocale.code : locale
        preview.shots = found.set.screenshots.enumerated().map { slot, shot in
            StudioShot(
                slot: slot, name: slotName(slot), image: liveImage(shot, locale: ownLocale, display: found.display, slot: slot),
                pixelSize: shot.pixelSize ?? found.display.defaultPixelSize, chip: chip
            )
        }
        if found.fellBack {
            let name = localeInfo(locale)?.shortName ?? locale
            preview.note = String(localized: "Live now · \(name) falls back to \(primaryLocale.name)")
        } else if found.display != displayType {
            preview.note = String(localized: "Live now · no \(displayType.shortTitle) screenshots, so \(displayType.shortTitle) shows these")
        } else {
            preview.note = String(localized: "Live now · \(madeTitle(locale: locale, display: found.display))")
        }
        preview.searchNote = String(localized: "The first screenshots, at the size search results show them.")
    }

    /// Apple Watch's or Apple Vision Pro's live set: this language's, else
    /// the primary language's. Neither falls back to iPhone.
    private func fillLiveOwn(_ preview: inout StudioPreview) {
        let display = displayType
        let own = live.set(locale: locale, displayType: display).flatMap { $0.screenshots.isEmpty ? nil : $0 }
        let primarySet = live.set(locale: primaryLocale.code, displayType: display).flatMap { $0.screenshots.isEmpty ? nil : $0 }
        preview.searchNote = Self.searchNote(on: display, hasShots: own ?? primarySet != nil)
        guard let set = own ?? primarySet else {
            preview.note = String(localized: "Live now · no \(display.title) screenshots")
            preview.emptyText = display == .watch
                ? String(localized: "No Apple Watch screenshots yet. The product page shows the iPhone set until there are some.")
                : String(localized: "No Apple Vision Pro screenshots yet. App Store Connect needs at least one before you can submit for visionOS.")
            return
        }
        let fellBack = own == nil && locale != primaryLocale.code
        let chip: StudioShotChip? = fellBack ? .fallback(language: primaryLocale.shortName) : nil
        preview.shots = set.screenshots.enumerated().map { slot, shot in
            StudioShot(
                slot: slot, name: slotName(slot, on: display), image: .live(shot),
                pixelSize: shot.pixelSize ?? display.defaultPixelSize, chip: chip
            )
        }
        if fellBack {
            let name = localeInfo(locale)?.shortName ?? locale
            preview.note = String(localized: "Live now · \(name) falls back to \(primaryLocale.name)")
        } else {
            let count = set.screenshots.count
            let language = localeInfo(set.locale)?.shortName ?? set.locale
            let shots = switch (display, count) {
            case (.watch, 1): String(localized: "1 \(language) capture")
            case (.watch, _): String(localized: "\(count) \(language) captures")
            case (_, 1): String(localized: "1 screenshot")
            default: String(localized: "\(count) screenshots")
            }
            let isAppLocalizers = set.screenshots.allSatisfy { $0.checksum.map(pushedChecksums.contains) ?? false }
            let made = isAppLocalizers ? String(localized: "made with AppLocalizer") : String(localized: "uploaded by hand")
            preview.note = String(localized: "Live now · \(shots), \(made)")
        }
    }

    /// What search shows on a device with screens of its own.
    static func searchNote(on display: ScreenshotDisplayType, hasShots: Bool) -> String {
        if display == .watch {
            return String(
                localized: "Apple Watch screenshots don’t show in search results on iPhone. People see them on the product page, under “Apple Watch”."
            )
        }
        return hasShots
            ? String(localized: "On Apple Vision Pro, search shows the first screenshot large.")
            : String(localized: "Nothing to show in search on Apple Vision Pro yet.")
    }

    /// The set the App Store shows: this language's, else the primary
    /// language's; on iPad without one, the iPhone set.
    private func liveSet() -> (set: LiveScreenshotSet, display: ScreenshotDisplayType, fellBack: Bool)? {
        let displays = displayType == .iPhone ? [ScreenshotDisplayType.iPhone] : [displayType, .iPhone]
        for display in displays {
            if let set = live.set(locale: locale, displayType: display) { return (set, display, false) }
            if let set = live.set(locale: primaryLocale.code, displayType: display) {
                return (set, display, locale != primaryLocale.code)
            }
        }
        return nil
    }

    /// A live screenshot AppLocalizer pushed draws from its render, here,
    /// instead of downloading it; the others load from App Store Connect.
    private func liveImage(_ shot: LiveScreenshot, locale: String, display: ScreenshotDisplayType, slot: Int) -> CellImageSource {
        if let cell = matrix.cell(locale: locale, displayType: display, slot: slot), cell.state == .live,
           cell.live?.id == shot.id, cell.image.renderJob != nil
        {
            return cell.image
        }
        return .live(shot)
    }

    /// "uploaded by hand" or "made with AppLocalizer".
    private func madeTitle(locale: String, display: ScreenshotDisplayType) -> String {
        let states = matrix.row(locale: locale, displayType: display).map(\.state)
        if states.contains(.uploadedByHand) { return String(localized: "uploaded by hand") }
        if states.contains(.live) || states.contains(.notPushed) { return String(localized: "made with AppLocalizer") }
        return String(localized: "in App Store Connect")
    }

    // MARK: - New

    private func fillNew(_ preview: inout StudioPreview) {
        let primary = primaryLocale.code
        let rowLocale = matrix.localizedLocales.contains(locale) ? locale : primary
        if displayType.hasOwnScreens {
            fillNewOwn(&preview, rowLocale: rowLocale)
            return
        }
        var display = displayType
        var cells = matrix.row(locale: rowLocale, displayType: display)
        if cells.isEmpty, display != .iPhone {
            display = .iPhone
            cells = matrix.row(locale: rowLocale, displayType: display)
        }
        preview.displayType = display
        preview.shots = cells.map { cell in
            StudioShot(
                slot: cell.key.slot, name: slotName(cell.key.slot), image: cell.image,
                pixelSize: cell.layout?.canvas.pixelSize ?? display.defaultPixelSize,
                chip: newChip(for: cell, fellBack: rowLocale != locale)
            )
        }
        var note = [String(localized: "New set")]
        if let name = newSetName { note.append(name) }
        note.append(String(localized: "not pushed"))
        if rowLocale != locale { note.append(String(localized: "\(primaryLocale.shortName) until this language is localized")) }
        preview.note = note.joined(separator: " · ")
        preview.searchNote = String(localized: "The new headlines, at the size search results show them.")
    }

    /// Apple Watch's real captures, or Apple Vision Pro's windows.
    private func fillNewOwn(_ preview: inout StudioPreview, rowLocale: String) {
        let display = displayType
        let cells = matrix.row(locale: rowLocale, displayType: display)
        preview.searchNote = Self.searchNote(on: display, hasShots: !cells.isEmpty)
        guard !cells.isEmpty else {
            preview.note = String(localized: "New set · no \(display.title) screenshots")
            preview.emptyText = run.map { !$0.plan.displayTypes.contains(display) } == true
                ? String(localized: "Not in this set: \(display.title) was turned off in the Autopilot plan.")
                : String(localized: "Not in this set yet. Run Autopilot with \(display.title) in the plan to make its screenshots.")
            return
        }
        preview.shots = cells.map { cell in
            StudioShot(
                slot: cell.key.slot, name: slotName(cell.key.slot, on: display), image: cell.image,
                pixelSize: cell.layout?.canvas.pixelSize ?? display.defaultPixelSize,
                chip: newChip(for: cell, fellBack: rowLocale != locale)
            )
        }
        if display == .watch {
            preview.note = String(localized: "New set · real captures in every language, no captions: the watch screen is too small for them")
        } else {
            let parts = [String(localized: "New set"), newSetName, String(localized: "each screen in its own window")]
            preview.note = parts.compactMap(\.self).joined(separator: " · ")
        }
    }

    private func newChip(for cell: ScreenshotCell, fellBack: Bool) -> StudioShotChip? {
        if fellBack { return .fallback(language: primaryLocale.shortName) }
        if run?.shortenings.contains(where: { $0.locale == cell.key.locale && $0.slot == cell.key.slot }) == true { return .shortened }
        return cell.state.isPending ? .new : nil
    }

    /// The chosen direction's name, else the template's.
    var newSetName: String? {
        if let run, run.stage == .ready, let direction = run.chosenDirection { return direction.name }
        return templateName
    }

    // MARK: - Helpers

    private func slotName(_ slot: Int) -> String {
        slotNames.indices.contains(slot) ? slotNames[slot] : String(localized: "Slot \(slot + 1)")
    }

    private func slotName(_ slot: Int, on display: ScreenshotDisplayType) -> String {
        guard display.hasOwnScreens else { return slotName(slot) }
        let names = ownSlotNames[display] ?? []
        return names.indices.contains(slot) ? names[slot] : String(localized: "Screen \(slot + 1)")
    }

    func localeInfo(_ code: String) -> StoreLocale? {
        storeTexts.locales.first { $0.code == code } ?? StoreLocaleCatalog.locale(code: code)
    }
}
