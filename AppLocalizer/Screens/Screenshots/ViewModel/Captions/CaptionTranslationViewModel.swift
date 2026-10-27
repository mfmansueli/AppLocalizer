//
//  CaptionTranslationViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Translate Missing… on the Captions tab. It runs the Store Page's
/// translator with Settings → Translation's provider, tone and glossary.
/// There's no review step: each caption is written as it arrives, tagged
/// machine-translated, and measured; one that doesn't fit is flagged in
/// the table, never cut.
@MainActor
@Observable
final class CaptionTranslationViewModel {
    unowned let screenshots: ScreenshotsViewModel

    var provider: TranslationProvider = .appleTranslation
    /// Settings → Translation's terms and tone; read-only here.
    private(set) var glossary = TranslationGlossary()
    /// Settings → Translation's AI provider.
    private(set) var aiProvider = AIProviderSetup.none
    var excludedLocales: Set<StoreLocale> = []
    /// The prompt was copied for the assistant.
    var isAssistantPromptCopied = false
    private(set) var isRunning = false
    private(set) var job: CaptionTranslationJob?
    /// The provider of the batch that runs, for the banner.
    private(set) var runProvider: TranslationProvider = .appleTranslation
    /// Apple Translation's status per target locale, once checked.
    private(set) var availability: [StoreLocale: TranslationAvailability] = [:]
    /// Captions written by the last batch that don't fit.
    private(set) var flagged: [LocaleSlot] = []
    @ObservationIgnored private var task: Task<Void, Never>?

    init(screenshots: ScreenshotsViewModel) {
        self.screenshots = screenshots
    }

    private var translator: any ListingTranslator { screenshots.services.translator }
    /// The AI provider's translator while its batch runs.
    @ObservationIgnored private var aiTranslator: (any ListingTranslator)?

    /// Opens the sheet with the settings' provider, glossary and AI provider.
    func prepare(provider: TranslationProvider, glossary: TranslationGlossary, aiProvider: AIProviderSetup = .none) {
        self.provider = provider
        self.glossary = glossary
        self.aiProvider = aiProvider
        excludedLocales = []
        isAssistantPromptCopied = false
    }

    // MARK: - The plan

    /// Every empty caption in scope.
    var plan: CaptionTranslationJob {
        guard let document = screenshots.document else { return CaptionTranslationJob(sourceLocale: screenshots.context.primaryLocale, items: []) }
        let locales = document.scope.orderedLocales(in: screenshots.locales.map(\.code)).compactMap(screenshots.locale(code:))
        return CaptionTranslationPlanner.plan(
            captions: document.captions, locales: locales, primary: screenshots.context.primaryLocale, slotCount: document.slotCount
        )
    }

    /// The plan without the unchecked locales.
    var selectedPlan: CaptionTranslationJob {
        let plan = plan
        return CaptionTranslationJob(sourceLocale: plan.sourceLocale, items: plan.items.filter { !excludedLocales.contains($0.locale) })
    }

    func isIncluded(_ locale: StoreLocale) -> Bool {
        !excludedLocales.contains(locale)
    }

    func setIncluded(_ locale: StoreLocale, _ isIncluded: Bool) {
        if isIncluded { excludedLocales.remove(locale) } else { excludedLocales.insert(locale) }
    }

    /// "Translate 20".
    var startTitle: String {
        String(localized: "Translate \(selectedPlan.totalCount)")
    }

    var canStart: Bool {
        setupMessage == nil && !selectedPlan.isEmpty && !isRunning
    }

    /// What the provider needs before it can translate, or nil.
    var setupMessage: String? {
        provider == .aiProvider ? aiProvider.setupMessage : provider.setupMessage
    }

    /// Target locales Apple Translation needs to download first.
    var localesNeedingDownload: [StoreLocale] {
        plan.locales.filter { availability[$0] == .needsDownload && isIncluded($0) }
    }

    var unsupportedLocales: [StoreLocale] {
        plan.locales.filter { availability[$0] == .unsupported && isIncluded($0) }
    }

    func checkAvailability() async {
        let job = plan
        for locale in job.locales where job.items.contains(where: { $0.locale == locale && $0.method == .translate }) {
            availability[locale] = await translator.availability(from: job.sourceLocale, to: locale)
        }
    }

    // MARK: - Running

    /// Starts the batch; the sheet closes and the banner takes over.
    func start() {
        guard canStart else { return }
        job = selectedPlan
        runProvider = provider
        aiTranslator = provider == .aiProvider ? aiProvider.makeTranslator(glossary.tone) : nil
        flagged = []
        isRunning = true
        task = Task { [weak self] in await self?.run() }
    }

    /// Cancel: what arrived stays written.
    func cancel() {
        task?.cancel()
        job?.cancelRemaining()
        finish()
    }

    /// Waits for the batch (tests).
    func waitUntilFinished() async {
        await task?.value
    }

    private func run() async {
        let protector = glossary.protector
        while let item = job?.nextQueued, !Task.isCancelled {
            job?.start(item.key)
            do {
                let caption = try await translated(item, protector: protector)
                guard !Task.isCancelled else { break }
                job?.complete(item.key, with: caption)
                await write(caption, for: item.key)
            } catch {
                job?.fail(item.key, message: error.localizedDescription)
            }
        }
        if !Task.isCancelled { finish() }
    }

    private func translated(_ item: CaptionTranslationItem, protector: GlossaryProtector) async throws -> ScreenshotCaption {
        if item.method == .copy {
            return ScreenshotCaption(headline: item.source.headline, subhead: item.source.subhead, provenance: .machineTranslated)
        }
        let target = item.locale
        let active = aiTranslator ?? translator
        if aiTranslator == nil {
            if availability[target] == nil { availability[target] = await active.availability(from: job?.sourceLocale ?? target, to: target) }
            switch availability[target] {
            case .needsDownload: throw CaptionTranslationError.needsDownload(target)
            case .unsupported: throw CaptionTranslationError.unsupported(target)
            case .ready, nil: break
            }
        }
        let source = job?.sourceLocale ?? screenshots.context.primaryLocale
        let headline = protector.protect(item.source.headline)
        let translatedHeadline = try await active.translateCaption(headline.text, from: source, to: target)
        var subhead: String?
        if let text = item.source.visibleSubhead {
            let protected = protector.protect(text)
            subhead = try await protected.restore(active.translateCaption(protected.text, from: source, to: target))
        }
        return ScreenshotCaption(headline: headline.restore(translatedHeadline), subhead: subhead, provenance: .machineTranslated)
    }

    /// Writes one arrival and measures it on every rendered display type.
    private func write(_ caption: ScreenshotCaption, for key: LocaleSlot) async {
        guard var document = screenshots.document else { return }
        document.captions.setCaption(caption, locale: key.locale, slot: key.slot)
        await screenshots.commit(document)
        if !screenshots.captionFits(caption, at: key) { flagged.append(key) }
    }

    private func finish() {
        guard isRunning else { return }
        isRunning = false
        aiTranslator = nil
        let done = job?.doneCount ?? 0
        guard done > 0 || (job?.failedCount ?? 0) > 0 else { return }
        screenshots.notice = summary(done: done)
    }

    /// "Translated 20 captions with Apple Translation. 1 doesn’t fit and is
    /// flagged."
    private func summary(done: Int) -> String {
        let translated = done == 1
            ? String(localized: "Translated 1 caption with \(runProvider.shortTitle).")
            : String(localized: "Translated \(done) captions with \(runProvider.shortTitle).")
        var parts = [translated]
        switch flagged.count {
        case 0: break
        case 1: parts.append(String(localized: "1 doesn’t fit and is flagged."))
        default: parts.append(String(localized: "\(flagged.count) don’t fit and are flagged."))
        }
        if let failed = job?.failedCount, failed > 0 {
            let reason = job?.items.lazy.compactMap { item -> String? in
                if case let .failed(message) = item.state { return message }
                return nil
            }.first ?? ""
            parts.append(failed == 1 ? String(localized: "1 couldn’t be translated: \(reason)") : String(localized: "\(failed) couldn’t be translated: \(reason)"))
        }
        return parts.joined(separator: " ")
    }
}
