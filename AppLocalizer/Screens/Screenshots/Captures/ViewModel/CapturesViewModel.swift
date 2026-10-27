//
//  CapturesViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The Captures tab (design README §2 "Captures"): the drop zone, the
/// matching step and the coverage. Matching only reads names and image
/// headers; Import copies the files next to the document (never to App
/// Store Connect) and, the first time, sets the scope to the locales whose
/// interface was captured.
@MainActor
@Observable
final class CapturesViewModel {
    unowned let screenshots: ScreenshotsViewModel

    /// The import at the matching step.
    var session: CaptureImportSession?
    /// Files are dragged over the drop zone: how many, when known.
    var dropHover: DropHover?
    var isImporterPresented = false
    private(set) var isScanning = false
    private(set) var isImporting = false
    var errorMessage: String?
    /// Every matched row shows, not just the first few.
    var showsAllMatched = false
    /// Folders chosen with the open panel, kept accessible until Import.
    @ObservationIgnored private var scopedURLs: [URL] = []

    /// Matched rows shown before "+ 45 more matched files".
    static let matchedPreviewCount = 7

    /// What the drop zone says while files hover over it.
    struct DropHover: Hashable {
        var fileCount: Int?
    }

    init(screenshots: ScreenshotsViewModel) {
        self.screenshots = screenshots
    }

    private var document: ScreenshotsDocument? { screenshots.document }

    // MARK: - Starting an import

    /// Dropped or chosen files and folders: scans them and shows the
    /// matching step.
    func scan(_ urls: [URL], securityScoped: Bool = false) async {
        guard !urls.isEmpty else { return }
        stopAccessing()
        if securityScoped {
            scopedURLs = urls.filter { $0.startAccessingSecurityScopedResource() }
        }
        isScanning = true
        defer { isScanning = false }
        let scanner = CaptureFolderScanner(reader: screenshots.services.attachmentReader)
        do {
            let scan = try await Task.detached { try await scanner.scan(urls) }.value
            present(scan)
        } catch {
            stopAccessing()
            errorMessage = error.localizedDescription
        }
    }

    /// Use Live Screenshots: App Store Connect's sets as an import.
    func useLiveScreenshots() {
        let scan = CaptureLiveCandidates.scan(screenshots.live)
        guard !scan.candidates.isEmpty else {
            errorMessage = String(localized: "There are no iPhone 6.9″ or iPad 13″ screenshots live in App Store Connect for this version.")
            return
        }
        present(scan)
    }

    /// Matches a scan against the template and shows the matching step.
    func present(_ scan: CaptureScan) {
        let matcher = CaptureMatcher(slotCount: document?.template?.slots.count)
        session = CaptureImportSession(source: scan.source, location: scan.location, rows: matcher.rows(for: scan.candidates))
        errorMessage = nil
        showsAllMatched = false
        screenshots.tab = .captures
    }

    // MARK: - The matching step

    func choose(_ choice: CaptureChoice, forRow id: CaptureMatchRow.ID) {
        session?.choose(choice, forRow: id)
    }

    /// The rows shown: every row that needs you and the first matched
    /// ones, in path order, until "+ n more matched files" shows the rest.
    var visibleRows: [CaptureMatchRow] {
        guard let session else { return [] }
        guard !showsAllMatched else { return session.rows }
        var matched = 0
        return session.rows.filter { row in
            guard !row.needsYou else { return true }
            matched += 1
            return matched <= Self.matchedPreviewCount
        }
    }

    /// "+ 45 more matched files".
    var moreMatchedText: String? {
        guard let session, !showsAllMatched else { return nil }
        let hidden = session.rows.filter { !$0.needsYou }.count - Self.matchedPreviewCount
        guard hidden > 0 else { return nil }
        return hidden == 1 ? String(localized: "+ 1 more matched file") : String(localized: "+ \(hidden) more matched files")
    }

    func cancel() {
        session = nil
        stopAccessing()
    }

    /// Import n Captures: copies the files, adds them to the index, names
    /// the slots, grows the template for "Add slot 6", and the first time
    /// sets the scope to the captured locales.
    func importCaptures(date: Date = .now) async {
        guard let session, var document = screenshots.document, !session.items.isEmpty else { return }
        isImporting = true
        defer { isImporting = false }
        let isFirstImport = document.captures.isEmpty
        let captures: [ScreenshotCapture]
        do {
            captures = try await screenshots.services.importCaptures(session.items, for: screenshots.app)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        captures.forEach { document.captures.add($0) }
        Self.nameSlots(in: &document, from: session.items)
        if let needed = session.slotsNeeded { Self.addSlots(upTo: needed, in: &document, date: date) }
        let locales = Set(captures.map(\.locale))
        if isFirstImport { document.scope.setLocalized(locales) }
        self.session = nil
        stopAccessing()
        await screenshots.commit(document)
        screenshots.notice = notice(captureCount: captures.count, localeCount: locales.count, isFirstImport: isFirstImport, document: document)
        if isFirstImport { screenshots.tab = .sets }
    }

    // MARK: - Coverage

    var coverage: CaptureCoverage? {
        guard let document, !document.captures.isEmpty else { return nil }
        return CaptureCoverage.make(CaptureCoverage.Inputs(
            document: document, displayType: screenshots.displayType, primary: screenshots.context.primaryLocale, locales: screenshots.locales
        ))
    }

    // MARK: - Helpers

    /// "52 captures imported for 10 locales. The other 29 locales will show
    /// English (U.S.) screenshots unless you add them."
    private func notice(captureCount: Int, localeCount: Int, isFirstImport: Bool, document: ScreenshotsDocument) -> String {
        let captures = captureCount == 1 ? String(localized: "1 capture") : String(localized: "\(captureCount) captures")
        let imported = localeCount == 1
            ? String(localized: "\(captures) imported for 1 locale.")
            : String(localized: "\(captures) imported for \(localeCount) locales.")
        let others = screenshots.locales.count - document.scope.count
        guard isFirstImport, others > 0 else { return imported }
        let primary = screenshots.context.primaryLocale.name
        return imported + " " + String(localized: "The other \(others) locales will show \(primary) screenshots unless you add them.")
    }

    /// Slots without a name take the first name a file gives them.
    static func nameSlots(in document: inout ScreenshotsDocument, from items: [CaptureImportItem]) {
        for item in items.sorted(by: { $0.placement.slot < $1.placement.slot }) {
            guard let name = item.candidate.slotName else { continue }
            let slot = item.placement.slot
            while document.slotNames.count <= slot { document.slotNames.append("") }
            if document.slotNames[slot].isEmpty { document.slotNames[slot] = name }
        }
        if document.slotNames.allSatisfy(\.isEmpty) { document.slotNames = [] }
        document.slotNames = document.slotNames.enumerated().map { $0.element.isEmpty ? String(localized: "Slot \($0.offset + 1)") : $0.element }
    }

    /// "Add slot 6 to the template": a new version with slots up to
    /// `count`, each like the template's last.
    static func addSlots(upTo count: Int, in document: inout ScreenshotsDocument, date: Date) {
        guard var history = document.history, var template = history.currentTemplate, template.slots.count < count else { return }
        let added = min(count, ScreenshotTemplate.maximumSlots) - template.slots.count
        guard added > 0 else { return }
        template.slots += Array(repeating: TemplateSlot(), count: added)
        let note = added == 1
            ? String(localized: "Added slot \(template.slots.count) for imported captures")
            : String(localized: "Added slots up to \(template.slots.count) for imported captures")
        _ = history.save(template, date: date, note: note)
        document.history = history
    }

    private func stopAccessing() {
        scopedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        scopedURLs = []
    }
}
