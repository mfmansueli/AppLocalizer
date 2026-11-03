//
//  ExtrasPushRun+Upload.swift
//  AppLocalizer
//

import Foundation

extension ExtrasPushRun {
    /// The slots `item` goes in: for each of its placement types, every
    /// group whose specs take a file of its size. A type with none fails
    /// the item before anything is uploaded.
    func targets(for item: ExtrasPushItem) async throws -> [ExtrasPushTarget] {
        let refData = try await loadRefData()
        let isVideo = item.kind.media == .video
        var targets: [ExtrasPushTarget] = []
        for placementType in item.kind.placementTypes {
            let groups = refData.placementGroups(for: placementType, pixelSize: item.pixelSize, isVideo: isVideo)
            guard !groups.isEmpty else {
                let accepted = refData.acceptedSizes(for: placementType, isVideo: isVideo)
                throw ExtrasPushFailure.noMatchingGroup(placementType: placementType, pixelSize: item.pixelSize, isVideo: isVideo, accepted: accepted)
            }
            targets += groups.map { ExtrasPushTarget(placementType: placementType, placementGroup: $0) }
        }
        return targets
    }

    /// The item's asset once Apple has processed it: uploaded now, or
    /// kept from an earlier round.
    func processedAsset(for item: ExtrasPushItem) async throws -> AssetLibraryAsset {
        let asset = try await committedAsset(for: item)
        guard !processedItemIDs.contains(item.id) else { return asset }
        statuses[item.id] = .processing
        try await waitUntilProcessed(asset, item: item)
        processedItemIDs.insert(item.id)
        return asset
    }

    /// `bytes` of the item's `total` went out: the percentage moves on
    /// while it's uploading, never back.
    func noteSent(_ id: ExtrasPushItem.ID, bytes: Int, of total: Int) {
        guard case let .uploading(fraction) = statuses[id], total > 0 else { return }
        let sent = min(1, Double(bytes) / Double(total))
        if sent > fraction { statuses[id] = .uploading(sent) }
    }

    // MARK: - Steps

    private func loadRefData() async throws -> AssetLibraryRefData {
        if let refData { return refData }
        let library = environment.library
        let loaded = try await call { try await library.assetLibraryRefData() }
        refData = loaded
        return loaded
    }

    private func libraryID(for appID: StoreApp.ID) async throws -> String {
        if let id = libraryIDs[appID] { return id }
        let library = environment.library
        do {
            let id = try await call { try await library.assetLibraryID(appID: appID) }
            libraryIDs[appID] = id
            return id
        } catch let AppStoreConnectError.notFound(detail) {
            throw ExtrasPushFailure.noLibrary(detail: detail ?? "NOT_FOUND")
        }
    }

    /// Reads the file, reserves it, uploads its parts and commits it.
    private func committedAsset(for item: ExtrasPushItem) async throws -> AssetLibraryAsset {
        if let asset = committedAssets[item.id] { return asset }
        statuses[item.id] = .uploading(0)
        let data: Data
        do {
            data = try await environment.fileData(item.fileURL)
        } catch {
            throw ExtrasPushFailure.file(detail: Self.describe(error))
        }
        let libraryID = try await libraryID(for: item.appID)
        let reservation = try await reserve(item, libraryID: libraryID, fileSize: data.count)
        try await uploadParts(of: item, operations: reservation.uploadOperations, data: data)
        let library = environment.library
        try await call { try await library.commitAssetLibraryAsset(reservation.asset) }
        committedAssets[item.id] = reservation.asset
        return reservation.asset
    }

    private func reserve(_ item: ExtrasPushItem, libraryID: String, fileSize: Int) async throws -> AssetLibraryAssetReservation {
        let library = environment.library
        switch item.kind {
        case .artwork:
            return try await call {
                try await library.reserveAssetLibraryImage(
                    libraryID: libraryID, fileName: item.fileName, fileSize: fileSize, category: item.kind.category, referenceName: item.referenceName
                )
            }
        case .motionArtwork:
            return try await call {
                try await library.reserveAssetLibraryVideo(
                    libraryID: libraryID, fileName: item.fileName, fileSize: fileSize, category: item.kind.category,
                    referenceName: item.referenceName, previewFrameTimeCode: ExtrasPushKind.loopPosterTimeCode
                )
            }
        case let .appPreview(posterTimeCode):
            return try await call {
                try await library.reserveAssetLibraryVideo(
                    libraryID: libraryID, fileName: item.fileName, fileSize: fileSize, category: item.kind.category,
                    referenceName: item.referenceName, previewFrameTimeCode: posterTimeCode
                )
            }
        }
    }

    /// The parts one by one, the percentage moving as their bytes go out.
    /// Offline stops the push; any other failure is the part's.
    private func uploadParts(of item: ExtrasPushItem, operations: [ScreenshotUploadOperation], data: Data) async throws {
        let library = environment.library
        let id = item.id
        for (index, operation) in operations.enumerated() {
            let before = operation.offset
            do {
                try await library.upload(operation, data: data) { [weak self] sent in
                    Task { @MainActor in self?.noteSent(id, bytes: before + Int(sent), of: data.count) }
                }
            } catch let error as URLError where Self.offlineCodes.contains(error.code) {
                throw error
            } catch {
                let timedOut = (error as? URLError)?.code == .timedOut
                throw ExtrasPushFailure.part(index + 1, count: operations.count, timedOut: timedOut, detail: Self.describe(error))
            }
            noteSent(id, bytes: operation.offset + operation.length, of: data.count)
        }
    }

    /// Checks the asset's state until Apple is done, waiting longer each
    /// time. A file Apple refused can't be placed, so a retry uploads it
    /// again; one still processing at the timeout is kept for the retry.
    private func waitUntilProcessed(_ asset: AssetLibraryAsset, item: ExtrasPushItem) async throws {
        let library = environment.library
        var waited: Duration = .zero
        var interval = environment.pollInterval
        while true {
            let status = try await call { try await library.assetLibraryAssetState(asset) }
            if status.isReady { return }
            if status.isFailed {
                committedAssets[item.id] = nil
                throw ExtrasPushFailure.processing(state: status.state ?? "FAILED", details: status.detailText)
            }
            guard waited < environment.processingTimeout else { throw ExtrasPushFailure.processingTimedOut }
            try await environment.sleep(interval)
            waited += interval
            interval = min(interval * 2, environment.longestPollInterval)
        }
    }
}
