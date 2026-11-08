//
//  ScreenshotsViewModel+Starters.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

extension ScreenshotsViewModel {
    /// The captions gallery cards are previewed with when the primary
    /// locale has none yet.
    static var sampleCaptions: [ScreenshotCaption] {
        [
            ScreenshotCaption(headline: String(localized: "Your headline goes here"), subhead: String(localized: "A short line that supports it")),
            ScreenshotCaption(headline: String(localized: "One caption per screenshot")),
            ScreenshotCaption(headline: String(localized: "Every locale, the same layout"), kicker: String(localized: "A short topic")),
            ScreenshotCaption(headline: String(localized: "Fits every language"), kicker: String(localized: "Every language")),
            ScreenshotCaption(headline: String(localized: "Ready for the App Store"), kicker: String(localized: "Ready to ship")),
        ]
    }

    /// Lays out every gallery template's first five slots with the primary
    /// locale's captions and captures, and renders them.
    func renderStarterPreviews() async {
        guard let document else { return }
        let engine = layoutEngine
        let scripts = scopeScripts(of: document)
        starterPreviews = TemplateStarter.allCases.map { starter in
            let template = ScreenshotTemplate.starter(starter, id: app.id, title: app.name, slotCount: document.slotCount)
            let jobs = starterJobs(template, document: document, locale: context.primaryLocale, engine: engine)
            return StarterPreview(starter: starter, jobs: jobs, fontNote: fontNote(for: template.caption.headline.font, scripts: scripts))
        }
        renderQueue.render(starterPreviews.flatMap(\.jobs), pixelWidth: StarterPreview.pixelWidth)
    }

    /// `starter`'s first five slots laid out in `code`, with its captions
    /// (the primary language's where it has none yet) and captures: the
    /// guided Look step previews a template in another language. Nothing
    /// is rendered here.
    func starterJobs(_ starter: TemplateStarter, locale code: String) -> [RenderJob] {
        guard let document else { return [] }
        let primary = context.primaryLocale
        let locale = code == primary.code ? primary : locales.first { $0.code == code } ?? primary
        let template = ScreenshotTemplate.starter(starter, id: app.id, title: app.name, slotCount: document.slotCount)
        return starterJobs(template, document: document, locale: locale, engine: layoutEngine)
    }

    private func starterJobs(
        _ template: ScreenshotTemplate, document: ScreenshotsDocument, locale: StoreLocale, engine: ScreenshotLayoutEngine
    ) -> [RenderJob] {
        let primary = context.primaryLocale.code
        let slots = min(StarterPreview.slotCount, document.slotCount)
        return (0..<slots).map { slot in
            let caption = document.captions.caption(locale: locale.code, slot: slot)
                ?? document.captions.caption(locale: primary, slot: slot)
                ?? Self.sampleCaptions[slot % Self.sampleCaptions.count]
            let capture = document.captures.capture(locale: locale.code, displayType: .iPhone, slot: slot, primary: primary)
            // Two phones shows the slot before it behind.
            let behind = capture == nil ? nil : template.behindSlot(slot, templateSlot: slot, count: slots).flatMap {
                document.captures.capture(locale: locale.code, displayType: .iPhone, slot: $0, primary: primary)?.capture
            }
            let layout = engine.layout(template, slot: slot, locale: locale, displayType: .iPhone, caption: caption)
            let key = RenderKey(
                templateHash: template.contentHash, locale: locale.code, displayType: .iPhone, slot: slot,
                caption: caption, captureID: capture.map { [$0.capture.id, behind?.id].compactMap(\.self).joined(separator: "+") },
                store: layout.storeSignature
            )
            return RenderJob(key: key, layout: layout, capture: capture?.capture, companion: behind)
        }
    }

    /// A gallery card's slots, each nil until it's rendered (all of them
    /// before the previews are laid out).
    func starterImages(_ starter: TemplateStarter) -> [CGImage?] {
        guard let preview = starterPreviews.first(where: { $0.starter == starter }) else {
            return Array(repeating: nil, count: StarterPreview.slotCount)
        }
        return preview.jobs.map { renderQueue.images[$0.key] }
    }

    /// The card's font note, once the previews are laid out.
    func starterFontNote(_ starter: TemplateStarter) -> String {
        starterPreviews.first { $0.starter == starter }?.fontNote ?? ""
    }

    /// "14 templates · previewed with Lumen’s captions and captures".
    var galleryCount: String { galleryCount(in: galleryStyle) }

    /// The count for `style`'s templates, every one's when nil.
    func galleryCount(in style: TemplateStarter.Style?) -> String {
        let count = TemplateStarter.starters(in: style).count
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
