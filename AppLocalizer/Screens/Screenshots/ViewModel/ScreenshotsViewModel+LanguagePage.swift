//
//  ScreenshotsViewModel+LanguagePage.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

// The Screenshots language page: one language's screenshots large, with the
// captions an assistant suggested drawn on them, the language bar over it,
// Accept and Dismiss per caption, Accept All Languages, and All Languages
// at a glance. Accepting writes the caption as "Proposed by Claude Code";
// the changed renders then wait in Review & Push like any others.
extension ScreenshotsViewModel {
    // MARK: - Languages

    /// The languages with their own screenshots, primary first.
    var pageLocales: [StoreLocale] {
        let codes = matrix.localizedLocales.isEmpty ? [context.primaryLocale.code] : matrix.localizedLocales
        return codes.compactMap { code in locales.first { $0.code == code } ?? StoreLocaleCatalog.locale(code: code) }
    }

    /// The language in view: the one picked, else the primary one.
    var currentPageLocale: StoreLocale {
        if let pageLocale, pageLocales.contains(pageLocale) { return pageLocale }
        return pageLocales.first ?? context.primaryLocale
    }

    /// Captions waiting to be accepted or dismissed, in every language.
    var proposedCaptions: [ProposedCaption] {
        document?.openProposedCaptions ?? []
    }

    func proposedCaptions(in locale: StoreLocale) -> [ProposedCaption] {
        proposedCaptions.filter { $0.locale == locale.code }
    }

    func proposedCaption(locale: String, slot: Int) -> ProposedCaption? {
        proposedCaptions.first { $0.locale == locale && $0.slot == slot }
    }

    func languageBarModel(acceptsRightAway: Bool) -> LanguageBarModel {
        let counts = Dictionary(grouping: proposedCaptions, by: \.locale).mapValues(\.count)
        return LanguageBarModel(
            entries: pageLocales.map { LanguageBarEntry(locale: $0, count: counts[$0.code] ?? 0) },
            current: currentPageLocale,
            acceptsRightAway: acceptsRightAway
        )
    }

    /// iPhone, iPad, Mac and the devices with screens of their own, as the
    /// set has them.
    var pageDisplays: [ScreenshotDisplayType] {
        let displays = matrix.displays.filter { matrix.slotCount(on: $0) > 0 }
        return displays.isEmpty ? [.iPhone] : displays
    }

    /// "Template: Caption above device (v4). Autopilot makes a new look."
    var templateLine: String? {
        guard let template = document?.template else { return nil }
        let version = document?.history?.currentNumber ?? 0
        let name = version > 0 ? "\(template.name) (v\(version))" : template.name
        return String(localized: "Template: \(name). Autopilot makes a new look.")
    }

    /// "Caption suggested", "Not pushed" or "Live" under a screenshot.
    func pageStatus(of cell: ScreenshotCell) -> (title: String, isSuggested: Bool) {
        if proposedCaption(locale: cell.key.locale, slot: cell.key.slot) != nil {
            return (String(localized: "Caption suggested"), true)
        }
        if cell.state.isPending { return (cell.state.title, false) }
        if cell.state.isFailed { return (cell.state.title, false) }
        return (String(localized: "Live"), false)
    }

    /// "3 captions suggested", or the language's state, for All Languages.
    func pageStatus(of locale: StoreLocale) -> String {
        let count = proposedCaptions(in: locale).count
        if count == 1 { return String(localized: "1 caption suggested") }
        if count > 1 { return String(localized: "\(count) captions suggested") }
        let pending = matrix.row(locale: locale.code, displayType: displayType).count { $0.state.isPending }
        return pending > 0 ? String(localized: "\(pending) not pushed") : String(localized: "Live")
    }

    // MARK: - Previews

    /// The slot drawn with the suggested caption, from the template.
    func proposedPreview(for caption: ProposedCaption, on display: ScreenshotDisplayType) -> SlotPreview? {
        guard let document, let template = document.template, template.slots.indices.contains(caption.slot),
              let locale = StoreLocaleCatalog.locale(code: caption.locale) else { return nil }
        let current = document.captions.caption(locale: caption.locale, slot: caption.slot)
        let proposed = caption.item.caption(over: current, provenance: .assistant(client: caption.client, date: caption.receivedAt))
        let capture = document.captures.capture(locale: caption.locale, displayType: display, slot: caption.slot, primary: context.primaryLocale.code)
        let placement = SlotPreview.Placement(template: template, locale: locale, displayType: display, slot: caption.slot)
        return SlotPreview.make(
            placement, caption: proposed, capture: capture, engine: layoutEngine, primaryLocaleName: context.primaryLocale.name, ratings: ratings
        )
    }

    /// The capture image a suggested caption's preview draws, at the
    /// language page's size; asked for when missing.
    func captureImage(for preview: SlotPreview) -> CGImage? {
        let width = Int(preview.job.layout.canvas.display.thumbnailWidth(phone: 500, tablet: 940))
        guard let capture = preview.job.capture else { return nil }
        if let image = captureImages.image(for: capture, width: width) { return image }
        captureImages.request([capture], width: width)
        return nil
    }

    /// What the caption reads now, "" without one.
    func currentHeadline(locale: String, slot: Int) -> String {
        document?.captions.caption(locale: locale, slot: slot)?.headline ?? ""
    }

    // MARK: - Accept All

    func acceptAllCaptionsSelection() -> AcceptAllSelection {
        let groups = pageLocales.compactMap { locale -> AcceptAllGroup? in
            let items = proposedCaptions(in: locale).map { caption in
                AcceptAllItem(
                    id: caption.id,
                    title: caption.title,
                    source: caption.source,
                    current: currentHeadline(locale: caption.locale, slot: caption.slot),
                    suggested: caption.item.headline,
                    reason: caption.reason
                )
            }
            guard !items.isEmpty else { return nil }
            return AcceptAllGroup(id: locale.code, title: locale.name, regionCode: locale.regionCode, isRightToLeft: locale.isRTL, items: items)
        }
        return AcceptAllSelection(kind: .screenshots, groups: groups, focus: currentPageLocale.code)
    }

    /// The language bar's Accept All Languages: right away when the person
    /// said not to ask, otherwise the sheet.
    func acceptAllCaptions(withoutAsking: Bool) async {
        guard withoutAsking else {
            isAcceptAllCaptionsPresented = true
            return
        }
        let captions = proposedCaptions
        await decide(Set(captions.map(\.id)), accept: true, toast: AcceptAllKind.screenshots.acceptedText(
            captions.count, groups: Set(captions.map(\.locale)).count, withoutAsking: true
        ))
    }

    /// The sheet's Accept: what was left ticked.
    func acceptCaptions(ids: Set<String>, turnedOffAsking: Bool) async {
        isAcceptAllCaptionsPresented = false
        let captions = proposedCaptions.filter { ids.contains($0.id) }
        await decide(Set(captions.map(\.id)), accept: true, toast: AcceptAllKind.screenshots.acceptedText(
            captions.count, groups: Set(captions.map(\.locale)).count, turnedOffAsking: turnedOffAsking
        ))
    }

    /// "Accept 3 in German".
    func acceptCaptionsHere() async {
        let locale = currentPageLocale
        let captions = proposedCaptions(in: locale)
        let text = captions.count == 1
            ? String(localized: "Accepted 1 caption in \(locale.name). It’s in Review & Push.")
            : String(localized: "Accepted \(captions.count) captions in \(locale.name). They’re in Review & Push.")
        await decide(Set(captions.map(\.id)), accept: true, toast: text)
    }

    func acceptCaption(_ caption: ProposedCaption) async {
        await decide([caption.id], accept: true, toast: String(localized: "Screenshot \(caption.slot + 1) caption accepted. It’s in Review & Push."))
    }

    func dismissCaption(_ caption: ProposedCaption) async {
        await decide([caption.id], accept: false, toast: String(localized: "Screenshot \(caption.slot + 1) caption dismissed."), offersReview: false)
    }

    /// Use and Edit: accepts the caption and opens it in Captions, to edit
    /// there.
    func useAndEditCaption(_ caption: ProposedCaption) async {
        await decide([caption.id], accept: true, toast: nil)
        tab = .captions
        captions.select(caption.key)
    }

    func undoCaptionToast() async {
        let undo = captionUndo
        captionUndo = nil
        captionToast = nil
        await undo?()
    }

    private func decide(_ ids: Set<String>, accept: Bool, toast text: String?, offersReview: Bool = true) async {
        guard var document, !ids.isEmpty else { return }
        let before = document
        guard document.decideCaptions(ids, accept: accept, date: .now) > 0 else { return }
        await commit(document)
        captionUndo = { [weak self] in await self?.commit(before) }
        if let text {
            captionToast = ToastMessage(text: text, canUndo: true, actionTitle: accept && offersReview ? String(localized: "Review & Push") : nil)
        }
    }
}
