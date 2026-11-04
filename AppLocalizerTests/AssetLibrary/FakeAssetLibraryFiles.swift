//
//  FakeAssetLibraryFiles.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
@testable import AppLocalizer

/// An asset library in memory for the sheet's model: files with how many
/// pages show each, refusing to delete a placed one like Apple, and
/// logging each delete.
final class FakeAssetLibraryFiles: AssetLibraryManaging {
    /// One file to start with: its ID, kind, reference name and how many
    /// pages show it.
    struct Seed {
        var id: String
        var media: AssetLibraryMedia
        var name: String
        var placements: Int
    }

    private struct State {
        var files: [AssetLibraryFile]
        var placements: [String: Int]
        var deleted: [String] = []
    }

    private let state: Mutex<State>
    /// Checking these files' placements fails.
    private let uncheckable: Set<String>

    init(_ files: [Seed], uncheckable: Set<String> = []) {
        let made = files.map { file in
            AssetLibraryFile(
                id: file.id, media: file.media, referenceName: file.name, fileName: "\(file.id).png", fileSize: 1000, state: "PREPARE_FOR_SUBMISSION",
                createdDate: nil, thumbnailTemplate: nil, pixelSize: nil
            )
        }
        state = Mutex(State(files: made, placements: Dictionary(uniqueKeysWithValues: files.map { ($0.id, $0.placements) })))
        self.uncheckable = uncheckable
    }

    var deleted: [String] { state.withLock { $0.deleted } }

    func assetLibraryFiles(appID _: StoreApp.ID) async throws -> [AssetLibraryFile] {
        state.withLock { $0.files }
    }

    func assetLibraryPlacementCount(_ asset: AssetLibraryAsset) async throws -> Int {
        if uncheckable.contains(asset.id) { throw URLError(.timedOut) }
        return state.withLock { $0.placements[asset.id] ?? 0 }
    }

    func deleteAssetLibraryAsset(_ asset: AssetLibraryAsset) async throws {
        let placed = state.withLock { $0.placements[asset.id] ?? 0 }
        if placed > 0 {
            throw AppStoreConnectError.rejected(statusCode: 409, code: "STATE_ERROR.ASSET_HAS_PLACEMENTS", detail: "Delete those placements first")
        }
        state.withLock { state in
            state.files.removeAll { $0.id == asset.id }
            state.deleted.append(asset.id)
        }
    }
}
