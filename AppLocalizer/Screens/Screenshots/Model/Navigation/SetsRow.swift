//
//  SetsRow.swift
//  AppLocalizer
//

import Foundation

/// One locale's row in the Sets matrix on one display type.
struct SetsRow: Identifiable, Hashable, Sendable {
    var locale: StoreLocale
    var isPrimary: Bool
    var summary: ScreenshotRowSummary
    var cells: [ScreenshotCell]
    /// The locale's live App Previews, read-only.
    var previews: LiveAppPreviewSet?

    var id: String { locale.code }
}
