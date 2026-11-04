//
//  AssetLibraryFileAttributes.swift
//  AppLocalizer
//

import Foundation

/// What the library listing (`GET /v1/appAssetLibraries/{id}/images` or
/// `…/videos`) says about each file, read leniently: each state has its
/// own attribute shape, so a field that doesn't decode is left out.
struct AssetLibraryFileAttributes: Decodable, Sendable {
    /// `imageAsset`, or a video's `previewFrameImage.image`.
    struct Image: Decodable, Sendable {
        var templateUrl: String?
        var width: Int?
        var height: Int?
    }

    private struct PreviewFrame: Decodable, Sendable {
        var image: Image?
    }

    var fileName: String?
    var referenceName: String?
    var fileSize: Int?
    var state: String?
    var createdDate: Date?
    var image: Image?

    private enum CodingKeys: String, CodingKey {
        case fileName, referenceName, fileSize, state, createdDate, imageAsset, previewFrameImage
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fileName = try? container.decodeIfPresent(String.self, forKey: .fileName)
        referenceName = try? container.decodeIfPresent(String.self, forKey: .referenceName)
        fileSize = try? container.decodeIfPresent(Int.self, forKey: .fileSize)
        state = try? container.decodeIfPresent(String.self, forKey: .state)
        createdDate = (try? container.decodeIfPresent(String.self, forKey: .createdDate)).flatMap { $0.flatMap(Self.date) }
        image = (try? container.decodeIfPresent(Image.self, forKey: .imageAsset))
            ?? (try? container.decodeIfPresent(PreviewFrame.self, forKey: .previewFrameImage))?.image
    }

    /// Apple's dates come with and without fractional seconds.
    private static func date(_ text: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }
}
