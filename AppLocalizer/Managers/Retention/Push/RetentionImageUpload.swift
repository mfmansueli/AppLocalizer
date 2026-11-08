//
//  RetentionImageUpload.swift
//  AppLocalizer
//

import Foundation

/// An image on this Mac (one Claude Design made) that a retention
/// message's placement shows: `{retentionImageUpload:<appID>:<path>}`. The
/// push reserves it in the app's Asset Library, uploads its parts, commits
/// it and waits for Apple to process it, then places its ID.
struct RetentionImageUpload: Hashable, Sendable {
    var token: String
    var appID: StoreApp.ID
    var path: String

    /// The asset category retention images are reserved under when the
    /// reference data doesn't name one. Untested against Apple.
    static let category = "CREATIVE_ASSETS"
    static let pollInterval: Duration = .seconds(2)
    static let processingTimeout: Duration = .seconds(180)

    init?(in request: PushRequest) {
        guard let found = RetentionPushSteps.token(RetentionPushSteps.uploadPrefix, in: request),
              let separator = found.value.firstIndex(of: ":"),
              let path = found.value[found.value.index(after: separator)...].removingPercentEncoding
        else { return nil }
        token = found.token
        appID = String(found.value[..<separator])
        self.path = path
    }

    var fileName: String { URL(fileURLWithPath: path).lastPathComponent }

    /// "Retention · lake-3840x1000 · 7Q2K": Apple takes each reference
    /// name once.
    func referenceName(suffix: String) -> String {
        "Retention · \(URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent) · \(suffix)"
    }

    /// Uploads the file and returns the image's asset ID once Apple has
    /// processed it.
    @MainActor
    func send(
        via transport: any PushTransport,
        category: String = Self.category,
        readFile: (String) throws -> Data = { try Data(contentsOf: URL(fileURLWithPath: $0)) },
        sleep: (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
        suffix: String = String(UUID().uuidString.prefix(4))
    ) async throws -> String {
        guard let library = transport as? any AssetLibraryPushing else { throw RetentionPushError.cannotUpload }
        let data: Data
        do {
            data = try readFile(path)
        } catch {
            throw RetentionPushError.imageMissing(fileName: fileName)
        }
        let libraryID = try await library.assetLibraryID(appID: appID)
        let reservation = try await library.reserveAssetLibraryImage(
            libraryID: libraryID, fileName: fileName, fileSize: data.count, category: category, referenceName: referenceName(suffix: suffix)
        )
        for operation in reservation.uploadOperations {
            try await library.upload(operation, data: data) { _ in }
        }
        try await library.commitAssetLibraryAsset(reservation.asset)
        var waited: Duration = .zero
        while true {
            let status = try await library.assetLibraryAssetState(reservation.asset)
            if status.isReady { return reservation.asset.id }
            if status.isFailed { throw RetentionPushError.imageRefused(state: status.state ?? "FAILED", details: status.detailText) }
            guard waited < Self.processingTimeout else { throw RetentionPushError.imageTimedOut }
            try await sleep(Self.pollInterval)
            waited += Self.pollInterval
        }
    }
}
