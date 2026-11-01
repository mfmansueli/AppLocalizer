//
//  ScreenshotsViewModel+Starters.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotsViewModel {
    /// The captions gallery cards are previewed with when the primary
    /// locale has none yet.
    static var sampleCaptions: [ScreenshotCaption] {
        [
            ScreenshotCaption(headline: String(localized: "Your headline goes here"), subhead: String(localized: "A short line that supports it")),
            ScreenshotCaption(headline: String(localized: "One caption per screenshot")),
            ScreenshotCaption(headline: String(localized: "Every locale, the same layout")),
            ScreenshotCaption(headline: String(localized: "Fits every language")),
            ScreenshotCaption(headline: String(localized: "Ready for the App Store")),
        ]
    }

    /// Lays out every gallery template's first five slots with the primary
    /// locale's captions and captures, and renders them.
    func renderStarterPreviews() async {
        guard let document else { return }
        let primary = context.primaryLocale
        let engine = ScreenshotLayoutEngine(catalog: fonts)
        let slots = min(StarterPreview.slotCount, document.slotCount)
        let scripts = scopeScripts(of: document)
        starterPreviews = TemplateStarter.allCases.map { starter in
            let template = ScreenshotTemplate.starter(starter, id: app.id, title: app.name, slotCount: document.slotCount)
            let jobs = (0..<slots).map { slot in
                let caption = document.captions.caption(locale: primary.code, slot: slot) ?? Self.sampleCaptions[slot % Self.sampleCaptions.count]
                let capture = document.captures.capture(locale: primary.code, displayType: .iPhone, slot: slot, primary: primary.code)
                let layout = engine.layout(template, slot: slot, locale: primary, displayType: .iPhone, caption: caption)
                let key = RenderKey(
                    templateHash: template.contentHash, locale: primary.code, displayType: .iPhone, slot: slot,
                    caption: caption, captureID: capture?.capture.id
                )
                return RenderJob(key: key, layout: layout, capture: capture?.capture)
            }
            return StarterPreview(starter: starter, jobs: jobs, fontNote: fontNote(for: template.caption.headline.font, scripts: scripts))
        }
        renderQueue.render(starterPreviews.flatMap(\.jobs), pixelWidth: StarterPreview.pixelWidth)
    }

    /// "12 templates · previewed with Lumen’s captions and captures".
    var galleryCount: String {
        let count = TemplateStarter.starters(in: galleryStyle).count
        let title = templateEditor.templateTitle
        return count == 1
            ? String(localized: "1 template · previewed with \(title)’s captions and captures")
            : String(localized: "\(count) templates · previewed with \(title)’s captions and captures")
    }

    /// "Playfair Display (bundled) draws Latin, Cyrillic, Vietnamese.
    /// Japanese, Arabic use fallback fonts." The scripts listed last are
    /// the set's own that the font can't draw.
    func fontNote(for font: String, scripts: [ScreenshotScript]) -> String {
        let name = fonts.isBundled(font) ? String(localized: "\(font) (bundled)") : font
        let drawn = ScreenshotScript.allCases.filter { fonts.covers(font, $0.sampleText) }
        let missing = scripts.filter { !drawn.contains($0) }.map(\.title)
        let covered = drawn.map(\.title).joined(separator: ", ")
        let note = drawn.isEmpty ? String(localized: "\(name) isn’t available on this Mac.") : String(localized: "\(name) draws \(covered).")
        guard !missing.isEmpty else { return note }
        let listed = missing.count <= 4
            ? missing.joined(separator: ", ")
            : String(localized: "\(missing.prefix(3).joined(separator: ", ")) and \(missing.count - 3) more")
        return note + " " + (missing.count == 1 ? String(localized: "\(listed) uses a fallback font.") : String(localized: "\(listed) use fallback fonts."))
    }

    /// The scripts of the primary locale and the localized ones, in the
    /// order they first appear.
    private func scopeScripts(of document: ScreenshotsDocument) -> [ScreenshotScript] {
        var scripts: [ScreenshotScript] = []
        for code in [document.scope.primary] + document.scope.orderedLocales(in: locales.map(\.code)) {
            guard let locale = locales.first(where: { $0.code == code }) else { continue }
            let script = ScreenshotScript(locale: locale)
            if !scripts.contains(script) { scripts.append(script) }
        }
        return scripts
    }

    /// "52 captures from fastlane, 10 locales with their own interface."
    var captureSummary: String {
        guard let captures = document?.captures else { return "" }
        let sources = Set(captures.captures.map(\.source))
        let source = sources.count == 1 ? sources.first?.title ?? "" : String(localized: "several sources")
        let locales = captures.localesWithOwnInterface().count
        return String(localized: "\(captures.captures.count) captures from \(source), \(locales) locales with their own interface.")
    }

    /// Use This Template: the gallery template becomes the template's
    /// version 1. From the Templates sheet it's the next version instead,
    /// named like the template it replaces; captions and captures stay.
    func chooseStarter(_ starter: TemplateStarter) async {
        guard var document else { return }
        let title = document.template.map { $0.name.components(separatedBy: " · ").first ?? $0.name } ?? app.name
        let template = ScreenshotTemplate.starter(starter, id: document.template?.id ?? app.id, title: title, slotCount: document.slotCount)
        if var history = document.history {
            history.save(template, date: .now, note: String(localized: "Switched to the template “\(starter.title)”"))
            document.history = history
        } else {
            document.history = .starting(with: template, date: .now, note: String(localized: "Created from the template “\(starter.title)”"))
        }
        starterPreviews = []
        await commit(document)
    }
}
