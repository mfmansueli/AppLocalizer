//
//  AppScreenshotAttributes.swift
//  AppLocalizer
//

import Foundation

/// An `appScreenshots` resource's attributes, as far as the Sets matrix
/// needs them.
struct AppScreenshotAttributes: Decodable, Sendable {
    var fileName: String?
    var fileSize: Int?
    /// MD5 of the uploaded file.
    var sourceFileChecksum: String?
    var imageAsset: ImageAsset?

    /// The processed image: a URL template and its pixel size.
    struct ImageAsset: Decodable, Sendable {
        var templateUrl: String?
        var width: Int?
        var height: Int?
    }
}
