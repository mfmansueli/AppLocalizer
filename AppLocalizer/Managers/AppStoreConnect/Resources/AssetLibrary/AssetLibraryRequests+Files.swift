//
//  AssetLibraryRequests+Files.swift
//  AppLocalizer
//

import Foundation

/// The library sheet's requests: every image and video in the app's
/// library, whether a file is on a page, and deleting one.
extension AssetLibraryRequests {
    /// `GET /v1/appAssetLibraries/{id}/images` (or `…/videos`), newest
    /// first.
    static func filesPath(libraryID: String, media: AssetLibraryMedia) -> String {
        let related = media == .image ? "images" : "videos"
        return "/v1/appAssetLibraries/\(libraryID)/\(related)?sort=-createdDate&limit=200"
    }

    /// `GET /v1/appAssetLibraryImages/{id}/relationships/placements`: one
    /// linkage is enough, the total says how many.
    static func placementLinksPath(_ asset: AssetLibraryAsset) -> String {
        "\(asset.media.path)/\(asset.id)/relationships/placements?limit=1"
    }

    /// `DELETE /v1/appAssetLibraryImages/{id}` (or `…Videos`). Apple
    /// refuses a file still placed on a page
    /// (`STATE_ERROR.ASSET_HAS_PLACEMENTS`).
    static func deleteAsset(_ asset: AssetLibraryAsset) -> PushRequest {
        PushRequest(method: .delete, path: "\(asset.media.path)/\(asset.id)", body: nil)
    }

    /// One page of files, and the next page's URL if there's more.
    static func files(in data: Data, media: AssetLibraryMedia) throws -> (files: [AssetLibraryFile], next: URL?) {
        do {
            let page = try JSONDecoder().decode(ScreenshotAPIDocument<AssetLibraryFileAttributes, AssetLibraryFileAttributes>.self, from: data)
            let files = page.data.map { resource in
                let attributes = resource.attributes
                let size = attributes?.image.flatMap { image -> PixelSize? in
                    guard let width = image.width, let height = image.height else { return nil }
                    return PixelSize(width: width, height: height)
                }
                return AssetLibraryFile(
                    id: resource.id, media: media, referenceName: attributes?.referenceName, fileName: attributes?.fileName,
                    fileSize: attributes?.fileSize, state: attributes?.state, createdDate: attributes?.createdDate,
                    thumbnailTemplate: attributes?.image?.templateUrl, pixelSize: size
                )
            }
            return (files, page.links?.next)
        } catch {
            throw AppStoreConnectError.unexpectedPayload
        }
    }

    /// How many placements a linkage response counts: `meta.paging.total`,
    /// else the linkages it lists.
    static func placementCount(in data: Data) throws -> Int {
        do {
            let linkages = try JSONDecoder().decode(AssetLibraryPlacementLinkages.self, from: data)
            return linkages.meta?.paging?.total ?? linkages.data.count
        } catch {
            throw AppStoreConnectError.unexpectedPayload
        }
    }
}
