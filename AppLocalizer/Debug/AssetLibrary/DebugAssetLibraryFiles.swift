//
//  DebugAssetLibraryFiles.swift
//  AppLocalizer
//

#if DEBUG
import Foundation
import Synchronization

/// An App Asset Library in memory for DEBUG scenes: Autopilot's headers,
/// search images and App Previews, some on a page and some left over from
/// earlier pushes, plus a failed upload and an unfinished one. Deleting a
/// file a page shows is refused like Apple does. Never contacts App Store
/// Connect.
final class DebugAssetLibraryFiles: AssetLibraryManaging {
    private struct Entry: Sendable {
        var file: AssetLibraryFile
        var placements: Int
    }

    private let delay: Duration
    private let entries: Mutex<[Entry]>

    init(delay: Duration = .milliseconds(120)) {
        self.delay = delay
        entries = Mutex(Self.sample())
    }

    func assetLibraryFiles(appID _: StoreApp.ID) async throws -> [AssetLibraryFile] {
        try await Task.sleep(for: delay)
        return entries.withLock { $0.map(\.file) }
    }

    func assetLibraryPlacementCount(_ asset: AssetLibraryAsset) async throws -> Int {
        try await Task.sleep(for: delay)
        return entries.withLock { entries in entries.first { $0.file.id == asset.id }?.placements ?? 0 }
    }

    func deleteAssetLibraryAsset(_ asset: AssetLibraryAsset) async throws {
        try await Task.sleep(for: delay)
        let placed = entries.withLock { entries in entries.first { $0.file.id == asset.id }?.placements ?? 0 }
        if placed > 0 {
            throw AppStoreConnectError.rejected(
                statusCode: 409, code: "STATE_ERROR.ASSET_HAS_PLACEMENTS",
                detail: "The asset cannot be deleted while placements still use it. Delete those placements first"
            )
        }
        entries.withLock { $0.removeAll { $0.file.id == asset.id } }
    }

    private static func sample() -> [Entry] {
        let now = Date(timeIntervalSince1970: 1_793_750_400)
        var entries: [Entry] = []
        for (index, locale) in ["en-US", "en-GB", "de-DE", "fr-FR"].enumerated() {
            let base = now.addingTimeInterval(Double(-index) * 60)
            entries.append(entry("header-\(locale)", .video, "Autopilot · \(locale) · Header 21:9 · motion · 7C1D\(index)A", date: base, placements: 1))
            entries.append(entry("header-old-\(locale)", .video, "Autopilot · \(locale) · Header 21:9 · motion", date: base.addingTimeInterval(-3600)))
            entries.append(entry(
                "search-\(locale)", .image, "Autopilot · \(locale) · Search results 3:2 · B2\(index)F90", date: base.addingTimeInterval(-30), placements: 1
            ))
        }
        entries.append(entry("preview-en-US", .video, "Autopilot · en-US · iPhone App Preview", date: now.addingTimeInterval(-7200), placements: 1))
        entries.append(entry("failed", .image, "Autopilot · it · Search results 3:2", date: now.addingTimeInterval(-9000), state: "FAILED"))
        entries.append(entry("unfinished", .video, "Autopilot · ja · Header 21:9 · motion", date: now.addingTimeInterval(-9600), state: "AWAITING_UPLOAD"))
        return entries
    }

    /// A video is a 4.9 MB `.mov`, an image a 1.2 MB `.png`.
    private static func entry(
        _ id: String, _ media: AssetLibraryMedia, _ name: String, date: Date, placements: Int = 0, state: String = "PREPARE_FOR_SUBMISSION"
    ) -> Entry {
        let isVideo = media == .video
        return Entry(
            file: AssetLibraryFile(
                id: id, media: media, referenceName: name, fileName: "\(id).\(isVideo ? "mov" : "png")", fileSize: isVideo ? 4_900_000 : 1_200_000,
                state: state, createdDate: date, thumbnailTemplate: nil, pixelSize: nil
            ),
            placements: placements
        )
    }
}
#endif
