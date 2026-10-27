//
//  TranslateMissingViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// "Translate Missing…": the sheet's choices, the batch while it runs, and
/// the suggestions afterwards, accepted or rejected per field.
///
/// Apple Translation and the AI provider run here; the assistant gets a
/// prompt instead, and a provider that isn't set up says what it needs.
/// Languages Apple Translation hasn't downloaded are listed before
/// starting; their fields fail with a reason if started anyway.
@MainActor
@Observable
final class TranslateMissingViewModel {
    enum Phase: Hashable, Sendable {
        case idle
        case running
        case reviewing
    }

    var provider: TranslationProvider = .appleTranslation {
        didSet { startsOnSettingsProvider = false }
    }

    /// Set when the sheet is prepared: it starts on Settings' provider
    /// unless someone picked one since (a scene, a menu command).
    private var startsOnSettingsProvider = false
    var glossary: TranslationGlossary
    /// One field, or nil for every field.
    var field: ListingField? {
        didSet { scope.fields = field.map { [$0] } }
    }

    /// Locales unchecked in the sheet.
    var excludedLocales: Set<StoreLocale> = []
    /// The person copied the prompt for their assistant: the sheet waits.
    var isAssistantPromptCopied = false
    private(set) var phase: Phase = .idle
    private(set) var job: TranslationJob?
    private(set) var review: TranslationReview?
    /// Apple Translation's status per target locale, once checked.
    private(set) var availability: [StoreLocale: TranslationAvailability] = [:]
    /// The provider of the batch that ran, for the suggestions' title.
    private(set) var runProvider: TranslationProvider = .appleTranslation

    /// The listing to plan against and to compare suggestions with.
    var currentListing: () -> StoreListing? = { nil }
    /// Settings → Translation's AI provider.
    var aiProvider = AIProviderSetup.none

    private let translator: any ListingTranslator
    private var scope = TranslationScope.everything
    private var includesFilled = false
    private var task: Task<Void, Never>?

    init(translator: any ListingTranslator, glossary: TranslationGlossary = TranslationGlossary(terms: [], tone: .warmAndSimple)) {
        self.translator = translator
        self.glossary = glossary
    }

    // MARK: - The sheet

    /// Settings → Translation, when the sheet opens: the provider it starts
    /// on, the glossary's terms and tone, and the AI provider.
    func applySettings(provider: TranslationProvider, glossary: TranslationGlossary, aiProvider: AIProviderSetup) {
        if startsOnSettingsProvider { self.provider = provider }
        self.aiProvider = aiProvider
        var merged = glossary
        for term in self.glossary.terms {
            merged.add(term)
        }
        self.glossary = merged
    }

    /// Resets the sheet for a scope. The glossary starts with the app's name.
    func prepare(scope: TranslationScope, includeFilled: Bool) {
        self.scope = scope
        includesFilled = includeFilled
        field = scope.fields?.count == 1 ? scope.fields?.first : nil
        self.scope.fields = scope.fields
        excludedLocales = []
        provider = .appleTranslation
        startsOnSettingsProvider = true
        isAssistantPromptCopied = false
        if let listing = currentListing(), glossary.terms.isEmpty {
            glossary.add(listing.appName.split(separator: ":").first.map(String.init) ?? listing.appName)
        }
    }

    /// Everything in scope, before the locale checkboxes.
    var plan: TranslationJob {
        guard let listing = currentListing() else { return TranslationJob(sourceLocale: .englishUS, items: []) }
        return TranslationPlanner.plan(listing, scope: scope, includeFilled: includesFilled)
    }

    /// What Translate would run: the plan minus unchecked locales.
    var selectedPlan: TranslationJob {
        guard let listing = currentListing() else { return plan }
        let locales = Set(plan.locales).subtracting(excludedLocales)
        return TranslationPlanner.plan(listing, scope: TranslationScope(fields: scope.fields, locales: locales), includeFilled: includesFilled)
    }

    /// Fields the sheet's picker offers: everything that can be translated
    /// or copied.
    var fieldOptions: [ListingField] {
        currentListing()?.fields.filter { currentListing()?.canEdit($0) == true } ?? []
    }

    var isSendingWhatsNew: Bool { includesFilled }

    func isIncluded(_ locale: StoreLocale) -> Bool {
        !excludedLocales.contains(locale)
    }

    func setIncluded(_ locale: StoreLocale, _ isIncluded: Bool) {
        if isIncluded { excludedLocales.remove(locale) } else { excludedLocales.insert(locale) }
    }

    /// The Translate button: "Translate 38 Fields".
    var startTitle: String {
        let count = selectedPlan.totalCount
        return count == 1 ? String(localized: "Translate 1 Field") : String(localized: "Translate \(count) Fields")
    }

    var canStart: Bool {
        setupMessage == nil && !selectedPlan.isEmpty && phase != .running
    }

    /// What the provider needs before it can translate, or nil.
    var setupMessage: String? {
        provider == .aiProvider ? aiProvider.setupMessage : provider.setupMessage
    }

    /// Target locales Apple Translation needs to download first.
    var localesNeedingDownload: [StoreLocale] {
        plan.locales.filter { availability[$0] == .needsDownload && isIncluded($0) }
    }

    /// Target locales Apple Translation can't translate into.
    var unsupportedLocales: [StoreLocale] {
        plan.locales.filter { availability[$0] == .unsupported && isIncluded($0) }
    }

    /// Asks Apple Translation about every target locale that has something
    /// to translate (copies need nothing).
    func checkAvailability() async {
        let job = plan
        for locale in job.locales where job.items.contains(where: { $0.key.locale == locale && $0.method == .translate }) {
            availability[locale] = await translator.availability(from: job.sourceLocale, to: locale)
        }
    }

    // MARK: - Running

    /// Starts the batch: copies finish at once, the rest go to the
    /// translator one at a time, glossary terms protected.
    func start() {
        guard canStart else { return }
        var job = selectedPlan
        job.completeCopies()
        self.job = job
        review = nil
        runProvider = provider
        phase = .running
        task = Task { [weak self] in await self?.run() }
    }

    /// "Cancel": keeps what's finished and shows it as suggestions.
    func cancel() {
        task?.cancel()
        job?.cancelRemaining()
        finishRunning()
    }

    /// Waits for the batch (tests).
    func waitUntilFinished() async {
        await task?.value
    }

    private func run() async {
        let protector = glossary.protector
        let aiTranslator = runProvider == .aiProvider ? aiProvider.makeTranslator(glossary.tone) : nil
        while let item = job?.nextQueued, !Task.isCancelled {
            job?.start(item.id)
            let target = item.key.locale
            if let aiTranslator {
                await translate(item, with: aiTranslator, protector: protector)
                continue
            }
            if availability[target] == nil { availability[target] = await translator.availability(from: item.sourceLocale, to: target) }
            switch availability[target] {
            case .needsDownload:
                job?.fail(item.id, message: String(localized: "\(target.name) isn’t downloaded for Apple Translation."))
                continue
            case .unsupported:
                job?.fail(item.id, message: String(localized: "Apple Translation can’t translate into \(target.name)."))
                continue
            case .ready, nil:
                break
            }
            await translate(item, with: translator, protector: protector)
        }
        if !Task.isCancelled { finishRunning() }
    }

    /// One field, glossary terms protected on the way out and back.
    private func translate(_ item: TranslationItem, with translator: any ListingTranslator, protector: GlossaryProtector) async {
        let target = item.key.locale
        let protected = protector.protect(item.sourceText)
        do {
            let translated = try await translator.translate(protected.text, field: item.key.field, from: item.sourceLocale, to: target)
            guard !Task.isCancelled else { return }
            job?.complete(item.id, with: protected.restore(translated))
        } catch {
            job?.fail(item.id, message: error.localizedDescription)
        }
    }

    private func finishRunning() {
        guard phase == .running, let job, let listing = currentListing() else { return }
        review = listing.suggestions(from: job)
        phase = .reviewing
    }

    // MARK: - Suggestions

    func accept(_ id: ListingFieldKey) { review?.accept(id) }
    func reject(_ id: ListingFieldKey) { review?.reject(id) }
    func undo(_ id: ListingFieldKey) { review?.undo(id) }
    func acceptAll() { review?.acceptAll() }
    func rejectAll() { review?.rejectAll() }

    /// Fields the provider couldn't translate, with the first reason.
    var failureSummary: String? {
        guard let job, job.failedCount > 0 else { return nil }
        let reason = job.items.lazy.compactMap { item -> String? in
            if case let .failed(message) = item.state { return message }
            return nil
        }.first ?? ""
        let count = job.failedCount == 1 ? String(localized: "1 field couldn’t be translated.") : String(localized: "\(job.failedCount) fields couldn’t be translated.")
        return "\(count) \(reason)"
    }

    /// "Done": hands back the decisions and goes back to idle.
    func finish() -> TranslationReview? {
        defer {
            review = nil
            job = nil
            phase = .idle
        }
        return review
    }
}
