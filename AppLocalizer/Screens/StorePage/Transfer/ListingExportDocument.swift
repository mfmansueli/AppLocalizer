//
//  ListingExportDocument.swift
//  AppLocalizer
//

import SwiftUI
import UniformTypeIdentifiers

/// A file for translators, for `.fileExporter`: the listing as CSV, XLIFF
/// or JSON.
struct ListingExportDocument: FileDocument {
    static let readableContentTypes: [UTType] = ListingTransferFormat.allCases.map(\.contentType)

    let data: Data
    let format: ListingTransferFormat

    init(data: Data, format: ListingTransferFormat) {
        self.data = data
        self.format = format
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
        format = ListingTransferFormat.allCases.first { $0.contentType == configuration.contentType } ?? .csv
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
