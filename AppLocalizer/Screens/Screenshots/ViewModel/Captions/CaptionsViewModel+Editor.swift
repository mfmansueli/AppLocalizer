//
//  CaptionsViewModel+Editor.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

// The editor panel: the source, the live fit and preview, Mark Reviewed
// and "Suggest a Shorter Version".
extension CaptionsViewModel {
    /// "German · slot 3".
    var editorTitle: String {
        guard let selection, let locale = selectedLocale else { return "" }
        return String(localized: "\(locale.name) · slot \(selection.slot + 1)")
    }

    /// "Search · iPhone 6.9″".
    var editorSubtitle: String {
        guard let selection else { return "" }
        return "\(screenshots.document?.slotName(selection.slot) ?? "") · \(screenshots.displayType.title)"
    }

    /// The primary caption, shown above another locale's fields.
    var sourceHeadline: String? {
        guard let selection, selection.locale != screenshots.context.primaryLocale.code else { return nil }
        return screenshots.document?.captions.caption(locale: screenshots.context.primaryLocale.code, slot: selection.slot)?.headline
    }

    var isRightToLeft: Bool {
        selectedLocale.map { ScreenshotScript(locale: $0).isRightToLeft } ?? false
    }

    var showsSubheadField: Bool {
        guard let selection else { return false }
        return screenshots.document?.template?.isHero(slot: selection.slot) ?? (selection.slot == 0)
    }

    var headlinePlaceholder: String {
        selection?.locale == screenshots.context.primaryLocale.code
            ? String(localized: "Say what this screen does for people")
            : String(localized: "Translate or write a caption")
    }

    // MARK: - Live fit

    /// The slot laid out with the fields as typed: the meter, the labels
    /// and the preview follow every keystroke.
    var editorPreview: SlotPreview? {
        guard let selection, let locale = selectedLocale, let document = screenshots.document,
              let template = document.template else { return nil }
        let primary = screenshots.context.primaryLocale
        return SlotPreview.make(
            SlotPreview.Placement(template: template, locale: locale, displayType: screenshots.displayType, slot: selection.slot),
            caption: editedCaption,
            capture: document.captures.capture(locale: locale.code, displayType: screenshots.displayType, slot: selection.slot, primary: primary.code),
            engine: ScreenshotLayoutEngine(catalog: screenshots.fonts), primaryLocaleName: primary.name
        )
    }

    /// "3 lines of 2 · 80 u (template 112, smallest 80)".
    var fitDetail: String {
        guard let fit = editorPreview?.fit, !fit.isEmpty else { return String(localized: "Fit is measured as you type.") }
        let lines = fit.lines.count == 1 ? String(localized: "1 line") : String(localized: "\(fit.lines.count) lines")
        let size = Int(fit.size.rounded())
        return String(localized: "\(lines) of \(fit.maxLines) · \(size) u (template \(Int(fit.fullSize.rounded())), smallest \(Int(fit.minimumSize.rounded())))")
    }

    /// The preview's width: 150 pt for iPhone, 270 for iPad.
    var previewWidth: CGFloat { screenshots.displayType.isTablet ? 270 : 150 }

    var previewPixelWidth: Int { Int(previewWidth * 2) }

    func previewCapture(for preview: SlotPreview) -> CGImage? {
        screenshots.captureImages.image(for: preview.job.capture, width: previewPixelWidth)
    }

    func loadPreviewCapture() {
        guard let capture = editorPreview?.job.capture else { return }
        screenshots.captureImages.request([capture], width: previewPixelWidth)
    }

    // MARK: - Tags

    var isMachineTranslated: Bool { selectedCaption?.provenance.isMachineTranslated == true && !hasPendingEdit }

    /// "Proposed by Claude Code · 10:43".
    var assistantNote: (client: String, text: String)? {
        guard let caption = selectedCaption, case let .assistant(client, _) = caption.provenance else { return nil }
        return (client, caption.provenance.title)
    }

    // MARK: - A shorter version

    /// Offered for another locale's caption that shrinks or overflows.
    var canSuggestShorter: Bool {
        guard let selection, selection.locale != screenshots.context.primaryLocale.code, suggestion == nil, !isSuggesting,
              let fit = editorPreview?.fit else { return false }
        return fit.tone == .overflows || fit.tone == .shrinks
    }

    /// Asks the translation provider for the primary caption again and
    /// offers the result when it's shorter than what's there.
    func suggestShorter() async {
        guard let selection, let locale = selectedLocale, let source = sourceHeadline, let current = editorPreview?.fit else { return }
        isSuggesting = true
        suggestionMessage = nil
        defer { isSuggesting = false }
        let translator = screenshots.services.translator
        let primary = screenshots.context.primaryLocale
        guard await translator.availability(from: primary, to: locale) == .ready else {
            suggestionMessage = String(localized: "Apple Translation needs \(locale.name) downloaded first. Translate Missing… can download it.")
            return
        }
        do {
            let text = try await translator.translateCaption(source, from: primary, to: locale)
            guard self.selection == selection, let fit = measure(headline: text) else { return }
            guard fit.fill < current.fill, text != headline else {
                suggestionMessage = String(localized: "Apple Translation’s version isn’t any shorter.")
                return
            }
            suggestion = CaptionSuggestion(key: selection, headline: text, providerTitle: TranslationProvider.appleTranslation.shortTitle, fit: fit)
        } catch {
            suggestionMessage = error.localizedDescription
        }
    }

    /// Use This: the suggestion becomes the caption, tagged
    /// machine-translated.
    func useSuggestion() async {
        guard let suggestion, suggestion.key == selection, var document = screenshots.document else { return }
        let caption = ScreenshotCaption(headline: suggestion.headline, subhead: editedCaption?.visibleSubhead, provenance: .machineTranslated)
        document.captions.setCaption(caption, locale: suggestion.key.locale, slot: suggestion.key.slot)
        showSaved(caption)
        await screenshots.commit(document)
    }

    /// Keep Mine.
    func keepMine() {
        suggestion = nil
    }

    private func measure(headline text: String) -> CaptionFit? {
        guard let selection, let locale = selectedLocale, let template = screenshots.document?.template else { return nil }
        let caption = ScreenshotCaption(headline: text, subhead: subhead.isEmpty ? nil : subhead)
        return ScreenshotLayoutEngine(catalog: screenshots.fonts)
            .layout(template, slot: selection.slot, locale: locale, displayType: screenshots.displayType, caption: caption).headline
    }
}
