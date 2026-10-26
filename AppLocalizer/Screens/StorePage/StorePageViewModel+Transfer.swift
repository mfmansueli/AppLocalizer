//
//  StorePageViewModel+Transfer.swift
//  AppLocalizer
//

import Foundation

// Find and Replace, Import with a diff, and Export.
extension StorePageViewModel {
    // MARK: - Find and Replace

    func presentFindReplace() {
        sheet = .findReplace
    }

    /// Every field the search text is in, with what it would become.
    var findMatches: [FindReplaceMatch] {
        listing?.matches(for: findQuery) ?? []
    }

    /// "Replace All": every match becomes your edit and a pending change.
    /// Returns how many fields changed.
    @discardableResult
    func replaceAll() -> Int {
        guard var listing else { return 0 }
        let count = listing.replace(findMatches)
        commit(listing)
        sheet = nil
        notice = count == 1 ? String(localized: "Replaced in 1 field.") : String(localized: "Replaced in \(count) fields.")
        return count
    }

    // MARK: - Import

    /// Reads a translator's file and shows what it would change. Files from
    /// the open panel are security-scoped.
    func importFile(at url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            showImport(data, fileName: url.lastPathComponent)
        } catch {
            importPreview = nil
            importError = error.localizedDescription
            sheet = .importPreview
        }
    }

    /// Builds the diff for a file's contents, or says why it can't be read.
    func showImport(_ data: Data, fileName: String) {
        guard let listing else { return }
        do {
            let document = try ListingTransfer.read(data, fileName: fileName)
            importPreview = listing.importPreview(for: document, fileName: fileName)
            importError = nil
        } catch {
            importPreview = nil
            importError = error.localizedDescription
        }
        sheet = .importPreview
    }

    func toggleImportChange(_ id: ListingFieldKey) {
        importPreview?.toggle(id)
    }

    /// "Apply n Changes": the selected rows become your edits.
    func applyImport() {
        guard var listing, let preview = importPreview else { return }
        let count = listing.apply(preview)
        commit(listing)
        importPreview = nil
        sheet = nil
        notice = count == 1 ? String(localized: "Imported 1 change.") : String(localized: "Imported \(count) changes.")
    }

    /// "Choose Another File…" and Cancel.
    func dismissImport(choosingAnother: Bool = false) {
        importPreview = nil
        sheet = nil
        if choosingAnother { isImporterPresented = true }
    }

    // MARK: - Export

    /// The current texts (pending edits included) as a file for translators.
    func exportDocument(as format: ListingTransferFormat) -> ListingExportDocument? {
        guard let listing else { return nil }
        return ListingExportDocument(data: ListingTransfer.export(listing, as: format), format: format)
    }

    func exportFileName(as format: ListingTransferFormat) -> String {
        guard let listing else { return "Store Page.\(format.fileExtension)" }
        return ListingTransfer.suggestedFileName(for: listing, as: format)
    }

    /// The save panel closed: says where the file went, or why it didn't.
    func exportDidFinish(_ result: Result<URL, any Error>) {
        exportFormat = nil
        switch result {
        case let .success(url):
            notice = String(localized: "Exported \(url.lastPathComponent).")
        case let .failure(error):
            if (error as? CocoaError)?.code == .userCancelled { return }
            notice = error.localizedDescription
        }
    }
}
