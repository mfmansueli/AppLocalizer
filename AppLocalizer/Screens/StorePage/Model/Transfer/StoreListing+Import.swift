//
//  StoreListing+Import.swift
//  AppLocalizer
//

import Foundation

extension StoreListing {
    /// Compares an imported file with the current values.
    func importPreview(for document: ListingTransferDocument, fileName: String? = nil) -> ListingImportPreview {
        ListingImportPreview(document: document, listing: self, fileName: fileName)
    }

    /// "Apply n Changes": the selected changes become your edits, adding
    /// locales the file brought in. Returns how many were applied.
    @discardableResult
    mutating func apply(_ preview: ListingImportPreview) -> Int {
        var count = 0
        for change in preview.selectedChanges where canEdit(change.key.field) {
            edit(change.key.field, in: change.key.locale, to: change.newValue)
            count += 1
        }
        return count
    }
}
