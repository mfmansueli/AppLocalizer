//
//  ProductPageTestRun.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Makes a Product Page Optimization test of the header or the search
/// results image from Review & Push: a draft test with one treatment,
/// each language's variant uploaded to the app's library and placed on the
/// treatment's page in that language. It stops at a test already in
/// progress (App Store Connect runs one at a time). When App Store Connect
/// won't take the artwork on a treatment, the draft is deleted and both
/// variants are exported with the steps to make the test by hand; the
/// outcome never says a test was created when it wasn't. The test isn't
/// started unless the request asks: the person starts it in App Store
/// Connect.
///
/// The steps live in `ProductPageTestRun+Steps`, `+Upload` and
/// `+Requests`.
@MainActor
@Observable
final class ProductPageTestRun {
    enum Phase: Hashable, Sendable {
        case idle
        case running
        case finished
    }

    let request: ProductPageTestRequest
    let environment: ProductPageTestEnvironment
    var phase: Phase = .idle
    /// The step under way; nil before and after.
    var step: ProductPageTestStep?
    /// Each language's variant, by locale code.
    var localeStatuses: [String: ExtrasPushStatus]
    var outcome: ProductPageTestOutcome?
    /// While the hourly budget is used up: when the run resumes.
    var pausedUntil: Date?

    /// Called once the run ends.
    @ObservationIgnored var onFinish: @MainActor (ProductPageTestRun) async -> Void = { _ in }
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored var libraryID: String?
    @ObservationIgnored var refData: AssetLibraryRefData?

    init(request: ProductPageTestRequest, environment: ProductPageTestEnvironment) {
        self.request = request
        self.environment = environment
        localeStatuses = Dictionary(request.locales.map { ($0.locale, .waiting) }, uniquingKeysWith: { first, _ in first })
    }

    func status(of locale: String) -> ExtrasPushStatus {
        localeStatuses[locale] ?? .waiting
    }

    var isRunning: Bool { phase == .running }

    /// "Making the test", then the outcome's title.
    var title: String {
        outcome?.title ?? String(localized: "Making the test")
    }

    func start() {
        guard phase != .running else { return }
        phase = .running
        outcome = nil
        task = Task { [weak self] in
            guard let self else { return }
            let outcome = await makeTest()
            self.outcome = outcome
            step = nil
            phase = .finished
            await onFinish(self)
        }
    }

    func waitUntilFinished() async {
        await task?.value
    }
}
