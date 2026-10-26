//
//  ListingTransfer.swift
//  AppLocalizer
//

import Foundation

/// Import & Export: writes a listing's current text (every locale, app and
/// version fields) for translators, and reads their files back. Comparing a
/// file with the listing is `ListingImportPreview`.
enum ListingTransfer {
    static func export(_ listing: StoreListing, as format: ListingTransferFormat) -> Data {
        switch format {
        case .csv: Data(ListingCSVCoder.encode(listing).utf8)
        case .xliff: Data(ListingXLIFFCoder.encode(listing).utf8)
        case .json: ListingJSONCoder.encode(listing)
        }
    }

    static func read(_ data: Data, as format: ListingTransferFormat) throws -> ListingTransferDocument {
        switch format {
        case .csv:
            guard let text = String(data: data, encoding: .utf8) else { throw ListingTransferError.notText }
            return try ListingCSVCoder.decode(text)
        case .xliff:
            return try ListingXLIFFCoder.decode(data)
        case .json:
            return try ListingJSONCoder.decode(data)
        }
    }

    /// Reads a file, picking the format from its name's extension.
    static func read(_ data: Data, fileName: String) throws -> ListingTransferDocument {
        let fileExtension = (fileName as NSString).pathExtension
        guard let format = ListingTransferFormat(fileExtension: fileExtension) else {
            throw ListingTransferError.unsupportedFileType(fileExtension)
        }
        return try read(data, as: format)
    }

    /// E.g. "Lumen-Journal-1.4.xliff".
    static func suggestedFileName(for listing: StoreListing, as format: ListingTransferFormat) -> String {
        let name = listing.appName.split(whereSeparator: { $0.isWhitespace || $0 == "/" || $0 == ":" }).joined(separator: "-")
        return "\(name)-\(listing.version.versionString).\(format.fileExtension)"
    }
}
