//
//  ScreenshotsProposalsDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Screenshots' Captures tab and the Proposals sheet as DEBUG
/// scenes (`-AppLocalizerDebugScene <id>`), named after the design's
/// screenshots. Lumen Journal, version 1.4:
///
/// - `capt-empty`, `capt-hover`: nothing imported yet; then files hover
///   over the drop zone, "Release to import 55 files".
/// - `capt-match`: fastlane's output at the matching step, "52 matched ·
///   3 need you".
/// - `capt`: the coverage after the import.
/// - `prop-list`: the toolbar's popover, "Lumen Journal · 2 proposals".
/// - `prop-tpl`, `prop-cap`: the Proposals sheet on Claude Code's template
///   revision and on its shorter German captions.
/// - `prop-stale`: a proposal based on v3 after v4 also changed the
///   device width.
/// - `prop-disc`: `prop-cap` after Claude Code disconnected at 10:44.
///
/// Scenes share `ScreenshotsDocumentCenter.shared`, which the toolbar
/// reads, without its disk store.
enum ScreenshotsProposalsDebugScenes {
    static let ids = ["capt-empty", "capt-hover", "capt-match", "capt", "prop-list", "prop-tpl", "prop-cap", "prop-stale", "prop-disc"]

    @MainActor
    static func view(for id: String) -> AnyView? {
        switch id {
        case "capt-empty":
            return scene(.noCaptures) { $0.tab = .captures }
        case "capt-hover":
            return scene(.noCaptures) { model in
                model.tab = .captures
                model.captures.dropHover = CapturesViewModel.DropHover(fileCount: 55)
            }
        case "capt-match":
            // The design's first import: a five-slot template, no captures yet.
            return scene(.noCaptures) { model in
                guard var document = model.document else { return }
                document.history = ScreenshotsSampleData.history
                await model.commit(document)
                model.captures.present(ScreenshotsSampleData.fastlaneScan)
            }
        case "capt":
            return scene { $0.tab = .captures }
        case "prop-list":
            AssistantToolbarIndicator.debugShowsPopover = true
            return scene(assistants: .paired) { _ in }
        default:
            return proposalScene(id)
        }
    }

    @MainActor
    private static func proposalScene(_ id: String) -> AnyView? {
        switch id {
        case "prop-tpl": scene(assistants: .paired) { open($0, proposal: "p1") }
        case "prop-cap": scene(assistants: .paired) { open($0, proposal: "p2") }
        case "prop-disc": scene(assistants: .disconnected) { open($0, proposal: "p2") }
        case "prop-stale":
            scene(assistants: .paired) { model in
                guard var document = model.document else { return }
                document.history = ScreenshotsSampleData.staleHistory
                document.proposals.insert(ScreenshotsSampleData.staleProposal, at: 0)
                await model.commit(document)
                open(model, proposal: "p3")
            }
        default: nil
        }
    }

    @MainActor
    private static func open(_ model: ScreenshotsViewModel, proposal: String) {
        ScreenshotsDocumentCenter.shared.openProposals(appID: model.app.id, proposalID: proposal)
    }

    @MainActor
    private static func scene(
        _ scenario: ScreenshotsDebugScenario = .standard,
        assistants: AssistantsDebugState = .off,
        opening: @escaping @MainActor (ScreenshotsViewModel) async -> Void
    ) -> AnyView {
        let center = ScreenshotsDocumentCenter.shared
        center.diskStore = nil
        let screenshots = DebugScreenshotsServices(scenario: scenario, opening: ScreenshotsDebugOpening(opening), documentCenter: center)
        var storePage = DebugStorePageServices()
        storePage.screenshots = screenshots
        var services = WorkspaceServices.debug
        services.storePage = storePage
        let main = DebugMainScene(services: services, section: .screenshots, pendingChanges: DebugWorkspace.pendingChanges)
        return AnyView(main.modifier(Assistants(state: assistants)))
    }

    /// Puts the MCP server in `state` once the scene appears.
    private struct Assistants: ViewModifier {
        let state: AssistantsDebugState
        @Environment(MCPServerController.self) private var server

        func body(content: Content) -> some View {
            content.task { state.apply(to: server) }
        }
    }
}
#endif
