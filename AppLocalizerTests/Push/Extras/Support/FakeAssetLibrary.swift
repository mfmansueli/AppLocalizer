//
//  FakeAssetLibrary.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
@testable import AppLocalizer

/// Answers the App Asset Library calls like App Store Connect would and
/// logs each one in order (`ref-data`, `library app-1`,
/// `reserve image de-DE-header.png 25 CREATIVE_ASSETS`, `upload image-1 1`,
/// `commit image-1`, `state image-1`, `list loc-de APP_PREVIEW IPHONE…`,
/// `delete p-old`, `place image-1 PRODUCT_PAGE_HEADER_ASSET … loc-de`,
/// `order IPHONE… p-2,p-a`). Like Apple, it refuses a placement past its
/// group's limit and a reference name that's already in use. Files named by the start of their file name can fail
/// once. Nothing reaches the network.
final class FakeAssetLibrary: AssetLibraryPushing {
    struct Script: Sendable {
        var refData = AssetLibraryRefDataSample.refData
        /// State checks that answer `UPLOAD_COMPLETE` before an asset is
        /// ready.
        var processingPolls = 1
        /// Apple fails processing once, with this detail.
        var processingFailures: [String: AssetLibraryStateDetail] = [:]
        /// Never done processing until `finishProcessing(_:)`.
        var stuck: Set<String> = []
        /// Still processing until the file named by the value is reserved,
        /// e.g. `["de-DE-header": "de-DE-preview"]`: only a push that
        /// uploads the next file meanwhile gets it placed.
        var processingUntilReserved: [String: String] = [:]
        /// Creating a placement for this file is refused once with
        /// `STATE_ERROR.INVALID_STATE`.
        var refusedPlacements: Set<String> = []
        /// Reserving finds the Mac offline.
        var offline: Set<String> = []
        /// The first call gets a 429.
        var rateLimitedOnce = false
    }

    private struct State {
        var log: [String] = []
        var nextID = 1
        var fileNames: [String: String] = [:]
        var uploaded: [String: Data] = [:]
        var polls: [String: Int] = [:]
        var placements: [String: [AssetLibraryPlacement]] = [:]
        var spent: Set<String> = []
        var stuck: Set<String>
        var referenceNames: [String] = []
    }

    private let script: Script
    private let state: Mutex<State>
    /// Runs while the first reservation is made, e.g. to cancel the run.
    private let onReserve: @Sendable () async -> Void

    /// `placements` are what each localization shows already, by its ID.
    init(_ script: Script = Script(), placements: [String: [AssetLibraryPlacement]] = [:], onReserve: @escaping @Sendable () async -> Void = {}) {
        self.script = script
        self.onReserve = onReserve
        state = Mutex(State(placements: placements, stuck: script.stuck))
    }

    var log: [String] { state.withLock { $0.log } }

    /// Every reference name an asset was reserved under, in order.
    var referenceNames: [String] { state.withLock { $0.referenceNames } }

    /// What a localization shows now, in order.
    func placements(on localizationID: String) -> [AssetLibraryPlacement] {
        state.withLock { $0.placements[localizationID] ?? [] }
    }

    /// The bytes uploaded for an asset, parts joined.
    func uploaded(_ id: String) -> Data? {
        state.withLock { $0.uploaded[id] }
    }

    func finishProcessing(_ name: String) {
        _ = state.withLock { $0.stuck.remove(name) }
    }

    // MARK: - AssetLibraryPushing

    func assetLibraryID(appID: StoreApp.ID) async throws -> String {
        try limitOnce()
        log("library \(appID)")
        return "lib-\(appID)"
    }

    func assetLibraryRefData() async throws -> AssetLibraryRefData {
        try limitOnce()
        log("ref-data")
        return script.refData
    }

    func reserveAssetLibraryImage(
        libraryID _: String, fileName: String, fileSize: Int, category: String, referenceName: String
    ) async throws -> AssetLibraryAssetReservation {
        try await reserve(.image, fileName: fileName, fileSize: fileSize, referenceName: referenceName, entry: "\(fileName) \(fileSize) \(category)")
    }

    func reserveAssetLibraryVideo(
        libraryID _: String, fileName: String, fileSize: Int, category: String, referenceName: String, previewFrameTimeCode: String?
    ) async throws -> AssetLibraryAssetReservation {
        try await reserve(
            .video, fileName: fileName, fileSize: fileSize, referenceName: referenceName,
            entry: "\(fileName) \(fileSize) \(category) poster \(previewFrameTimeCode ?? "-")"
        )
    }

    func upload(_ operation: ScreenshotUploadOperation, data: Data, progress: @escaping @Sendable (Int64) -> Void) async throws {
        let parts = operation.url.components(separatedBy: "/")
        let id = parts.dropLast().last ?? ""
        log("upload \(id) \(parts.last ?? "")")
        state.withLock { $0.uploaded[id, default: Data()].append(operation.slice(of: data)) }
        progress(Int64(operation.length))
    }

    func commitAssetLibraryAsset(_ asset: AssetLibraryAsset) async throws {
        try limitOnce()
        log("commit \(asset.id)")
    }

    func assetLibraryAssetState(_ asset: AssetLibraryAsset) async throws -> AssetLibraryAssetStatus {
        try limitOnce()
        log("state \(asset.id)")
        let (fileName, polls, stuck) = state.withLock { state in
            state.polls[asset.id, default: 0] += 1
            let fileName = state.fileNames[asset.id] ?? ""
            let waitsFor = Self.matching(fileName, Set(script.processingUntilReserved.keys)).flatMap { script.processingUntilReserved[$0] }
            let waiting = waitsFor.map { other in !state.fileNames.values.contains { $0.hasPrefix(other) } } ?? false
            return (fileName, state.polls[asset.id] ?? 0, waiting || Self.matching(fileName, state.stuck) != nil)
        }
        if let name = Self.matching(fileName, Set(script.processingFailures.keys)), let detail = script.processingFailures[name], spend("process|\(name)") {
            return AssetLibraryAssetStatus(state: "FAILED", details: [detail])
        }
        if stuck || polls <= script.processingPolls { return AssetLibraryAssetStatus(state: "UPLOAD_COMPLETE") }
        return AssetLibraryAssetStatus(state: "PREPARE_FOR_SUBMISSION")
    }

    func assetLibraryPlacements(localizationID: String, placementType: String, placementGroup: String?) async throws -> [AssetLibraryPlacement] {
        try limitOnce()
        log("list \(localizationID) \(placementType) \(placementGroup ?? "-")")
        return placements(on: localizationID).filter {
            $0.placementType == placementType && (placementGroup == nil || $0.placementGroup == placementGroup)
        }
    }

    func deleteAssetLibraryPlacement(id: String) async throws {
        try limitOnce()
        log("delete \(id)")
        state.withLock { state in
            for key in state.placements.keys { state.placements[key]?.removeAll { $0.id == id } }
        }
    }

    func createAssetLibraryPlacement(
        placementType: String, placementGroup: String, asset: AssetLibraryAsset, localizationID: String
    ) async throws -> AssetLibraryPlacement {
        try limitOnce()
        log("place \(asset.id) \(placementType) \(placementGroup) \(localizationID)")
        let fileName = state.withLock { $0.fileNames[asset.id] } ?? ""
        if let name = Self.matching(fileName, script.refusedPlacements), spend("place|\(name)") {
            throw AppStoreConnectError.rejected(statusCode: 409, code: "STATE_ERROR.INVALID_STATE", detail: "The version can’t be edited")
        }
        let count = placements(on: localizationID).count { $0.placementType == placementType && $0.placementGroup == placementGroup }
        if let limit = script.refData.groupLimit(placementType: placementType, placementGroup: placementGroup), count >= limit {
            throw AppStoreConnectError.rejected(statusCode: 409, code: "ENTITY_ERROR.ATTRIBUTE.INVALID", detail: "The group is full")
        }
        return state.withLock { state in
            let placement = AssetLibraryPlacement(
                id: "p-\(state.nextID)", placementType: placementType, placementGroup: placementGroup, state: "PARENT_PREPARE_FOR_SUBMISSION", asset: asset
            )
            state.nextID += 1
            state.placements[localizationID, default: []].append(placement)
            return placement
        }
    }

    func orderAssetLibraryPlacements(_ ids: [String], placementGroup: String, localizationID: String) async throws {
        try limitOnce()
        log("order \(placementGroup) \(ids.joined(separator: ","))")
        state.withLock { state in
            let all = state.placements[localizationID] ?? []
            let ordered = ids.compactMap { id in all.first { $0.id == id } }
            state.placements[localizationID] = ordered + all.filter { !ids.contains($0.id) }
        }
    }

    // MARK: - Helpers

    /// Two parts, split in the middle.
    private func reserve(
        _ media: AssetLibraryMedia, fileName: String, fileSize: Int, referenceName: String, entry: String
    ) async throws -> AssetLibraryAssetReservation {
        try limitOnce()
        log("reserve \(media.rawValue) \(entry)")
        if spend("reserve-hook") { await onReserve() }
        if Self.matching(fileName, script.offline) != nil { throw URLError(.notConnectedToInternet) }
        let taken = state.withLock { state in
            defer { state.referenceNames.append(referenceName) }
            return state.referenceNames.contains(referenceName)
        }
        if taken {
            throw AppStoreConnectError.rejected(
                statusCode: 409, code: "ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE", detail: "Reference name '\(referenceName)' is already in use"
            )
        }
        let id = state.withLock { state in
            let id = "\(media.rawValue)-\(state.nextID)"
            state.nextID += 1
            state.fileNames[id] = fileName
            return id
        }
        let half = fileSize / 2
        let operations = [
            ScreenshotUploadOperation(method: "PUT", url: "test://upload/\(id)/1", offset: 0, length: half),
            ScreenshotUploadOperation(method: "PUT", url: "test://upload/\(id)/2", offset: half, length: fileSize - half),
        ]
        return AssetLibraryAssetReservation(asset: AssetLibraryAsset(id: id, media: media), uploadOperations: operations)
    }

    private func limitOnce() throws {
        if script.rateLimitedOnce, spend("429") {
            log("429")
            throw AppStoreConnectError.rateLimited
        }
    }

    private func log(_ entry: String) {
        state.withLock { $0.log.append(entry) }
    }

    private func spend(_ key: String) -> Bool {
        state.withLock { $0.spent.insert(key).inserted }
    }

    private static func matching(_ fileName: String, _ names: Set<String>) -> String? {
        names.first { fileName.hasPrefix($0) }
    }
}
