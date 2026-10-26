//
//  CustomIndexPreview.swift
//  AppLocalizer
//

import Foundation

/// A CSV picked for the custom index, parsed but not imported yet, so the
/// sheet can show what matched and what didn't.
struct CustomIndexPreview: Identifiable, Hashable, Sendable {
    var fileName: String
    var lineCount: Int
    var result: CustomIndexImport

    var id: String { fileName }

    /// Rows the preview table lists before “+ n more matched rows”.
    static let visibleRowCount = 8
}
