//
//  MCPScreenshotsDraft.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// An app's screenshot document as the screenshot tools read it: the
/// services that keep it, its primary locale, and checked lookups of what
/// an assistant names (locales, 1-based slots, display types, captures).
/// Saving goes through the services, so the open Screenshots view and the
/// Proposals sheet see a proposal the moment it's sent.
@MainActor
struct MCPScreenshotsDraft {
    let app: StoreApp
    let services: any ScreenshotsServices
    let primary: StoreLocale
    var document: ScreenshotsDocument

    static func load(app identifier: String, in workspace: MCPWorkspace) async throws -> MCPScreenshotsDraft {
        let app = try await workspace.app(matching: identifier)
        let services = workspace.services.screenshots
        let primary = app.primaryLocale.flatMap(StoreLocaleCatalog.locale(code:)) ?? .englishUS
        do {
            let document = try await services.loadDocument(for: app, primaryLocale: primary)
            return MCPScreenshotsDraft(app: app, services: services, primary: primary, document: document)
        } catch {
            throw MCPToolError.unavailable(String(localized: "Couldn’t read \(app.name)’s screenshots: \(error.localizedDescription)"))
        }
    }

    /// "Lumen Journal · Screenshots".
    var target: String { String(localized: "\(app.name) · Screenshots") }

    /// "Lumen Journal · de-DE · slot 2".
    func target(locale: String, slot: Int) -> String {
        "\(app.name) · \(locale) · " + String(localized: "slot \(slot + 1)")
    }

    var engine: ScreenshotLayoutEngine { ScreenshotLayoutEngine(catalog: services.fonts) }

    var applier: TemplateOperationApplier { TemplateOperationApplier(fonts: services.fonts) }

    // MARK: - Lookups

    func template() throws -> ScreenshotTemplate {
        guard let template = document.template else {
            throw MCPToolError.notFound(String(localized: "\(app.name) has no screenshot template yet. Ask the person to import captures and pick a starter in AppLocalizer → Screenshots."))
        }
        return template
    }

    func locale(_ code: String) throws -> StoreLocale {
        guard let locale = StoreLocaleCatalog.resolve(code).locale else {
            throw MCPToolError.notFound(String(localized: "“\(code)” isn’t an App Store locale. Use codes such as de-DE, ja or pt-BR."))
        }
        return locale
    }

    /// A 1-based slot number as the 0-based slot.
    func slot(_ number: Int) throws -> Int {
        guard (1...document.slotCount).contains(number) else {
            throw MCPToolError.invalidArgument(name: "slot", expected: String(localized: "a slot from 1 to \(document.slotCount)"))
        }
        return number - 1
    }

    func displayType(_ value: String?) throws -> ScreenshotDisplayType {
        guard let value else { return .iPhone }
        // The template tools work on the set's slots: iPhone and iPad.
        guard let display = ScreenshotDisplayType(mcpValue: value), display.isRendered else {
            throw MCPToolError.invalidArgument(name: "displayType", expected: String(localized: "“iphone” or “ipad”"))
        }
        return display
    }

    func capture(id: String) throws -> ScreenshotCapture {
        guard let capture = document.captures.captures.first(where: { $0.id == id }) else {
            throw MCPToolError.notFound(String(localized: "\(app.name) has no capture “\(id)”. Use list_captures."))
        }
        return capture
    }

    /// The scope's locales, primary first.
    var scopeLocales: [StoreLocale] {
        document.scope.orderedLocales(in: StoreLocaleCatalog.all.map(\.code)).compactMap(StoreLocaleCatalog.locale(code:))
    }

    // MARK: - Measuring

    /// The layout of `caption` on a slot, from `template`.
    func layout(
        _ template: ScreenshotTemplate, locale: StoreLocale, slot: Int, displayType: ScreenshotDisplayType, caption: ScreenshotCaption?
    ) -> ScreenshotLayout {
        engine.layout(template, slot: min(slot, template.slots.count - 1), locale: locale, displayType: displayType, caption: caption)
    }

    /// The template with an assistant's patch applied, or why it can't be.
    func patched(_ template: ScreenshotTemplate, with patch: JSONValue?) throws -> ScreenshotTemplate {
        guard let patch, !patch.isNull else { return template }
        let operations = try TemplateOperation.mcpOperations(from: patch, argument: "templatePatch")
        switch applier.applying(operations, to: template) {
        case let .success(patched): return patched
        case let .failure(refusals): throw MCPToolError.invalidArgument(name: "templatePatch", expected: refusals.summary)
        }
    }

    /// A slot rendered as PNG, about `pixelWidth` wide.
    func renderPNG(_ layout: ScreenshotLayout, capture: ScreenshotCapture?, pixelWidth: Int) async -> Data? {
        var image: CGImage?
        if let capture { image = await services.captureImage(capture, for: app, pixelWidth: pixelWidth) }
        guard let render = ScreenshotImageRenderer.image(layout: layout, capture: image, pixelWidth: pixelWidth) else { return nil }
        return ScreenshotPNG.data(render)
    }

    // MARK: - Saving

    mutating func save() async throws {
        do {
            try await services.saveDocument(document, for: app)
        } catch {
            throw MCPToolError.unavailable(String(localized: "Couldn’t save \(app.name)’s screenshots: \(error.localizedDescription)"))
        }
    }
}
