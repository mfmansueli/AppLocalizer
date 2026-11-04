//
//  ProductPageTestModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// “Test with Product Page Optimization…” for one placement: asks the
/// run's design source for a variant with one idea changed (the current
/// image shows the interface, the variant the outcome), shows it rendered
/// and checked in every language, then makes the test through the API, or
/// exports both variants with the steps to make it by hand. It never says
/// a test was made when it wasn't: only `ProductPageTestOutcome.created`
/// does.
@MainActor
@Observable
final class ProductPageTestModel: Identifiable {
    enum Phase: Hashable {
        /// Nothing asked yet.
        case intro
        /// Waiting for the design source's variant.
        case asking
        case variantReady
        case testing
        case finished
    }

    /// One language: the current image and the variant, with the
    /// variant's findings.
    struct LocaleRow: Hashable, Identifiable {
        var locale: String
        var name: String
        var control: URL?
        var treatment: URL?
        var checks: [ArtworkCheck]

        var id: String { locale }
    }

    let id = UUID()
    let placement: ProductPageTestPlacement
    let kind: AutopilotArtworkKind
    private(set) var plan: ExtrasReviewPlan
    var phase: Phase
    var run: ProductPageTestRun?
    /// Why the variant can't be asked for, or that the person asks their
    /// assistant themselves.
    var notice: String?
    /// The assistant asked for the variant (the run's client).
    var assistantName: String?
    /// The Claude Code AppLocalizer started for the variant, if it did.
    var launchedRunID: ClaudeCodeRun.ID?
    /// AppLocalizer is starting Claude Code: nobody's idle yet.
    private(set) var isStarting = false
    #if DEBUG
    /// DEBUG scenes: asks as soon as the sheet opens.
    var asksOnAppear = false
    #endif

    @ObservationIgnored let environment: ProductPageTestEnvironment?
    @ObservationIgnored let fileURL: (_ fileID: String, _ pathExtension: String) -> URL
    @ObservationIgnored let exportFolder: URL
    /// Reads the app's extras again, once the variant is in.
    @ObservationIgnored let loadExtras: () async -> ScreenshotExtras?

    /// The sheet's first line.
    static let explanation = String(localized: """
    Tests one idea at a time. Apple splits traffic between your current page and this treatment; results appear in App Store Connect.
    """)

    init(
        plan: ExtrasReviewPlan, placement: ProductPageTestPlacement, environment: ProductPageTestEnvironment?,
        fileURL: @escaping (String, String) -> URL, exportFolder: URL, loadExtras: @escaping () async -> ScreenshotExtras?
    ) {
        self.plan = plan
        self.placement = placement
        kind = plan.kind(for: placement) ?? (placement == .header ? .header : .search)
        self.environment = environment
        self.fileURL = fileURL
        self.exportFolder = exportFolder
        self.loadExtras = loadExtras
        phase = .intro
        if variant != nil { phase = .variantReady }
    }

    var role: ArtworkTextRole { placement == .header ? .header : .search }
    var controlName: String { ProductPageTestRequest.defaultControlName }
    var treatmentName: String { ProductPageTestRequest.defaultTreatmentName }

    /// "Header: Interface vs Outcome".
    var testName: String { "\(placement.title): \(controlName) vs \(treatmentName)" }

    /// The variant for this placement, once one was made.
    var variant: ExtrasArtworkVariant? {
        guard let variant = plan.variant, variant.kind == kind, variant.role == role else { return nil }
        return variant
    }

    /// Primary language first.
    var rows: [LocaleRow] {
        let codes = plan.artwork.filter { $0.kind == kind }.map(\.locale)
        let ordered = codes.filter { $0 == plan.primaryLocale } + codes.filter { $0 != plan.primaryLocale }
        return ordered.map { code in
            let control = plan.artwork.first { $0.kind == kind && $0.locale == code }
            let treatment = variant?.files.first { $0.kind == kind && $0.locale == code }
            return LocaleRow(
                locale: code, name: ExtrasReviewPlanner.name(of: code), control: control.map { fileURL($0.fileID, "png") },
                treatment: treatment.map { fileURL($0.fileID, "png") }, checks: treatment?.checks ?? []
            )
        }
    }

    var variantErrors: [ArtworkCheck] { rows.flatMap(\.checks).filter(\.isError) }

    /// The current image still waits in Review & Push: the test's control
    /// is what the page shows now, so it should go first.
    var controlWaits: Bool { plan.controlWaits(placement) }

    var canCreateTest: Bool { createBlockReason == nil && phase == .variantReady }

    /// Why Create Test is off, or nil.
    var createBlockReason: String? {
        guard variant != nil else { return String(localized: "The variant isn’t in yet.") }
        if let error = variantErrors.first {
            return String(localized: "The variant breaks one of Apple’s rules: \(error.text) Ask for another.")
        }
        guard environment != nil else { return String(localized: "These services can’t make tests in App Store Connect.") }
        return nil
    }

    // MARK: - Asking

    /// Asks the run's design source for the variant, and starts Claude
    /// Code for it when AppLocalizer can.
    func ask(center: AutopilotCenter?, launcher: ClaudeCodeLauncher?) async {
        notice = nil
        guard let center, center.requestVariant(appID: plan.appID, role: role, kind: kind) else {
            notice = String(localized: "Screenshot Autopilot has no finished run for \(plan.appName) to ask. Run it again, then come back here.")
            return
        }
        assistantName = center.run(for: plan.appID)?.client
        phase = .asking
        launchedRunID = nil
        await startClaudeCode(center: center, launcher: launcher)
    }

    /// Starts Claude Code again for the variant still asked for, after it
    /// stopped or was stopped before sending it.
    func continueAsking(center: AutopilotCenter?, launcher: ClaudeCodeLauncher?) async {
        guard phase == .asking, let center, center.run(for: plan.appID)?.variantRequest != nil else { return }
        notice = nil
        await startClaudeCode(center: center, launcher: launcher)
    }

    private func startClaudeCode(center: AutopilotCenter, launcher: ClaudeCodeLauncher?) async {
        guard let launcher, launcher.canStart else {
            notice = String(localized: "Ask your assistant to continue \(plan.appName)’s run: next_step says what to design.")
            return
        }
        isStarting = true
        defer { isStarting = false }
        guard let id = await AutopilotContinuation.start(appID: plan.appID, appName: plan.appName, center: center, launcher: launcher) else {
            notice = String(localized: "Ask your assistant to continue \(plan.appName)’s run: next_step says what to design.")
            return
        }
        launchedRunID = id
    }

    func cancelAsking(center: AutopilotCenter?) {
        center?.cancelVariant(appID: plan.appID)
        phase = variant == nil ? .intro : .variantReady
        notice = nil
    }

    /// What's done and what's left while it waits for the variant; empty
    /// when nothing's asked.
    func steps(of run: AutopilotRun?) -> [ProductPageTestAskingStep] {
        guard phase == .asking, let request = run?.variantRequest else { return [] }
        return ProductPageTestAskingStep.steps(
            for: request, assistant: assistantName ?? run?.client ?? String(localized: "the assistant"),
            placement: placement.title.lowercased(), direction: plan.directionName.isEmpty ? nil : plan.directionName,
            languageCount: rows.count
        )
    }

    /// The Claude Code working on the variant: the one AppLocalizer started
    /// for it, else the run's latest since it was asked for.
    func session(in launcher: ClaudeCodeLauncher?, run: AutopilotRun?) -> ClaudeCodeRun? {
        guard let launcher else { return nil }
        if let started = launcher.run(launchedRunID) { return started }
        guard let askedAt = run?.variantRequest?.askedAt else { return nil }
        return launcher.latestRun(appID: plan.appID, purpose: .autopilot, since: askedAt)
    }

    /// Nobody's working on the variant AppLocalizer could start Claude Code
    /// for: it stopped (or was stopped) before sending it.
    func isIdle(session: ClaudeCodeRun?, run: AutopilotRun?, canStart: Bool) -> Bool {
        guard phase == .asking, canStart, !isStarting, let request = run?.variantRequest, request.receivedAt == nil else { return false }
        return session?.isActive != true
    }

    /// Picks up the variant once the assistant sent it.
    func reload() async {
        guard let extras = await loadExtras() else { return }
        plan.variant = extras.variant
        if phase == .asking, variant != nil {
            phase = .variantReady
            notice = nil
        }
    }

    // MARK: - The test

    /// What the run makes: each language the variant was rendered in, with
    /// its current image for the export.
    var request: ProductPageTestRequest? {
        let locales = rows.compactMap { row -> ProductPageTestLocale? in
            guard let treatment = row.treatment else { return nil }
            return ProductPageTestLocale(locale: row.locale, treatmentFile: treatment, treatmentPixelSize: kind.pixelSize, controlFile: row.control)
        }
        guard !locales.isEmpty else { return nil }
        return ProductPageTestRequest(
            appID: plan.appID, appName: plan.appName, placement: placement, testName: testName, locales: locales,
            exportFolder: exportFolder
        )
    }

    /// Creates the test (a draft the person starts in App Store Connect),
    /// or exports both variants when the API can't.
    func createTest() {
        guard canCreateTest, let environment, let request else { return }
        let run = ProductPageTestRun(request: request, environment: environment)
        run.onFinish = { [weak self] _ in self?.phase = .finished }
        self.run = run
        phase = .testing
        run.start()
    }
}
