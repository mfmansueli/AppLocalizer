//
//  UTType+PrivateKey.swift
//  AppLocalizer
//

import UniformTypeIdentifiers

extension UTType {
    /// `.p8` has no system-declared type, so this is the dynamic type macOS
    /// derives from the extension: it lets the file importer pick exactly
    /// App Store Connect's `AuthKey_….p8` files.
    static let appStoreConnectPrivateKey = UTType(filenameExtension: "p8", conformingTo: .data) ?? .data
}
