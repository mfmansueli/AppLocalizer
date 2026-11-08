//
//  RetentionImageFiles.swift
//  AppLocalizer
//

import Foundation

/// Where retention images an assistant made wait until the push uploads
/// them to the Asset Library: in AppLocalizer's own container, which the
/// sandbox always lets it read.
enum RetentionImageFiles {
    static let directory = URL.applicationSupportDirectory.appending(path: "AppLocalizer/Retention", directoryHint: .isDirectory)

    /// Writes the PNG as `<name>-<short id>.png` in the app's folder.
    static func save(_ data: Data, name: String, appID: StoreApp.ID, in directory: URL = directory) throws -> URL {
        let folder = directory.appending(path: appID, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let suffix = UUID().uuidString.prefix(8).lowercased()
        let url = folder.appending(path: "\(slug(name))-\(suffix).png")
        try data.write(to: url, options: .atomic)
        return url
    }

    /// "Moonrise over pages!" → "moonrise-over-pages".
    static func slug(_ name: String) -> String {
        let folded = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX")).lowercased()
        let words = folded.split { !$0.isLetter && !$0.isNumber }.filter { $0.allSatisfy(\.isASCII) }
        let slug = words.joined(separator: "-")
        return slug.isEmpty ? "retention-image" : String(slug.prefix(48))
    }
}
