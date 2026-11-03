//
//  ProductPageTestRun+Upload.swift
//  AppLocalizer
//

import Foundation

extension ProductPageTestRun {
    /// The groups a language's variant goes in: those of the placement
    /// type whose specs take its size. None fails it before uploading.
    func groups(for locale: ProductPageTestLocale) async throws -> [String] {
        let refData = try await loadRefData()
        let placementType = request.placement.placementType
        let groups = refData.placementGroups(for: placementType, pixelSize: locale.treatmentPixelSize, isVideo: false)
        guard !groups.isEmpty else {
            throw ProductPageTestFailure.noMatchingGroup(
                placementType: placementType, pixelSize: locale.treatmentPixelSize, accepted: refData.acceptedSizes(for: placementType, isVideo: false)
            )
        }
        return groups
    }

    /// The variant reserved in the app's library, uploaded in parts,
    /// committed and processed.
    func processedAsset(for locale: ProductPageTestLocale) async throws -> AssetLibraryAsset {
        let data: Data
        do {
            data = try await environment.fileData(locale.treatmentFile)
        } catch {
            throw ProductPageTestFailure.file(detail: error.localizedDescription)
        }
        let library = environment.library
        let libraryID = try await libraryID()
        let fileName = locale.treatmentFile.lastPathComponent
        let referenceName = "AppLocalizer · \(request.testName) · \(request.treatmentName) · \(locale.locale)"
        let reservation = try await call {
            try await library.reserveAssetLibraryImage(
                libraryID: libraryID, fileName: fileName, fileSize: data.count, category: Self.artworkCategory, referenceName: referenceName
            )
        }
        try await uploadParts(of: locale.locale, operations: reservation.uploadOperations, data: data)
        try await call { try await library.commitAssetLibraryAsset(reservation.asset) }
        localeStatuses[locale.locale] = .processing
        try await waitUntilProcessed(reservation.asset)
        return reservation.asset
    }

    /// Header and search results artwork's library category.
    static let artworkCategory = "CREATIVE_ASSETS"

    // MARK: - Steps

    private func loadRefData() async throws -> AssetLibraryRefData {
        if let refData { return refData }
        let library = environment.library
        let loaded = try await call { try await library.assetLibraryRefData() }
        refData = loaded
        return loaded
    }

    private func libraryID() async throws -> String {
        if let libraryID { return libraryID }
        let library = environment.library
        let appID = request.appID
        let id = try await call { try await library.assetLibraryID(appID: appID) }
        libraryID = id
        return id
    }

    private func uploadParts(of locale: String, operations: [ScreenshotUploadOperation], data: Data) async throws {
        let library = environment.library
        for operation in operations {
            let before = operation.offset
            do {
                try await library.upload(operation, data: data) { [weak self] sent in
                    Task { @MainActor in self?.noteSent(locale, bytes: before + Int(sent), of: data.count) }
                }
            } catch let error as URLError where Self.offlineCodes.contains(error.code) {
                throw error
            } catch {
                throw ProductPageTestFailure.upload(detail: Self.describe(error))
            }
            noteSent(locale, bytes: operation.offset + operation.length, of: data.count)
        }
    }

    private func noteSent(_ locale: String, bytes: Int, of total: Int) {
        guard case let .uploading(fraction) = localeStatuses[locale], total > 0 else { return }
        let sent = min(1, Double(bytes) / Double(total))
        if sent > fraction { localeStatuses[locale] = .uploading(sent) }
    }

    /// Checks the asset's state until Apple is done, waiting longer each
    /// time.
    private func waitUntilProcessed(_ asset: AssetLibraryAsset) async throws {
        let library = environment.library
        var waited: Duration = .zero
        var interval = environment.pollInterval
        while true {
            let status = try await call { try await library.assetLibraryAssetState(asset) }
            if status.isReady { return }
            if status.isFailed { throw ProductPageTestFailure.processing(state: status.state ?? "FAILED", details: status.detailText) }
            guard waited < environment.processingTimeout else { throw ProductPageTestFailure.processingTimedOut }
            try await environment.sleep(interval)
            waited += interval
            interval = min(interval * 2, environment.longestPollInterval)
        }
    }
}
