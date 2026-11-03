//
//  AssetLibraryRefDataTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Apple's asset library reference data: parsed leniently, and asked
/// which placement groups take a file of a given size.
@Suite("AssetLibraryRefData")
struct AssetLibraryRefDataTests {
    private typealias Sample = AssetLibraryRefDataSample

    private let header = ExtrasPushKind.productPageHeader
    private let search = ExtrasPushKind.searchResults
    private let preview = ExtrasPushKind.appPreviewPlacement

    @Test func parsesEverySpecAndSkipsWhatDoesntDecode() throws {
        let refData = try AssetLibraryRefData(json: Data(Sample.json.utf8))

        #expect(refData.specs.map(\.id) == [
            "spec-header", "spec-wide", "spec-search", "spec-preview-iphone", "spec-preview-iphone-landscape", "spec-preview-ipad",
        ])
        #expect(refData.specs.first?.media == .image)
        #expect(refData.specs.last?.media == .video)
        #expect(refData.specs.first { $0.id == "spec-wide" }?.isUniversal == true)
        #expect(refData.specs.first?.maxFileSize == 524_288_000)
        #expect(refData.mappings.count == 4)
        #expect(refData.mappings.last == AssetLibrarySpecMapping(placementType: preview, placementGroup: Sample.iPadGroup, specIDs: ["spec-preview-ipad"]))
    }

    @Test func groupsArePickedByPixelSize() {
        let refData = Sample.refData

        #expect(refData.placementGroups(for: header, pixelSize: PixelSize(width: 3840, height: 1646), isVideo: false) == [Sample.headerGroup])
        #expect(refData.placementGroups(for: search, pixelSize: PixelSize(width: 3840, height: 1646), isVideo: false).isEmpty)
        #expect(refData.placementGroups(for: search, pixelSize: PixelSize(width: 3840, height: 2560), isVideo: false) == [Sample.searchGroup])
        #expect(refData.placementGroups(for: search, pixelSize: PixelSize(width: 1920, height: 1280), isVideo: false) == [Sample.searchGroup])
        #expect(refData.placementGroups(for: search, pixelSize: PixelSize(width: 1919, height: 1280), isVideo: false).isEmpty)
    }

    @Test func aSixteenByNineImageFitsTheHeaderAndSearchResults() {
        let wide = PixelSize(width: 5244, height: 2950)

        #expect(Sample.refData.placementGroups(for: header, pixelSize: wide, isVideo: false) == [Sample.headerGroup])
        #expect(Sample.refData.placementGroups(for: search, pixelSize: wide, isVideo: false) == [Sample.searchGroup])
    }

    @Test func appPreviewsGoToTheirDevicesGroup() {
        let refData = Sample.refData

        #expect(refData.placementGroups(for: preview, pixelSize: PixelSize(width: 886, height: 1920), isVideo: true) == [Sample.iPhoneGroup])
        #expect(refData.placementGroups(for: preview, pixelSize: PixelSize(width: 1920, height: 886), isVideo: true) == [Sample.iPhoneGroup])
        #expect(refData.placementGroups(for: preview, pixelSize: PixelSize(width: 1200, height: 1600), isVideo: true) == [Sample.iPadGroup])
        #expect(refData.placementGroups(for: preview, pixelSize: PixelSize(width: 886, height: 1920), isVideo: false).isEmpty)
        #expect(refData.placementGroups(for: preview, pixelSize: PixelSize(width: 1080, height: 1920), isVideo: true).isEmpty)
    }

    @Test func limitsComeFromAppStoreVersions() {
        let refData = Sample.refData

        #expect(refData.groupLimit(placementType: preview, placementGroup: Sample.iPhoneGroup) == 3)
        #expect(refData.groupLimit(placementType: preview, placementGroup: Sample.iPhoneGroup, feature: "CUSTOM_PRODUCT_PAGES") == 5)
        #expect(refData.groupLimit(placementType: header, placementGroup: Sample.headerGroup) == 1)
        #expect(refData.groupLimit(placementType: header, placementGroup: Sample.iPhoneGroup) == nil)
    }

    @Test func acceptedSizesNameTheExactOnes() {
        #expect(Sample.refData.acceptedSizes(for: header, isVideo: false) == [PixelSize(width: 3840, height: 1646), PixelSize(width: 5244, height: 2950)])
        #expect(Sample.refData.acceptedSizes(for: search, isVideo: false) == [PixelSize(width: 5244, height: 2950)])
    }

    @Test func applesDocumentedExampleParses() throws {
        let json = """
        {"data":[{"type":"appAssetLibraryRefData","id":"1","attributes":{
          "features":[{"featureId":"APP_STORE_VERSIONS","placementPolicies":[{"placementType":"APP_SCREENSHOT",
            "groupLimits":[{"groupIds":["IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","MAC_PROFILE"],"maxCount":10}]}]}],
          "imageSpecs":[{"specId":"f56c777c-99ea-5760-97ae-27c5f8cbb884","shortName":"i1290x2796a0",
            "dimensions":{"minWidth":1290,"maxWidth":1290,"minHeight":2796,"maxHeight":2796},"aspectRatio":"6:13",
            "compatiblePlacementTypes":["APP_SCREENSHOT","IMESSAGE_APP_SCREENSHOT"],"alphaAllowed":false,"maxFileSize":524288000}],
          "placementTypes":[{"placementTypeId":"APP_SCREENSHOT","acceptsAssetCategories":["APP_SCREENSHOTS_AND_PREVIEWS"],
            "specMappings":[{"placementGroupId":"IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","specs":["f56c777c-99ea-5760-97ae-27c5f8cbb884"]}]}]
        }}]}
        """
        let refData = try AssetLibraryRefData(json: Data(json.utf8))
        let size = PixelSize(width: 1290, height: 2796)

        #expect(refData.placementGroups(for: "APP_SCREENSHOT", pixelSize: size, isVideo: false) == ["IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE"])
        #expect(refData.groupLimit(placementType: "APP_SCREENSHOT", placementGroup: "MAC_PROFILE") == 10)
    }

    @Test func otherSpellingsAndOneResourceAreRead() throws {
        let json = """
        {"data":{"attributes":{
          "imageSpecs":{"id":"s1","dimensions":{"width":"3840","height":1646}},
          "placementTypes":[{"placementType":"PRODUCT_PAGE_HEADER_ASSET","specMappings":[{"placementGroup":"G","specIds":"s1"}]}],
          "features":[{"placementPolicies":[{"placementTypeId":"PRODUCT_PAGE_HEADER_ASSET","groupLimits":[{"groupId":"G","maxCount":"1"}]}]}]
        }}}
        """
        let refData = try AssetLibraryRefData(json: Data(json.utf8))

        #expect(refData.placementGroups(for: header, pixelSize: PixelSize(width: 3840, height: 1646), isVideo: false) == ["G"])
        #expect(refData.groupLimit(placementType: header, placementGroup: "G") == 1)
    }

    @Test func noDataIsAnUnexpectedPayload() throws {
        #expect(throws: AppStoreConnectError.unexpectedPayload) { try AssetLibraryRefData(json: Data(#"{"errors":[]}"#.utf8)) }
        #expect(throws: AppStoreConnectError.unexpectedPayload) { try AssetLibraryRefData(json: Data("not json".utf8)) }
        let empty = try AssetLibraryRefData(json: Data(#"{"data":[]}"#.utf8))
        #expect(empty == AssetLibraryRefData())
        #expect(empty.placementGroups(for: header, pixelSize: PixelSize(width: 3840, height: 1646), isVideo: false).isEmpty)
    }

    @Test func aRangeOfSizesKeepsItsShape() {
        let search = AssetLibrarySpec(id: "s", media: .image, minWidth: 1920, maxWidth: 3840, minHeight: 1280, maxHeight: 2560, aspectRatio: 1.5)

        #expect(search.accepts(PixelSize(width: 3000, height: 2000)))
        #expect(!search.accepts(PixelSize(width: 3840, height: 1646)))
        #expect(AssetLibrarySpec.ratio("3:2") == 1.5)
        #expect(AssetLibrarySpec.ratio("16 : 9") == 16.0 / 9.0)
        #expect(AssetLibrarySpec.ratio("wide") == nil)
        #expect(AssetLibrarySpec.ratio("0:9") == nil)
    }

    @Test func aSpecWithoutDimensionsTakesNothing() {
        let spec = AssetLibrarySpec(id: "s", media: .image)

        #expect(!spec.accepts(PixelSize(width: 3840, height: 1646)))
        #expect(spec.exactSize == nil)
    }
}
