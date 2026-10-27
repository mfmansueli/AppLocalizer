//
//  AppPreviewSetAttributes.swift
//  AppLocalizer
//

import Foundation

/// An `appPreviewSets` resource's attributes.
struct AppPreviewSetAttributes: Decodable, Sendable {
    /// E.g. `IPHONE_67` or `IPAD_PRO_3GEN_129`.
    var previewType: String
}
