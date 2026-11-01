//
//  TemplateEditorViewModel+Previews.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

// The canvas and the stress strip, laid out from the draft on every edit.
// They're drawn straight from the layout, never cached as renders: a
// draft's renders would only fill the cache with images nobody pushes.
extension TemplateEditorViewModel {
    /// Everything the previews depend on; the view relays out when it
    /// changes.
    struct PreviewInputs: Hashable {
        var template: ScreenshotTemplate?
        var captions: CaptionBook?
        var previewCaptions: [LocaleSlot: ScreenshotCaption]
        var slot: Int
        var locale: String
        var displayType: ScreenshotDisplayType
        var fonts: ScreenshotFontCatalog
        var ratings: StoreRatings
    }

    var previewInputs: PreviewInputs {
        PreviewInputs(
            template: template, captions: screenshots.document?.captions, previewCaptions: previewCaptions, slot: slot,
            locale: localeCode, displayType: displayType, fonts: screenshots.fonts,
            ratings: screenshots.ratings
        )
    }

    /// Lays out the canvas and the strip, then fetches what they're
    /// missing: capture images and preview translations.
    func refreshPreviews() {
        guard let template, let document = screenshots.document else {
            canvas = nil
            strip = []
            return
        }
        let engine = ScreenshotLayoutEngine(catalog: screenshots.fonts)
        let primary = screenshots.context.primaryLocale
        let slot = min(slot, template.slots.count - 1)
        let capture = { [displayType] (code: String) in
            document.captures.capture(locale: code, displayType: displayType, slot: slot, primary: primary.code)
        }
        let inputs = StressStripPlanner.Inputs(
            template: template, slot: slot, displayType: displayType, primary: primary,
            ownCaption: { document.captions.caption(locale: $0, slot: slot) },
            previewCaption: { [previewCaptions] in previewCaptions[LocaleSlot(locale: $0, slot: slot)] },
            capture: capture
        )
        strip = StressStripPlanner(engine: engine).entries(inputs)
        canvas = SlotPreview.make(
            SlotPreview.Placement(template: template, locale: locale, displayType: displayType, slot: slot),
            caption: canvasCaption(inputs), capture: capture(localeCode), engine: engine, primaryLocaleName: primary.name,
            ratings: screenshots.ratings
        )
        screenshots.lookUpRatings(for: template)
        requestPreviewTranslations()
        loadCaptureImages()
    }

    /// The canvas shows the locale's caption, else its preview
    /// translation, else the primary's.
    private func canvasCaption(_ inputs: StressStripPlanner.Inputs) -> ScreenshotCaption? {
        inputs.ownCaption(localeCode) ?? inputs.previewCaption(localeCode)
            ?? (localeCode == inputs.primary.code ? nil : inputs.ownCaption(inputs.primary.code))
    }

    // MARK: - Capture images

    /// Twice the canvas's width: 500 px for iPhone, 940 for iPad, iPhone
    /// Duo's at the iPhone's height.
    var captureImageWidth: Int { Int(displayType.thumbnailWidth(phone: 500, tablet: 940)) }

    /// The capture image a preview draws, once loaded.
    func captureImage(for preview: SlotPreview) -> CGImage? {
        screenshots.captureImages.image(for: preview.job.capture, width: captureImageWidth)
    }

    private func loadCaptureImages() {
        let previews = [canvas].compactMap(\.self) + strip.map(\.preview)
        screenshots.captureImages.request(previews.compactMap(\.job.capture), width: captureImageWidth)
    }

    // MARK: - Preview translations

    /// Stress locales without a caption get the primary caption
    /// translated, for the strip only: "Longest · preview translation".
    /// Asked once per locale and slot; a locale the translator can't do
    /// keeps showing the primary caption.
    func requestPreviewTranslations() {
        let primary = screenshots.context.primaryLocale
        let wanted = strip.filter { $0.captionSource == .primaryStandIn }.map(\.locale)
            + StressStripPlanner.longestCandidates.compactMap(screenshots.locale(code:))
        for target in wanted where target != primary {
            let key = LocaleSlot(locale: target.code, slot: slot)
            guard !requestedPreviews.contains(key), screenshots.document?.captions.caption(locale: target.code, slot: slot) == nil,
                  let source = screenshots.document?.captions.caption(locale: primary.code, slot: slot) else { continue }
            requestedPreviews.insert(key)
            Task { [weak self, translator = screenshots.services.translator] in
                guard await translator.availability(from: primary, to: target) == .ready,
                      let headline = try? await translator.translateCaption(source.headline, from: primary, to: target) else { return }
                var subhead: String?
                if let text = source.visibleSubhead { subhead = try? await translator.translateCaption(text, from: primary, to: target) }
                self?.previewCaptions[key] = ScreenshotCaption(headline: headline, subhead: subhead, provenance: .machineTranslated)
            }
        }
    }
}
