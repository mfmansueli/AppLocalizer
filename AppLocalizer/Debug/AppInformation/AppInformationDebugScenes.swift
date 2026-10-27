//
//  AppInformationDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// The App Information section's DEBUG scenes (`-AppLocalizerDebugScene <id>`),
/// named after the design's screenshots. `DebugSceneView` asks here for any
/// id it doesn't know itself. Every scene is Lumen Journal's App
/// Information; the `info-*` scenes sit on the sample workspace (Habitat's
/// pending changes), the `a11y-*` scenes only have their own:
///
/// - `info-general`, `info-review`, `info-export`: the pages; App Review
///   with sign-in required and a demo account, Export Compliance with
///   Claude Code's evidence open.
/// - `info-age`: Claude Code's seven answers, two confirmed. `info-age-override`:
///   all confirmed, rated 13+ over the calculated rating, with a reason.
/// - `a11y-empty`, `a11y-loading`, `a11y-error`: never declared; the
///   declarations never finish loading; a 500 from App Store Connect.
/// - `a11y-editor`: declaring iPhone (never declared). `a11y-editor-watch`:
///   Apple Watch, Voice Control hidden, Claude Code's suggestions.
/// - `a11y-draft`, `a11y-published`, `a11y-pending`: only an iPhone draft;
///   Lumen's cards; iPhone adds Reduced Motion, not pushed.
/// - `a11y-nolive`, `a11y-review`: Review & Push with the publish switch,
///   disabled for Apple Vision Pro; three devices.
/// - `a11y-url`: the accessibility URL without https://.
/// - `a11y-pushing`: iPhone published, iPad held at "Publishing…".
/// - `priv-*` and `info-privacy-draft`: App Privacy, in
///   `AppInformationDebugScenes+Privacy.swift`.
enum AppInformationDebugScenes {
    static let ids = [
        "info-general", "info-age", "info-age-override", "info-review", "info-export",
        "a11y-empty", "a11y-loading", "a11y-error", "a11y-editor", "a11y-editor-watch", "a11y-draft", "a11y-published",
        "a11y-pending", "a11y-nolive", "a11y-url", "a11y-review", "a11y-pushing",
    ] + privacyIDs

    @MainActor
    static func view(for id: String) -> AnyView? {
        if id.hasPrefix("info-") { return infoScene(id) }
        switch id {
        case "a11y-empty": return accessibilityScene(.neverDeclared)
        case "a11y-loading": return accessibilityScene(DebugAppInformationServices(accessibilityDelay: .seconds(24 * 60 * 60)))
        case "a11y-error":
            let error = AppStoreConnectError.server(statusCode: 500, code: "UNEXPECTED_ERROR", detail: "An unexpected error occurred.")
            return accessibilityScene(DebugAppInformationServices(accessibilityError: error))
        case "a11y-editor", "a11y-editor-watch": return editorScene(id)
        case "a11y-draft": return accessibilityScene(.iPhoneDraft)
        case "a11y-published": return accessibilityScene(.lumen)
        case "a11y-pending": return accessibilityScene(.lumen, pending: [DebugAppInformationChanges.iPhoneAddsReducedMotion])
        case "a11y-url": return accessibilityScene(.lumen, pending: [DebugAppInformationChanges.invalidURL])
        default: return reviewScene(id)
        }
    }

    // MARK: - Pages

    @MainActor
    private static func infoScene(_ id: String) -> AnyView? {
        switch id {
        case "info-general":
            return scene { $0.page = .general }
        case "info-age":
            let answers = DebugAppInformationChanges.assistantAgeAnswers(confirmed: DebugAppInformationChanges.confirmedInAgeScene)
            return scene(pending: answers) { $0.page = .ageRating }
        case "info-age-override":
            let answers = DebugAppInformationChanges.assistantAgeAnswers(confirmed: Set(AgeRatingQuestion.allCases))
            return scene(pending: answers) { model in
                model.page = .ageRating
                model.setOverrideReason("Weekly reflections can touch on grief, loss and self-harm.")
                model.setOverride(.thirteenPlus)
            }
        case "info-review":
            return scene { model in
                model.page = .appReview
                model.setSignInRequired(true)
                model.setReviewText("review@northpier.dev", for: .userName)
                model.setReviewText("lumen-sandbox-2026", for: .password)
            }
        case "info-export":
            return scene { model in
                model.page = .exportCompliance
                model.showsExportEvidence = true
            }
        default:
            return privacyScene(id)
        }
    }

    /// The editor sheet: declaring iPhone on a never-declared app, or Apple
    /// Watch on Lumen's cards.
    @MainActor
    private static func editorScene(_ id: String) -> AnyView {
        guard id == "a11y-editor-watch" else {
            return accessibilityScene(.neverDeclared) { model in
                model.openEditor(.iPhone)
                model.editor?.supportsAny = true
                model.editor?.features = [.voiceOver, .largerText, .darkInterface]
            }
        }
        return accessibilityScene(.lumen) { model in
            model.openEditor(.appleWatch)
            model.editor?.supportsAny = true
            model.editor?.features = [.voiceOver, .largerText]
        }
    }

    // MARK: - Review & Push

    @MainActor
    private static func reviewScene(_ id: String) -> AnyView? {
        switch id {
        case "a11y-nolive":
            return accessibilityScene(.lumen, pending: [DebugAppInformationChanges.visionAddsReducedMotion], sheet: .review)
        case "a11y-review":
            let pending = [
                DebugAppInformationChanges.iPhoneAddsReducedMotion,
                DebugAppInformationChanges.iPadToSeven,
                DebugAppInformationChanges.visionSwapsVoiceControl,
            ]
            return accessibilityScene(.lumen, pending: pending, sheet: .review)
        case "a11y-pushing":
            // Conflict checks need App Store Connect's real answers, which
            // the sample transport doesn't fake.
            let pending = [DebugAppInformationChanges.iPhoneAddsReducedMotion, DebugAppInformationChanges.iPadToSeven].compactMap { change in
                var change = change
                change?.conflictCheck = nil
                return change
            }
            var services = WorkspaceServices.debug
            var appInformation = DebugAppInformationServices()
            appInformation.opening = DebugAppInformationServices.Opening { $0.page = .accessibility }
            services.appInformation = appInformation
            services.push = DebugHoldingPushTransport(holding: DebugAppInformationContent.iPadDraftID)
            return AnyView(DebugMainScene(services: services, section: .appInformation, pendingChanges: pending, autoPush: true))
        default:
            return privacyScene(id)
        }
    }

    // MARK: - Scenes

    /// An `info-*` scene: the sample workspace plus `pending`.
    @MainActor
    private static func scene(
        pending: [PendingChange?] = [],
        opening: @escaping @MainActor (AppInformationViewModel) async -> Void
    ) -> AnyView {
        var appInformation = DebugAppInformationServices()
        appInformation.opening = DebugAppInformationServices.Opening(opening)
        var services = WorkspaceServices.debug
        services.appInformation = appInformation
        return AnyView(DebugMainScene(
            services: services,
            section: .appInformation,
            pendingChanges: DebugWorkspace.pendingChanges + pending.compactMap(\.self)
        ))
    }

    @MainActor
    private static func accessibilityScene(
        _ sample: DebugAppInformationContent.AccessibilitySample,
        pending: [PendingChange?] = [],
        sheet: WorkspaceSheet? = nil,
        opening: (@MainActor (AppInformationViewModel) async -> Void)? = nil
    ) -> AnyView {
        accessibilityScene(DebugAppInformationServices(accessibilitySample: sample), pending: pending, sheet: sheet, opening: opening)
    }

    /// An `a11y-*` scene on the Accessibility page, with only `pending`.
    @MainActor
    private static func accessibilityScene(
        _ appInformation: DebugAppInformationServices,
        pending: [PendingChange?] = [],
        sheet: WorkspaceSheet? = nil,
        opening: (@MainActor (AppInformationViewModel) async -> Void)? = nil
    ) -> AnyView {
        var appInformation = appInformation
        appInformation.opening = DebugAppInformationServices.Opening { model in
            model.page = .accessibility
            await opening?(model)
        }
        var services = WorkspaceServices.debug
        services.appInformation = appInformation
        return AnyView(DebugMainScene(
            services: services,
            section: .appInformation,
            pendingChanges: pending.compactMap(\.self),
            presentedSheet: sheet
        ))
    }
}
#endif
