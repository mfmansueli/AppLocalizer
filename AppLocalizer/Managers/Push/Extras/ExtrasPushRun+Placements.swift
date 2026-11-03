//
//  ExtrasPushRun+Placements.swift
//  AppLocalizer
//

import Foundation

extension ExtrasPushRun {
    /// Refuses an App Preview before its upload when a group is full and
    /// it replaces none of what's there.
    func checkPreviewRoom(for item: ExtrasPushItem, in targets: [ExtrasPushTarget]) async throws {
        let assetID = committedAssets[item.id]?.id
        for target in targets {
            let existing = try await placements(of: item, in: target)
            guard !existing.contains(where: { $0.assetID != nil && $0.assetID == assetID }) else { continue }
            let kept = existing.filter { !item.replacesPlacementIDs.contains($0.id) }
            let limit = limit(of: target, default: ExtrasPushKind.defaultPreviewLimit)
            if kept.count >= limit { throw ExtrasPushFailure.previewsFull(group: target.placementGroup, limit: limit) }
        }
    }

    /// Places `asset` in each of the item's slots and returns the
    /// placements' IDs. A slot that already shows it (from an earlier
    /// round) is kept.
    func place(_ asset: AssetLibraryAsset, item: ExtrasPushItem, targets: [ExtrasPushTarget]) async throws -> [String] {
        var placementIDs: [String] = []
        for target in targets {
            let existing = try await placements(of: item, in: target)
            let mine = existing.first { $0.assetID == asset.id }
            let others = existing.filter { $0.id != mine?.id }
            switch item.kind {
            case .artwork, .motionArtwork:
                let limit = limit(of: target, default: 1)
                let id = try await put(asset, item: item, target: target, mine: mine, replacing: others, hasRoom: others.count < limit)
                placementIDs.append(id)
            case .appPreview:
                let replaced = others.filter { item.replacesPlacementIDs.contains($0.id) }
                let kept = others.filter { !item.replacesPlacementIDs.contains($0.id) }
                let limit = limit(of: target, default: ExtrasPushKind.defaultPreviewLimit)
                if mine == nil, kept.count >= limit { throw ExtrasPushFailure.previewsFull(group: target.placementGroup, limit: limit) }
                let id = try await put(asset, item: item, target: target, mine: mine, replacing: replaced, hasRoom: others.count < limit)
                if !kept.isEmpty { try await order([id] + kept.map(\.id), item: item, target: target) }
                placementIDs.append(id)
            }
        }
        return placementIDs
    }

    // MARK: - Steps

    /// Puts `asset` in `target` in place of `old`. With room in the group
    /// it's created first, so the slot is never empty; otherwise `old`
    /// goes first and, if the create is refused, is put back.
    private func put(
        _ asset: AssetLibraryAsset, item: ExtrasPushItem, target: ExtrasPushTarget, mine: AssetLibraryPlacement?,
        replacing old: [AssetLibraryPlacement], hasRoom: Bool
    ) async throws -> String {
        if let mine {
            try await delete(old)
            return mine.id
        }
        if hasRoom {
            let created = try await create(asset, item: item, target: target)
            try await delete(old)
            return created.id
        }
        try await delete(old)
        do {
            return try await create(asset, item: item, target: target).id
        } catch {
            guard !old.isEmpty, !(error is CancellationError) else { throw error }
            let restored = await restore(old, item: item, target: target)
            throw ExtrasPushFailure.placing(detail: Self.describe(error), restored: restored)
        }
    }

    /// The localization's placements in `target`, in their order.
    private func placements(of item: ExtrasPushItem, in target: ExtrasPushTarget) async throws -> [AssetLibraryPlacement] {
        let library = environment.library
        let placements = try await call {
            try await library.assetLibraryPlacements(
                localizationID: item.localizationID, placementType: target.placementType, placementGroup: target.placementGroup
            )
        }
        return placements.filter { placement in
            (placement.placementType ?? target.placementType) == target.placementType
                && (placement.placementGroup ?? target.placementGroup) == target.placementGroup
        }
    }

    private func create(_ asset: AssetLibraryAsset, item: ExtrasPushItem, target: ExtrasPushTarget) async throws -> AssetLibraryPlacement {
        let library = environment.library
        return try await call {
            try await library.createAssetLibraryPlacement(
                placementType: target.placementType, placementGroup: target.placementGroup, asset: asset, localizationID: item.localizationID
            )
        }
    }

    /// Deletes placements; one that's gone already is fine.
    private func delete(_ placements: [AssetLibraryPlacement]) async throws {
        let library = environment.library
        for placement in placements {
            do {
                try await call { try await library.deleteAssetLibraryPlacement(id: placement.id) }
            } catch AppStoreConnectError.notFound {
                continue
            }
        }
    }

    private func order(_ ids: [String], item: ExtrasPushItem, target: ExtrasPushTarget) async throws {
        let library = environment.library
        try await call {
            try await library.orderAssetLibraryPlacements(ids, placementGroup: target.placementGroup, localizationID: item.localizationID)
        }
    }

    /// Places the assets that were taken off again; true when every one
    /// came back.
    private func restore(_ old: [AssetLibraryPlacement], item: ExtrasPushItem, target: ExtrasPushTarget) async -> Bool {
        var restored = true
        for placement in old {
            if let asset = placement.asset, await (try? create(asset, item: item, target: target)) != nil { continue }
            restored = false
        }
        return restored
    }

    /// How many placements `target`'s group holds on a version, from
    /// Apple's reference data.
    private func limit(of target: ExtrasPushTarget, default fallback: Int) -> Int {
        refData?.groupLimit(placementType: target.placementType, placementGroup: target.placementGroup) ?? fallback
    }
}
