//
//  RetentionDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Pricing → Retention's DEBUG scenes (`-AppLocalizerDebugScene <id>`), as
/// the design's Retention board shows them, all on Lumen Journal:
///
/// - `ret-none`: no retention message yet.
/// - `ret-edit`: "Before you go", live, a message only, in English.
/// - `ret-offer-de`: "Before you go" before its first push, with the
///   half-price offer, in German, which runs to 149 characters; Claude
///   Code's shorter version is waiting.
/// - `ret-all`: the live message with every language listed, and an empty
///   "Message 2".
/// - `ret-offer-sheet`: New Offer… over `ret-edit`.
/// - `ret-img-sheet`: the image sheet with Night Window picked.
/// - `ret-image-ar`: in dark mode, the live message with Still Lake, in
///   Arabic, in Review & Push, with the server setup open.
enum RetentionDebugScenes {
    static let ids = ["ret-none", "ret-edit", "ret-offer-de", "ret-all", "ret-offer-sheet", "ret-img-sheet", "ret-image-ar"]

    @MainActor
    static func view(for id: String) -> AnyView? {
        guard let launch = launch(for: id) else { return nil }
        var services = WorkspaceServices.debug
        services.retention = DebugRetentionServices(launch: launch)
        let scene = DebugMainScene(services: services, section: .subscriptionPricing, pendingChanges: [])
        return launch.isDark ? AnyView(scene.preferredColorScheme(.dark)) : AnyView(scene)
    }

    static func launch(for id: String) -> RetentionDebugLaunch? {
        let draftID = "\(RetentionMessage.draftPrefix)1"
        switch id {
        case "ret-none":
            return RetentionDebugLaunch(remoteMessages: [])
        case "ret-edit":
            return RetentionDebugLaunch()
        case "ret-offer-de":
            return RetentionDebugLaunch(
                remoteMessages: [],
                drafts: [RetentionSampleData.draft(kind: .offer)],
                locale: StoreLocale.german.code,
                suggestion: RetentionSuggestion(
                    messageID: draftID, locale: StoreLocale.german.code, body: RetentionSampleData.shorterGerman, client: "Claude Code"
                )
            )
        case "ret-all":
            return RetentionDebugLaunch(
                drafts: [RetentionMessage.draft(id: draftID, number: 2)],
                selectedMessageID: RetentionSampleData.messageID,
                showsAllLanguages: true
            )
        case "ret-offer-sheet":
            return RetentionDebugLaunch(sheet: .offer)
        case "ret-img-sheet":
            return RetentionDebugLaunch(
                remoteMessages: [],
                drafts: [RetentionSampleData.draft(kind: .image, image: RetentionSampleData.moonrise)],
                sheet: .image(pickedImageID: RetentionSampleData.window.id)
            )
        case "ret-image-ar":
            return RetentionDebugLaunch(
                kind: .image,
                image: RetentionSampleData.lake,
                locale: StoreLocale.arabic.code,
                isAdvancedExpanded: true,
                isDark: true,
                queues: true
            )
        default:
            return nil
        }
    }
}
#endif
