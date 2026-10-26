//
//  PrivacyExportDocument.swift
//  AppLocalizer
//

import SwiftUI
import UniformTypeIdentifiers

/// The exported file, for `.fileExporter`.
struct PrivacyExportDocument: FileDocument {
    static let readableContentTypes: [UTType] = PrivacyExportFormat.allCases.map(\.contentType)

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
