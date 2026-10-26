//
//  ImportedPrivateKey.swift
//  AppLocalizer
//

import Foundation

/// A `.p8` file picked or dropped on the connect screen.
struct ImportedPrivateKey: Equatable, Sendable {
    /// Shown on the drop zone, e.g. `AuthKey_2X9R4HXF34.p8`.
    var fileName: String
    var pem: String
}
