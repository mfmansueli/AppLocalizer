//
//  StorePageViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The Store Page section's state: App Store Connect's texts for the chosen
/// version, with every pending change laid on top, and the views, sheets and
/// helpers that edit them.
///
/// The `ChangeQueue` is where edits live. Each edit rebuilds the matching
/// `PendingChange`s (`commit(_:)`); whenever the queue changes from outside
/// (Review & Push discarded or pushed something), `queueDidChange()`
/// rebuilds the listing from App Store Connect's values plus what's still
/// queued. So queued values survive navigation and relaunch, and
/// discarding one in review reverts the field.
@MainActor
@Observable
final class StorePageViewModel {
    let app: StoreApp
    let services: any StorePageServices
    let queue: ChangeQueue
    let translation: TranslateMissingViewModel
    let inAppTexts: InAppTextsViewModel
    private let summaries: AppSummaryStore?
    private let push: PushController?

    // MARK: - Loaded state

    private(set) var content: StorePageContent?
    /// App Store Connect's values with pending changes and tags on top: what
    /// the grid and the editor show.
    private(set) var listing: StoreListing?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    /// Locales added with "Add Locale" that have nothing queued yet.
    private(set) var addedLocales: [StoreLocale] = []
    /// Store Page → Screenshots, made once the store page has loaded.
    private(set) var screenshots: ScreenshotsViewModel?

    // MARK: - Navigation

    var mode: StorePageMode = .coverage {
        didSet { modeDidChange() }
    }

    /// The locale the editor shows on its right.
    var editorLocale: StoreLocale?
    /// The field the editor scrolls to when it opens.
    var editorFocus: ListingField?
    var sheet: StorePageSheet?
    var isImporterPresented = false
    var exportFormat: ListingTransferFormat?
    /// "View Version 1.3" on the no-editable-version page: show the live
    /// version read-only (its app-level fields stay editable).
    var showsReadOnlyVersion = false

    // MARK: - Sheets

    /// Find and Replace's fields.
    var findQuery = FindReplaceQuery(find: "", replacement: "")
    /// The import sheet's diff, once a file was read.
    var importPreview: ListingImportPreview?
    /// Why the chosen file couldn't be read at all.
    var importError: String?
    /// Something to say after an action, e.g. "3 fields copied".
    var notice: String?

    private var selectedVersionID: String?
    private var pendingIntent: WorkspaceIntent?
    /// The overview numbers last worked out here, to notice when they change.
    private var lastSummary: StorePageSummary?

    init(
        app: StoreApp,
        services: any StorePageServices,
        queue: ChangeQueue,
        summaries: AppSummaryStore? = nil,
        push: PushController? = nil
    ) {
        self.app = app
        self.services = services
        self.queue = queue
        self.summaries = summaries
        self.push = push
        translation = TranslateMissingViewModel(translator: services.translator)
        inAppTexts = InAppTextsViewModel(app: app, services: services, queue: queue)
        translation.currentListing = { [weak self] in self?.listing }
    }

    // MARK: - Loading

    /// Fetches the chosen version (the editable one by default). A failure
    /// keeps whatever was shown, says why, and goes to the workspace banner
    /// when it's the connection or the rate limit.
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await services.content(for: app, versionID: selectedVersionID)
            let versionChanged = content?.version.id != loaded.version.id
            content = loaded
            errorMessage = nil
            rebuild()
            refreshSummaryIfNeeded()
            await updateScreenshots(content: loaded, reload: versionChanged || mode == .screenshots)
            if mode == .inAppTexts { await inAppTexts.load(listing: listing, force: true) }
            performPendingIntent()
        } catch {
            errorMessage = StorePageErrorReporter.report(error, to: push)
        }
    }

    /// Picks another version in the context bar.
    func selectVersion(_ id: StorePageVersion.ID) async {
        guard id != content?.version.id else { return }
        selectedVersionID = id
        showsReadOnlyVersion = true
        await load()
    }

    var isLoaded: Bool { content != nil }

    /// Makes the Screenshots view's model the first time, and keeps it on
    /// the shown version; it loads when the view first opens.
    private func updateScreenshots(content: StorePageContent, reload: Bool) async {
        guard let screenshots else {
            screenshots = ScreenshotsViewModel(app: app, services: services.screenshots, context: ScreenshotsContext(content: content))
            return
        }
        let context = ScreenshotsContext(content: content)
        if context != screenshots.context {
            await screenshots.update(context: context)
        } else if reload, screenshots.isLoaded {
            await screenshots.load()
        }
    }

    private func modeDidChange() {
        if mode == .editor, editorLocale == nil { editorLocale = defaultEditorLocale }
    }

    // MARK: - Queue

    /// The builder for the loaded version's changes.
    var changeBuilder: ListingChangeBuilder? {
        content.map { ListingChangeBuilder(appID: app.id, ids: $0.ids, versionString: $0.version.versionString) }
    }

    /// The queue changed: rebuild what's shown from App Store Connect's
    /// values plus what's still queued.
    func queueDidChange() {
        rebuild()
        inAppTexts.queueDidChange()
    }

    /// Rebuilds `listing` from `content`, the queue and the stored tags.
    func rebuild() {
        guard let content, let builder = changeBuilder else { return }
        let tags = MachineTranslationScope.tags(in: services.machineTranslations, appID: app.id, ids: content.ids)
        var rebuilt = content.listing(machineTranslated: tags, addedLocales: addedLocales)
        builder.apply(queue.changes(for: app.id, section: .storePage), to: &rebuilt, machineTranslated: tags)
        listing = rebuilt
        if let locale = editorLocale, !rebuilt.contains(locale) { editorLocale = defaultEditorLocale }
        saveTags()
    }

    /// Shows an edited listing and brings the queue in line with it: new and
    /// changed fields are upserted, fields back at App Store Connect's value
    /// are discarded.
    func commit(_ edited: StoreListing) {
        guard let builder = changeBuilder else { return }
        listing = edited
        let desired = builder.changes(for: edited)
        let existing = queue.changes(for: app.id, section: .storePage).filter(builder.owns)
        let desiredIDs = Set(desired.map(\.id))
        queue.discard(ids: existing.map(\.id).filter { !desiredIDs.contains($0) })
        let current = Dictionary(existing.map { ($0.id, $0) }) { first, _ in first }
        queue.upsert(contentsOf: desired.compactMap { change in
            guard let old = current[change.id] else { return change }
            var change = change
            change.createdAt = old.createdAt
            if change.newValue == old.newValue { change.remoteConflict = old.remoteConflict }
            return change == old ? nil : change
        })
        saveTags()
    }

    /// Writes the listing's machine-translation tags, and refreshes the
    /// summary when that changes what App Store Connect's texts count as.
    private func saveTags() {
        guard let content, let listing else { return }
        let store = services.machineTranslations
        var changed = false
        for level in [ListingFieldLevel.app, .version] {
            let scope = MachineTranslationScope.scope(for: level, ids: content.ids)
            let tags = listing.machineTranslationTags(at: level)
            if store.tags(appID: app.id, scope: scope) != tags {
                store.setTags(tags, appID: app.id, scope: scope)
                changed = true
            }
        }
        if changed { refreshSummaryIfNeeded() }
    }

    /// Tells the overview and sidebar when their numbers changed: after a
    /// reload brought different texts, or tags changed what App Store
    /// Connect's texts count as. Only for the version the summary is about.
    private func refreshSummaryIfNeeded() {
        guard let content, content.editableVersion == nil || content.version.isEditable else { return }
        let tags = MachineTranslationScope.tags(in: services.machineTranslations, appID: app.id, ids: content.ids)
        let summary = content.summary(machineTranslated: tags)
        defer { lastSummary = summary }
        guard let lastSummary, lastSummary != summary, let summaries else { return }
        summaries.invalidate(app.id)
        Task { [app] in await summaries.load(app) }
    }

    // MARK: - Intents

    /// The intents this section takes; the rest belong to other sections.
    static func handles(_ intent: WorkspaceIntent) -> Bool {
        switch intent {
        case .translateMissing, .findAndReplace, .importTranslations, .search: true
        case .reviewSuggestions, .applyRecommendedPrices, .showResults, .editPriceSchedule, .showPrices, .openAppInformationPage: false
        }
    }

    /// Handles an intent now, or once the store page has loaded.
    func handle(_ intent: WorkspaceIntent) {
        pendingIntent = intent
        if isLoaded { performPendingIntent() }
    }

    private func performPendingIntent() {
        guard let intent = pendingIntent else { return }
        pendingIntent = nil
        switch intent {
        case .translateMissing: presentTranslate()
        case .findAndReplace, .search: presentFindReplace()
        case .importTranslations: isImporterPresented = true
        case .reviewSuggestions, .applyRecommendedPrices, .showResults, .editPriceSchedule, .showPrices, .openAppInformationPage: break
        }
    }

    // MARK: - Reading

    /// The first locale the editor shows: the first one that isn't primary.
    var defaultEditorLocale: StoreLocale? {
        guard let listing else { return nil }
        return listing.displayLocales.first { $0 != listing.primaryLocale } ?? listing.primaryLocale
    }

    /// No editable version exists and the person hasn't asked to see the
    /// live one: the "No version to edit" page.
    var showsNoVersionPage: Bool {
        guard let content else { return false }
        return content.editableVersion == nil && !showsReadOnlyVersion
    }

    /// Version-level fields can be edited (the version isn't live or in review).
    var isVersionEditable: Bool { content?.version.isEditable ?? false }

    var coverage: ListingCoverageGrid? { listing?.coverage }

    /// "10 of 39 locales · 11 missing · 1 over the limit · …".
    var summaryLine: String { coverage?.summary.line ?? "" }

    func value(_ field: ListingField, in locale: StoreLocale) -> String {
        listing?.value(field, in: locale) ?? ""
    }

    func draft(_ field: ListingField, in locale: StoreLocale) -> ListingFieldDraft {
        listing?.draft(field, in: locale) ?? ListingFieldDraft()
    }

    func canEdit(_ field: ListingField) -> Bool {
        listing?.canEdit(field) ?? false
    }

    /// Over the limit, an invalid URL, empty or fine.
    func validation(of field: ListingField, in locale: StoreLocale) -> ListingFieldValidation {
        listing?.validation(of: field, in: locale) ?? .empty
    }

    // MARK: - Locales

    /// "Add Locale": the locale shows empty in the grid and opens in the
    /// editor. Nothing is created in App Store Connect until a field of it
    /// is pushed.
    func addLocale(_ locale: StoreLocale) {
        if listing?.contains(locale) != true, !addedLocales.contains(locale) { addedLocales.append(locale) }
        rebuild()
        openEditor(locale)
    }

    /// Opens the editor on a locale, scrolled to `field`.
    func openEditor(_ locale: StoreLocale, field: ListingField? = nil) {
        editorLocale = locale
        editorFocus = field
        mode = .editor
    }
}
