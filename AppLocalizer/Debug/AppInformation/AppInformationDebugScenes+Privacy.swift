//
//  AppInformationDebugScenes+Privacy.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

// App Privacy's scenes, named after the design's screenshots. Each puts
// Lumen Journal's worksheet in one state (`DebugPrivacyWorksheets`):
//
// - `priv-empty`, `priv-noconn`: not started, with Claude Code connected,
//   or with the server on and no assistant.
// - `priv-scanning`: the first five suggestions in, the scan running.
// - `priv-review`, `priv-evidence`, `priv-questions`: the scan done, three
//   accepted; Purchase History's evidence open; the open questions.
// - `priv-conflict`, `priv-mismatch`: Device ID answered differently;
//   Sentry's manifest against a type marked not collected.
// - `priv-done`, `priv-checklist`, `priv-published`: done; the checklist
//   with three steps ticked; marked published.
// - `priv-rescan`: a later scan found Mixpanel; out of date.
// - `priv-export`, `priv-import`: the export sheet over the done
//   worksheet; a fastlane file to import.
// - `priv-urls`, `priv-review-urls`: French (Canada)'s policy URL edited;
//   Review & Push with two policy URLs and an accessibility change.
// - `priv-overview`: the overview's App Privacy and Privacy URLs cards.
// - `info-privacy-draft`: Claude Code's suggestions arriving one by one,
//   through the worksheet store as over MCP.
extension AppInformationDebugScenes {
    static let privacyIDs = [
        "priv-empty", "priv-noconn", "priv-scanning", "priv-review", "priv-evidence", "priv-questions", "priv-conflict",
        "priv-mismatch", "priv-done", "priv-checklist", "priv-published", "priv-rescan", "priv-export", "priv-import",
        "priv-urls", "priv-review-urls", "priv-overview", "info-privacy-draft",
    ]

    @MainActor
    static func privacyScene(_ id: String) -> AnyView? {
        guard let worksheet = privacyWorksheets[id] else { return otherPrivacyScene(id) }
        let setUp = privacySetUps[id]
        return privacy(worksheet(), assistant: id == "priv-noconn" ? .serverOnly : .connected) { setUp?($0) }
    }

    /// The worksheet of each scene that only needs one and a page state.
    @MainActor
    private static let privacyWorksheets: [String: @MainActor () -> PrivacyWorksheet] = [
        "priv-empty": { PrivacyWorksheet() },
        "priv-noconn": { PrivacyWorksheet() },
        "priv-scanning": { DebugPrivacyWorksheets.scanning() },
        "priv-review": { DebugPrivacyWorksheets.review },
        "priv-evidence": { DebugPrivacyWorksheets.review },
        "priv-questions": { DebugPrivacyWorksheets.review },
        "priv-conflict": { DebugPrivacyWorksheets.conflict },
        "priv-mismatch": { DebugPrivacyWorksheets.mismatch },
        "priv-done": { DebugPrivacyWorksheets.done },
        "priv-checklist": { DebugPrivacyWorksheets.checklist },
        "priv-published": { DebugPrivacyWorksheets.published },
        "priv-rescan": { DebugPrivacyWorksheets.rescan },
        "priv-export": { DebugPrivacyWorksheets.done },
        "priv-import": { PrivacyWorksheet() },
    ]

    /// What each of those scenes opens on the page.
    @MainActor
    private static let privacySetUps: [String: @MainActor (AppPrivacyViewModel) -> Void] = [
        "priv-evidence": { $0.evidenceType = .purchases },
        "priv-questions": { $0.filter = .openQuestions },
        "priv-checklist": { $0.tab = .checklist },
        "priv-published": { $0.tab = .checklist },
        "priv-export": { $0.isExportSheetPresented = true },
        "priv-import": { model in
            model.showImport(
                DebugPrivacyWorksheets.fastlaneFile,
                fileName: "app_privacy_details.json",
                path: "~/Developer/Lumen/fastlane/app_privacy_details.json"
            )
        },
    ]

    @MainActor
    private static func otherPrivacyScene(_ id: String) -> AnyView? {
        switch id {
        case "priv-urls":
            return privacy(DebugPrivacyWorksheets.review, pending: [DebugPrivacyURLChanges.frenchCanadaPolicy]) { $0.tab = .urls }
        case "priv-review-urls":
            let pending = [
                DebugPrivacyURLChanges.frenchCanadaPolicy,
                DebugPrivacyURLChanges.hebrewPolicy,
                DebugAppInformationChanges.iPhoneAddsReducedMotion,
            ]
            return privacy(DebugPrivacyWorksheets.review, pending: pending, sheet: .review) { $0.tab = .urls }
        case "priv-overview":
            var services = WorkspaceServices.debug
            services.appInformation = DebugAppInformationServices(privacy: DebugPrivacyWorksheets.overview)
            return AnyView(DebugMainScene(services: services, section: .overview, pendingChanges: []))
        case "info-privacy-draft":
            return privacy(DebugPrivacyWorksheets.scanning()) { model in
                await DebugPrivacyDraft.stream(into: model)
            }
        default:
            return nil
        }
    }

    /// Lumen Journal's App Privacy page with `worksheet`, Claude Code
    /// connected unless `assistant` says otherwise, and only `pending` in
    /// the queue.
    @MainActor
    private static func privacy(
        _ worksheet: PrivacyWorksheet,
        assistant: DebugPrivacyAssistant = .connected,
        pending: [PendingChange?] = [],
        sheet: WorkspaceSheet? = nil,
        opening: (@MainActor (AppPrivacyViewModel) async -> Void)? = nil
    ) -> AnyView {
        var appInformation = DebugAppInformationServices(privacy: worksheet)
        appInformation.opening = DebugAppInformationServices.Opening { model in
            model.page = .appPrivacy
            await opening?(model.privacy)
        }
        var services = WorkspaceServices.debug
        services.appInformation = appInformation
        let scene = DebugMainScene(
            services: services,
            section: .appInformation,
            pendingChanges: pending.compactMap(\.self),
            presentedSheet: sheet
        )
        return AnyView(scene.modifier(DebugPrivacyAssistantModifier(assistant: assistant)))
    }
}
#endif
