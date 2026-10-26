//
//  PrivateKeyFileReader.swift
//  AppLocalizer
//

import Foundation

/// Reads a `.p8` the person picked in the file importer or dropped on the
/// window. In the sandbox those URLs are security-scoped
/// (`ENABLE_USER_SELECTED_FILES = readonly`), so access is opened around the
/// read.
enum PrivateKeyFileReader {
    static func read(_ url: URL) throws -> ImportedPrivateKey {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isScoped { url.stopAccessingSecurityScopedResource() }
        }
        let pem = try String(contentsOf: url, encoding: .utf8)
        return ImportedPrivateKey(fileName: url.lastPathComponent, pem: pem)
    }
}
