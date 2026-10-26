//
//  ScreenshotsDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Store Page → Screenshots' DEBUG scenes (`-AppLocalizerDebugScene <id>`),
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
enum ScreenshotsDebugScenes {
    static let ids = [
        "sets", "sets-ipad", "sets-fallback", "sets-rendering", "sets-failed", "viewer", "viewer-fail", "scope",
        "sets-empty", "sets-notpl", "sets-noversion",
    ]

    @MainActor
    static func view(for id: String) -> AnyView? {
        matrixScene(id) ?? stateScene(id)
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

    @MainActor
    private static func scene(
        _ scenario: ScreenshotsDebugScenario = .standard,
        renderHoldCount: Int? = nil,
        hasEditableVersion: Bool = true,
        opening: (@MainActor (ScreenshotsViewModel) async -> Void)? = nil
    ) -> AnyView {
        let screenshots = DebugScreenshotsServices(
            scenario: scenario,
            renderHoldCount: renderHoldCount,
            opening: opening.map(ScreenshotsDebugOpening.init)
        )
        var storePage = DebugStorePageServices(hasEditableVersion: hasEditableVersion)
        storePage.screenshots = screenshots
        storePage.opening = DebugStorePageServices.Opening { $0.mode = .screenshots }
        var services = WorkspaceServices.debug
        services.storePage = storePage
        return AnyView(DebugMainScene(services: services, section: .storePage, pendingChanges: DebugWorkspace.pendingChanges))
    }
}
#endif
