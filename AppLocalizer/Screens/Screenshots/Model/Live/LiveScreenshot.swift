//
//  LiveScreenshot.swift
//  AppLocalizer
//

import Foundation

/// One screenshot in a live set in App Store Connect.
struct LiveScreenshot: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var fileName: String
    /// `sourceFileChecksum`: the MD5 of the uploaded file. AppLocalizer
    /// matches it against what it pushed to know a cell is live.
    var checksum: String?
    var pixelSize: PixelSize?
    /// The image URL with `{w}`, `{h}` and `{f}` placeholders.
    var imageURLTemplate: String?

    /// The image at `width` pixels wide as PNG, when App Store Connect
    /// gave a URL template.
    func imageURL(width: Int) -> URL? {
        guard let imageURLTemplate, let pixelSize, pixelSize.width > 0 else { return nil }
        let height = Int((Double(width) * Double(pixelSize.height) / Double(pixelSize.width)).rounded())
        let text = imageURLTemplate
            .replacingOccurrences(of: "{w}", with: "\(width)")
            .replacingOccurrences(of: "{h}", with: "\(height)")
            .replacingOccurrences(of: "{f}", with: "png")
        return URL(string: text)
    }
}
