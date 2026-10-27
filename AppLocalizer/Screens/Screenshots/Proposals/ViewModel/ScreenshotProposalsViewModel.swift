//
//  ScreenshotProposalsViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The Proposals sheet (design README §6): an app's screenshot proposals
/// on the left, the selected one on the right. Nothing an assistant sends
/// changes the screenshots until it's accepted here; accepting saves a
/// template version or writes captions, and the changed renders then wait
/// in Review & Push like any others.
///
/// It loads and saves through the app's `ScreenshotsServices`, whose
/// document center hands every save to the open Screenshots view.
@MainActor
@Observable
final class ScreenshotProposalsViewModel: Identifiable {
    nonisolated let id = UUID()
    let app: StoreApp
    let services: any ScreenshotsServices
    let primaryLocale: StoreLocale
    /// Capture images for the previews.
    let captureImages: CaptureImageStore

    private(set) var document: ScreenshotsDocument?
    var errorMessage: String?
    var selectedID: String?
    /// The slot the before-and-after strip shows, 0-based.
    var stressSlot = 2
    var displayType: ScreenshotDisplayType = .iPhone
    /// The captions ticked per caption proposal; all of them until the
    /// person unticks one.
    var captionSelections: [String: Set<LocaleSlot>] = [:]
    /// Per stale proposal and conflicting path: keep yours or use theirs.
    var rebaseChoices: [String: [String: TemplateProposalReview.Choice]] = [:]
    @ObservationIgnored var now: () -> Date = { .now }

    init(app: StoreApp, services: any ScreenshotsServices, primaryLocale: StoreLocale, selecting proposalID: String? = nil) {
        self.app = app
        self.services = services
        self.primaryLocale = primaryLocale
        selectedID = proposalID
        captureImages = CaptureImageStore { [services, app] capture, width in
            await services.captureImage(capture, for: app, pixelWidth: width)
        }
        services.documentCenter?.observe(app.id, owner: self) { [weak self] document in
            self?.adopt(document)
        }
    }

    func load() async {
        do {
            try await adopt(services.loadDocument(for: app, primaryLocale: primaryLocale))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// The document as saved elsewhere, e.g. a proposal an assistant just
    /// sent.
    func adopt(_ document: ScreenshotsDocument) {
        self.document = document
        if selected == nil { selectedID = document.waitingProposals.first?.id ?? document.proposals.last?.id }
        stressSlot = min(stressSlot, max(0, document.slotCount - 1))
    }

    // MARK: - The list

    /// Every proposal, oldest first.
    var proposals: [ScreenshotProposal] { document?.proposals ?? [] }

    var selected: ScreenshotProposal? {
        proposals.first { $0.id == selectedID }
    }

    var currentVersion: Int? { document?.history?.currentNumber }

    func status(of proposal: ScreenshotProposal) -> ProposalCardStatus {
        ProposalCardStatus(proposal, currentVersion: currentVersion)
    }

    /// "Template v4 → v5 · 4 changes", "3 captions · German".
    func subtitle(of proposal: ScreenshotProposal) -> String {
        switch proposal.kind {
        case .template:
            let based = proposal.basedOnVersion ?? 0
            let count = proposal.template?.operations.count ?? 0
            let changes = count == 1 ? String(localized: "1 change") : String(localized: "\(count) changes")
            return String(localized: "Template v\(based) → v\(based + 1) · \(changes)")
        case .captions:
            let count = proposal.captions.count
            let captions = count == 1 ? String(localized: "1 caption") : String(localized: "\(count) captions")
            var names: [String] = []
            for item in proposal.captions {
                let name = StoreLocaleCatalog.locale(code: item.locale)?.name ?? item.locale
                if !names.contains(name) { names.append(name) }
            }
            return "\(captions) · \(names.formatted(.list(type: .and)))"
        }
    }

    /// "From Claude Code at 10:42 · based on template v4".
    func meta(of proposal: ScreenshotProposal) -> String {
        let time = proposal.timeText(now: now())
        let based = proposal.basedOnVersion ?? currentVersion
        var text = String(localized: "From \(proposal.client) at \(time)")
        if let based { text += " · " + String(localized: "based on template v\(based)") }
        if let rebasedFrom = proposal.template?.rebasedFrom { text += " · " + String(localized: "rebased from v\(rebasedFrom)") }
        return text
    }

    /// What a decided proposal's detail says instead of its buttons.
    func outcome(of proposal: ScreenshotProposal) -> String? {
        switch proposal.status {
        case .waiting: nil
        case .accepted where proposal.kind == .template:
            String(localized: "Accepted. It’s template v\(currentVersion ?? 0) now, and the changed renders are waiting in Review & Push.")
        case .accepted:
            String(localized: "Accepted. The captions keep the “Proposed by \(proposal.client)” tag until someone edits them.")
        case .partlyAccepted: String(localized: "Partly accepted. Rejected captions stay as they were.")
        case .rejected: String(localized: "Rejected. Nothing changed.")
        }
    }

    // MARK: - Deciding

    /// Reject, Reject All and Discard.
    func reject() async {
        guard let id = selectedID, var document else { return }
        document.rejectProposal(id, date: now())
        await save(document)
    }

    /// Saves and adopts what was decided.
    func save(_ document: ScreenshotsDocument) async {
        self.document = document
        do {
            try await services.saveDocument(document, for: app)
            errorMessage = nil
        } catch {
            errorMessage = String(localized: "Couldn’t save the screenshot settings: \(error.localizedDescription)")
        }
    }

    /// Checks operations against the fonts this Mac has.
    var applier: TemplateOperationApplier { TemplateOperationApplier(fonts: services.fonts) }

    /// The layout engine every preview uses.
    var engine: ScreenshotLayoutEngine { ScreenshotLayoutEngine(catalog: services.fonts) }

    /// Twice a preview's width.
    static let captureImageWidth = 240
}
