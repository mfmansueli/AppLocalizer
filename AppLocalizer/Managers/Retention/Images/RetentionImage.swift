//
//  RetentionImage.swift
//  AppLocalizer
//

import Foundation

/// The image a "With image" message shows: one already in the app's App
/// Asset Library (`assetID`), or a PNG Claude Design made on this Mac
/// (`localPath`), which the push uploads to the library first.
struct RetentionImage: Identifiable, Hashable, Codable, Sendable {
    /// The `appAssetLibraryImages` ID; nil until a local file is uploaded.
    var assetID: String?
    /// "Still Lake".
    var name: String
    var fileName: String?
    var pixelWidth: Int
    var pixelHeight: Int
    /// Where it came from, e.g. "from the header scenes".
    var note: String?
    /// Apple's thumbnail URL with `{w}`, `{h}` and `{f}`, or `sample:<name>`
    /// for the sample data's drawn artwork.
    var thumbnailTemplate: String?
    /// A PNG on this Mac that isn't in the library yet.
    var localPath: String?
    /// Whether the PNG has an alpha channel; nil when AppLocalizer can't
    /// tell (a library file is checked by Apple when it's placed).
    var hasAlpha: Bool?
    /// Whether the file is a PNG; nil when unknown.
    var isPNG: Bool?

    var id: String { assetID ?? localPath ?? name }

    /// "3840 × 1000".
    var sizeText: String {
        "\(pixelWidth) × \(pixelHeight)"
    }

    /// What's wrong with it for a retention message, by Apple's rules.
    var problems: [RetentionImageProblem] {
        RetentionImageRule.problems(width: pixelWidth, height: pixelHeight, isPNG: isPNG, hasAlpha: hasAlpha)
    }

    var fits: Bool { problems.isEmpty }

    /// "3840 × 1000 · from the header scenes".
    var detail: String {
        [sizeText, note].compactMap(\.self).joined(separator: " · ")
    }

    /// The thumbnail at `width` points (doubled for Retina), or nil for a
    /// local or sample image.
    func thumbnailURL(width: CGFloat) -> URL? {
        guard let thumbnailTemplate, !thumbnailTemplate.hasPrefix(Self.samplePrefix) else { return nil }
        let pixels = Int(width * 2)
        let height = Int((Double(pixels) * Double(pixelHeight) / Double(max(1, pixelWidth))).rounded())
        let filled = thumbnailTemplate
            .replacingOccurrences(of: "{w}", with: "\(pixels)")
            .replacingOccurrences(of: "{h}", with: "\(height)")
            .replacingOccurrences(of: "{f}", with: "png")
        return URL(string: filled)
    }

    /// The sample artwork's name, for `sample:<name>` thumbnails.
    var sampleArtwork: String? {
        guard let thumbnailTemplate, thumbnailTemplate.hasPrefix(Self.samplePrefix) else { return nil }
        return String(thumbnailTemplate.dropFirst(Self.samplePrefix.count))
    }

    static let samplePrefix = "sample:"
}

extension RetentionImage {
    /// A library file as a candidate image; nil for a video or a file whose
    /// size Apple didn't report.
    init?(_ file: AssetLibraryFile) {
        guard file.media == .image, let size = file.pixelSize else { return nil }
        let name = file.referenceName.flatMap { $0.isEmpty ? nil : $0 } ?? file.fileName ?? file.id
        self.init(
            assetID: file.id,
            name: name,
            fileName: file.fileName,
            pixelWidth: size.width,
            pixelHeight: size.height,
            thumbnailTemplate: file.thumbnailTemplate,
            isPNG: file.fileName.map { $0.lowercased().hasSuffix(".png") }
        )
    }
}
