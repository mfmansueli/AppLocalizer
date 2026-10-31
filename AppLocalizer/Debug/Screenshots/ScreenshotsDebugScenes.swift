//
//  ScreenshotsDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Screenshots' DEBUG scenes (`-AppLocalizerDebugScene <id>`),
/// named after the design's screenshots. Every scene is Lumen Journal's
/// store page, version 1.4, on the Screenshots view:
///
/// - `sets`, `sets-ipad`: the matrix on iPhone 6.9″ and iPad 13″; "40 not
///   pushed · 2 checks failed".
/// - `sets-fallback`: S thumbnails, the English (U.S.) locales shown.
/// - `sets-rendering`: the queue held at 22 renders.
/// - `sets-failed`: a brand font without Thai or Vietnamese and an iPad
///   capture in an iPhone slot: "23 renders fail their checks".
/// - `viewer`, `viewer-fail`: Arabic slot 1 and German slot 3 full size.
/// - `scope`: the Locale Scope sheet.
/// - `sets-empty`, `sets-notpl`: no captures; captures but no template.
/// - `sets-noversion`: only the live 1.3 exists.
/// - `tpl`: the template editor on German slot 3, which overflows.
/// - `tpl-ipad`: iPad 13″ landscape, Japanese slot 1.
/// - `tpl-glyph`: Thai slot 1 with the uploaded Northpier Display tried as
///   an unsaved edit, and no Thai fallback: Thai's glyphs are missing.
/// - `tpl-pano`: switched to the Panorama starter (v5), Arabic slot 2.
/// - `tpl-history`, `starter`: the History popover and the Starter
///   Templates sheet over `tpl`.
/// - `cap`, `cap-edit`: the captions table; German slot 3 in the editor.
/// - `cap-translate`, `cap-translating`: Finnish, Polish, Swedish and
///   Turkish added with no captions; the Translate sheet, and its batch
///   held at "7 of 20 · Polish · slot 3".
enum ScreenshotsDebugScenes {
    static let ids = [
        "sets", "sets-ipad", "sets-fallback", "sets-rendering", "sets-failed", "viewer", "viewer-fail", "scope",
        "sets-empty", "sets-notpl", "sets-noversion",
        "tpl", "tpl-ipad", "tpl-glyph", "tpl-pano", "tpl-history", "starter",
        "cap", "cap-edit", "cap-translate", "cap-translating",
    ]

    /// The locales `cap-translate` adds, with no captions.
    static let addedLocales = ["fi", "pl", "sv", "tr"]

    @MainActor
    static func view(for id: String) -> AnyView? {
        matrixScene(id) ?? stateScene(id) ?? templateScene(id) ?? captionsScene(id)
    }

    /// The matrix, and the viewer and scope sheets over it.
    @MainActor
    private static func matrixScene(_ id: String) -> AnyView? {
        switch id {
        case "sets": scene()
        case "sets-ipad": scene { $0.displayType = .iPad }
        case "sets-fallback":
            scene { model in
                model.thumbnailSize = .small
                model.showsFallbackRows = true
            }
        case "viewer": scene { $0.openViewer(ScreenshotCellKey(locale: "ar-SA", displayType: .iPhone, slot: 0)) }
        case "viewer-fail": scene { $0.openViewer(ScreenshotCellKey(locale: "de-DE", displayType: .iPhone, slot: 2)) }
        case "scope": scene { $0.openScope() }
        default: nil
        }
    }

    /// Other documents and versions.
    @MainActor
    private static func stateScene(_ id: String) -> AnyView? {
        switch id {
        case "sets-rendering": scene(renderHoldCount: 22)
        case "sets-failed": scene(.failedChecks)
        case "sets-empty": scene(.noCaptures)
        case "sets-notpl": scene(.noTemplate)
        case "sets-noversion": scene(hasEditableVersion: false)
        default: nil
        }
    }

    /// The Template tab.
    @MainActor
    private static func templateScene(_ id: String) -> AnyView? {
        let german = LocaleSlot(locale: "de-DE", slot: 2)
        return switch id {
        case "tpl": scene { $0.openTemplateEditor(at: german) }
        case "tpl-ipad":
            scene { model in
                model.displayType = .iPad
                model.openTemplateEditor(at: LocaleSlot(locale: "ja", slot: 0))
            }
        case "tpl-glyph":
            scene(.thaiAndVietnamese) { model in
                model.openTemplateEditor(at: LocaleSlot(locale: "th", slot: 0))
                model.templateEditor.setDisplayFont("Northpier Display")
                model.templateEditor.setFallback(nil, for: .thai)
            }
        case "tpl-pano":
            scene { model in
                await model.chooseStarter(.panorama)
                model.openTemplateEditor(at: LocaleSlot(locale: "ar-SA", slot: 1))
            }
        case "tpl-history":
            scene { model in
                model.openTemplateEditor(at: german)
                model.templateEditor.isHistoryPresented = true
            }
        case "starter":
            scene { model in
                model.openTemplateEditor(at: german)
                model.templateEditor.isStarterSheetPresented = true
            }
        default: nil
        }
    }

    /// The Captions tab.
    @MainActor
    private static func captionsScene(_ id: String) -> AnyView? {
        switch id {
        case "cap": scene { $0.tab = .captions }
        case "cap-edit": scene { $0.editCaption(at: LocaleSlot(locale: "de-DE", slot: 2)) }
        case "cap-translate":
            scene { model in
                await addLocalesWithoutCaptions(to: model)
                model.tab = .captions
                model.captions.translation.prepare(provider: .appleTranslation, glossary: glossary)
                model.captions.isTranslateSheetPresented = true
            }
        case "cap-translating":
            scene(translator: DebugCaptionTranslator(holdsAt: LocaleSlot(locale: "pl", slot: 2))) { model in
                await addLocalesWithoutCaptions(to: model)
                model.tab = .captions
                model.captions.translation.prepare(provider: .appleTranslation, glossary: glossary)
                model.captions.translation.start()
            }
        default: nil
        }
    }

    /// Settings → Translation's glossary in the design.
    private static var glossary: TranslationGlossary {
        TranslationGlossary(terms: ["Lumen", "Lumen Plus", "Face ID"])
    }

    @MainActor
    private static func addLocalesWithoutCaptions(to model: ScreenshotsViewModel) async {
        guard var document = model.document else { return }
        document.scope.setLocalized(ScreenshotsSampleData.scope + addedLocales)
        await model.commit(document)
    }

    @MainActor
    private static func scene(
        _ scenario: ScreenshotsDebugScenario = .standard,
        renderHoldCount: Int? = nil,
        hasEditableVersion: Bool = true,
        translator: DebugCaptionTranslator? = nil,
        opening: (@MainActor (ScreenshotsViewModel) async -> Void)? = nil
    ) -> AnyView {
        let screenshots = DebugScreenshotsServices(
            scenario: scenario,
            renderHoldCount: renderHoldCount,
            opening: opening.map(ScreenshotsDebugOpening.init)
        )
        if let translator { screenshots.translator = translator }
        var storePage = DebugStorePageServices(hasEditableVersion: hasEditableVersion)
        storePage.screenshots = screenshots
        var services = WorkspaceServices.debug
        services.storePage = storePage
        return AnyView(DebugMainScene(services: services, section: .screenshots, pendingChanges: DebugWorkspace.pendingChanges))
    }
}
#endif
