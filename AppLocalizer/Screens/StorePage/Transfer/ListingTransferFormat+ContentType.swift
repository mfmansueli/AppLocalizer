//
//  ListingTransferFormat+ContentType.swift
//  AppLocalizer
//

import UniformTypeIdentifiers

extension ListingTransferFormat {
    /// The file type for the open and save panels.
    var contentType: UTType {
        switch self {
        case .csv: .commaSeparatedText
        case .xliff: UTType(filenameExtension: "xliff", conformingTo: .xml) ?? .xml
        case .json: .json
        }
    }

    /// Everything Import Translations accepts.
    static var importableContentTypes: [UTType] {
        allCases.map(\.contentType) + [UTType(filenameExtension: "xlf", conformingTo: .xml) ?? .xml]
    }
}
