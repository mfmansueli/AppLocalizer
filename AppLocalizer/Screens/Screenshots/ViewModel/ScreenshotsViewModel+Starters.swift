//
//  ScreenshotsViewModel+Starters.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotsViewModel {
    /// The captions starter cards are previewed with when the primary
    /// locale has none yet.
    static var sampleCaptions: [ScreenshotCaption] {
        [
            ScreenshotCaption(headline: String(localized: "Your headline goes here"), subhead: String(localized: "A short line that supports it")),
            ScreenshotCaption(headline: String(localized: "One caption per screenshot")),
            ScreenshotCaption(headline: String(localized: "Every locale, the same layout")),
        ]
    }

    /// Lays out the three starters' first slots with the primary locale's
    /// captions and captures, and renders them.
    func renderStarterPreviews() async {
        guard let document else { return }
        let primary = context.primaryLocale
        let engine = ScreenshotLayoutEngine(catalog: fonts)
        let slots = min(3, document.slotCount)
        starterPreviews = TemplateStarter.allCases.map { starter in
            let template = ScreenshotTemplate.starter(starter, id: app.id, title: app.name, slotCount: document.slotCount)
            let jobs = (0..<slots).map { slot in
                let caption = document.captions.caption(locale: primary.code, slot: slot) ?? Self.sampleCaptions[slot]
                let capture = document.captures.capture(locale: primary.code, displayType: .iPhone, slot: slot, primary: primary.code)
                let layout = engine.layout(template, slot: slot, locale: primary, displayType: .iPhone, caption: caption)
                let key = RenderKey(
                    templateHash: template.contentHash, locale: primary.code, displayType: .iPhone, slot: slot,
                    caption: caption, captureID: capture?.capture.id
                )
                return RenderJob(key: key, layout: layout, capture: capture?.capture)
            }
            return StarterPreview(starter: starter, jobs: jobs)
        }
        renderQueue.render(starterPreviews.flatMap(\.jobs), pixelWidth: StarterPreview.pixelWidth)
    }

    /// "52 captures from fastlane, 10 locales with their own interface."
    var captureSummary: String {
        guard let captures = document?.captures else { return "" }
        let sources = Set(captures.captures.map(\.source))
        let source = sources.count == 1 ? sources.first?.title ?? "" : String(localized: "several sources")
        let locales = captures.localesWithOwnInterface().count
        return String(localized: "\(captures.captures.count) captures from \(source), \(locales) locales with their own interface.")
    }

    /// Use This Template: the starter becomes the template's version 1.
    /// From the Template tab's sheet it's the next version instead, named
    /// like the template it replaces; captions and captures stay.
    func chooseStarter(_ starter: TemplateStarter) async {
        guard var document else { return }
        let title = document.template.map { $0.name.components(separatedBy: " · ").first ?? $0.name } ?? app.name
        let template = ScreenshotTemplate.starter(starter, id: document.template?.id ?? app.id, title: title, slotCount: document.slotCount)
        if var history = document.history {
            history.save(template, date: .now, note: String(localized: "Switched to the starter “\(starter.title)”"))
            document.history = history
        } else {
            document.history = .starting(with: template, date: .now, note: String(localized: "Created from the starter “\(starter.title)”"))
        }
        starterPreviews = []
        await commit(document)
    }
}
