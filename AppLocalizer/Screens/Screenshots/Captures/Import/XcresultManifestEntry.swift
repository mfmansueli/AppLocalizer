//
//  XcresultManifestEntry.swift
//  AppLocalizer
//

import Foundation

/// One test in the `manifest.json` that `xcresulttool export attachments`
/// writes, read leniently: only what matching needs, each field optional.
struct XcresultManifestEntry: Decodable, Hashable, Sendable {
    var testIdentifier: String?
    var attachments: [Attachment]

    struct Attachment: Decodable, Hashable, Sendable {
        /// The file in the export folder.
        var exportedFileName: String
        /// "01_Today_0_9F2C….png", as the test named it.
        var suggestedHumanReadableName: String?
        /// "iPhone 17 Pro Max".
        var deviceName: String?
        /// The test plan configuration, e.g. "German" or "de-DE".
        var configurationName: String?
    }

    enum CodingKeys: String, CodingKey {
        case testIdentifier
        case attachments
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        testIdentifier = try? container.decodeIfPresent(String.self, forKey: .testIdentifier)
        attachments = (try? container.decodeIfPresent([Attachment].self, forKey: .attachments)) ?? []
    }

    /// The manifest's entries; none when it isn't one.
    static func entries(in data: Data) -> [XcresultManifestEntry] {
        (try? JSONDecoder().decode([XcresultManifestEntry].self, from: data)) ?? []
    }
}
