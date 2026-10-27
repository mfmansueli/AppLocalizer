//
//  TemplateEditorViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The Template tab (design README §2 "Template editor"): one slot of one
/// locale on the canvas, the stress strip and the inspector.
///
/// Every inspector edit is a `TemplateOperation` that goes through
/// `TemplateOperationApplier`, the same check an assistant's proposal
/// gets, so a refusal reads the same. Edits pile up as an unsaved draft
/// with an undo stack; Save makes the next version in `TemplateHistory`,
/// and History restores an old one as a new version.
@MainActor
@Observable
final class TemplateEditorViewModel {
    unowned let screenshots: ScreenshotsViewModel

    // MARK: - Navigation

    /// 0-based.
    var slot = 0
    var localeCode: String
    /// The safe area and the caption box drawn over the canvas.
    var showsGuides = true
    var isHistoryPresented = false
    var isStarterSheetPresented = false

    // MARK: - Edits

    /// Edits not saved as a version yet; nil when there are none.
    private(set) var draft: ScreenshotTemplate?
    /// The templates before each edit of the draft, newest last.
    private(set) var undoStack: [ScreenshotTemplate] = []
    /// Why the last edit was refused, until the next one.
    var refusals: TemplateRefusals?
    /// Why an uploaded font couldn't be used.
    var uploadError: String?
    /// The fields the last edit set: dragging a slider coalesces into one
    /// undo step.
    @ObservationIgnored var lastEditPaths: [String] = []

    // MARK: - Previews

    // Set by `refreshPreviews()` and the loads it starts.

    var canvas: SlotPreview?
    var strip: [StressStripEntry] = []
    /// Translations of the primary caption made for stress locales without
    /// a caption, by locale and slot. Never saved.
    var previewCaptions: [LocaleSlot: ScreenshotCaption] = [:]
    @ObservationIgnored var requestedPreviews: Set<LocaleSlot> = []
    /// Which fonts draw which scripts, for the inspector; cleared when the
    /// catalog changes.
    @ObservationIgnored var fontCoverage = FontCoverageCache()

    init(screenshots: ScreenshotsViewModel) {
        self.screenshots = screenshots
        localeCode = screenshots.context.primaryLocale.code
    }

    // MARK: - The template

    /// The saved current version.
    var savedTemplate: ScreenshotTemplate? { screenshots.document?.template }

    /// What the editor shows: the draft, else the current version.
    var template: ScreenshotTemplate? { draft ?? savedTemplate }

    var history: TemplateHistory? { screenshots.document?.history }

    var hasUnsavedEdits: Bool { draft != nil }

    var canUndo: Bool { !undoStack.isEmpty }

    /// "v4".
    var versionTitle: String { "v\(history?.currentNumber ?? 0)" }

    /// "Save as v5".
    var saveTitle: String { String(localized: "Save as v\((history?.currentNumber ?? 0) + 1)") }

    /// "Proposed by Claude Code · 10:42" when the current version came
    /// from an accepted proposal and nothing is edited on top of it.
    var assistantNote: (client: String, text: String)? {
        guard !hasUnsavedEdits, let current = history?.current, let client = current.assistant else { return nil }
        return (client, String(localized: "Proposed by \(client) · \(current.date.formatted(date: .omitted, time: .shortened))"))
    }

    var applier: TemplateOperationApplier { TemplateOperationApplier(fonts: screenshots.fonts) }

    /// Applies inspector edits to the draft, or keeps the refusals to show.
    /// Returns whether they applied.
    @discardableResult
    func apply(_ operations: [TemplateOperation]) -> Bool {
        guard let template else { return false }
        switch applier.applying(operations, to: template) {
        case let .success(result):
            refusals = nil
            guard result != template else { return true }
            let paths = operations.map(\.path)
            if paths != lastEditPaths || draft == nil || undoStack.isEmpty { undoStack.append(template) }
            lastEditPaths = paths
            setDraft(result)
            return true
        case let .failure(refusals):
            self.refusals = refusals
            return false
        }
    }

    /// One field: `set("caption.headline.size", to: 104)`.
    @discardableResult
    func set(_ path: String, to value: JSONValue) -> Bool {
        apply([.replace(path, with: value)])
    }

    /// Takes back the last edit.
    func undo() {
        guard let previous = undoStack.popLast() else { return }
        refusals = nil
        lastEditPaths = []
        setDraft(previous)
    }

    /// Drops every unsaved edit.
    func discardEdits() {
        draft = nil
        undoStack = []
        refusals = nil
        lastEditPaths = []
    }

    /// Saves the draft as the next version, noted with what changed.
    func save() async {
        guard let draft, let saved = savedTemplate, var document = screenshots.document, var history = document.history else { return }
        let note = TemplateDiff.note(for: TemplateDiff.changes(from: saved, to: draft))
        history.save(draft, date: .now, note: note)
        document.history = history
        discardEdits()
        await screenshots.commit(document)
    }

    /// What Save would note, for the header's help text.
    var draftSummary: String? {
        guard let draft, let saved = savedTemplate else { return nil }
        return TemplateDiff.note(for: TemplateDiff.changes(from: saved, to: draft))
    }

    /// A draft that renders like the saved version isn't an edit.
    private func setDraft(_ template: ScreenshotTemplate) {
        if let saved = savedTemplate, saved.contentHash == template.contentHash, saved.name == template.name {
            draft = nil
            undoStack = []
        } else {
            draft = template
        }
    }

    // MARK: - Navigation

    /// "Open in Template Editor" and Captions' links: the slot of a
    /// locale.
    func focus(on target: LocaleSlot) {
        localeCode = target.locale
        slot = max(0, min(target.slot, max(0, slotCount - 1)))
    }

    var slotCount: Int { template?.slots.count ?? screenshots.document?.slotCount ?? 5 }

    /// "1 Today", "2 Week"…
    var slotTitles: [String] {
        (0..<slotCount).map { "\($0 + 1) \(screenshots.document?.slotName($0) ?? "")" }
    }

    var locale: StoreLocale {
        screenshots.locale(code: localeCode) ?? screenshots.context.primaryLocale
    }

    /// The locale menu: the primary, then the localized sets.
    var localeOptions: [StoreLocale] {
        guard let document = screenshots.document else { return [screenshots.context.primaryLocale] }
        let codes = document.scope.orderedLocales(in: screenshots.locales.map(\.code))
        var options = codes.compactMap { screenshots.locale(code: $0) }
        if !options.contains(locale) { options.append(locale) }
        return options
    }

    var displayType: ScreenshotDisplayType { screenshots.displayType }

    /// "Write your captions next.": the primary locale has none.
    var needsPrimaryCaptions: Bool {
        guard let document = screenshots.document else { return false }
        return document.captions.count(locale: screenshots.context.primaryLocale.code, slotCount: slotCount) == 0
    }
}
