//
//  AssetLibraryFileRequestsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The library sheet's requests and Apple's answers, from the App Store
/// Connect API 4.5 examples: listing images and videos, a file's placement
/// count, and deleting a file.
@Suite("Asset library file requests")
struct AssetLibraryFileRequestsTests {
    @Test func pathsNameTheLibraryAndTheFile() {
        #expect(AssetLibraryRequests.filesPath(libraryID: "123", media: .image) == "/v1/appAssetLibraries/123/images?sort=-createdDate&limit=200")
        #expect(AssetLibraryRequests.filesPath(libraryID: "123", media: .video) == "/v1/appAssetLibraries/123/videos?sort=-createdDate&limit=200")
        let video = AssetLibraryAsset(id: "v-1", media: .video)
        #expect(AssetLibraryRequests.placementLinksPath(video) == "/v1/appAssetLibraryVideos/v-1/relationships/placements?limit=1")
        let delete = AssetLibraryRequests.deleteAsset(AssetLibraryAsset(id: "i-1", media: .image))
        #expect(delete.method == .delete)
        #expect(delete.path == "/v1/appAssetLibraryImages/i-1")
        #expect(delete.body == nil)
    }

    @Test func anImageListingReadsNamesSizesAndTheThumbnail() throws {
        let json = """
        {"data": [{"type": "appAssetLibraryImages", "id": "c3", "attributes": {
          "category": "CREATIVE_ASSETS", "createdDate": "2026-08-11T22:47:02Z", "fileName": "order-screen.png", "fileSize": 1284736,
          "imageAsset": {"templateUrl": "https://is1.mzstatic.com/image/thumb/x/{w}x{h}bb.{f}", "width": 1290, "height": 2796},
          "referenceName": "Order screen", "state": "PREPARE_FOR_SUBMISSION", "stateDetails": null}}],
         "links": {"self": "https://api.appstoreconnect.apple.com/v1/appAssetLibraries/1/images",
                   "next": "https://api.appstoreconnect.apple.com/v1/appAssetLibraries/1/images?cursor=AB"}}
        """
        let page = try AssetLibraryRequests.files(in: Data(json.utf8), media: .image)
        let file = try #require(page.files.first)
        #expect(file.id == "c3")
        #expect(file.title == "Order screen")
        #expect(file.fileName == "order-screen.png")
        #expect(file.fileSize == 1_284_736)
        #expect(file.stateTitle == "Ready")
        #expect(file.pixelSize == PixelSize(width: 1290, height: 2796))
        #expect(file.createdDate == ISO8601DateFormatter().date(from: "2026-08-11T22:47:02Z"))
        #expect(file.thumbnailURL(width: 50)?.absoluteString == "https://is1.mzstatic.com/image/thumb/x/100x217bb.png")
        #expect(page.next?.absoluteString.hasSuffix("cursor=AB") == true)
    }

    @Test func aVideoListingUsesItsPosterFrame() throws {
        let json = """
        {"data": [{"type": "appAssetLibraryVideos", "id": "3b", "attributes": {
          "createdDate": "2026-08-11T22:51:04.123Z", "fileName": "app-preview.mp4", "fileSize": 31457280,
          "previewFrameImage": {"image": {"templateUrl": "https://is1.mzstatic.com/p/{w}x{h}bb.{f}", "width": 886, "height": 1920},
                                "state": "COMPLETE"},
          "referenceName": "Autopilot · en-US · iPhone App Preview", "state": "APPROVED",
          "videoAsset": "https://video-ssl.itunes.apple.com/preview.m3u8"}}], "links": {}}
        """
        let file = try #require(try AssetLibraryRequests.files(in: Data(json.utf8), media: .video).files.first)
        #expect(file.media == .video)
        #expect(file.thumbnailTemplate == "https://is1.mzstatic.com/p/{w}x{h}bb.{f}")
        #expect(file.createdDate != nil, "Fractional seconds are read too")
        #expect(file.isFromAutopilot)
        #expect(file.stateTitle == "Approved")
    }

    @Test func thePlacementCountIsThePagingTotal() throws {
        let json = """
        {"data": [{"type": "appAssetLibraryPlacements", "id": "2e"}], "meta": {"paging": {"total": 3, "limit": 1}}}
        """
        #expect(try AssetLibraryRequests.placementCount(in: Data(json.utf8)) == 3)
        #expect(try AssetLibraryRequests.placementCount(in: Data(#"{"data": []}"#.utf8)) == 0)
    }
}
