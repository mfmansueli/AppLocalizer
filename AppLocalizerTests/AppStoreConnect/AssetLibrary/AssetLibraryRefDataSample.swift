//
//  AssetLibraryRefDataSample.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Reference data shaped like `GET /v1/appAssetLibraryRefData`'s: a 21:9
/// header, 3:2 search results, one 16:9 image for both, iPhone and iPad
/// App Previews, and limits for App Store versions and custom product
/// pages. It also carries what parsing must skip: an unknown key, a spec
/// without an ID, a number where a spec should be, and a spec mapping in
/// the object form.
enum AssetLibraryRefDataSample {
    static let headerGroup = "PRODUCT_PAGE_HEADER_UNIVERSAL"
    static let searchGroup = "SEARCH_RESULTS_UNIVERSAL"
    static let iPhoneGroup = "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE"
    static let iPadGroup = "IPAD_PRO_13_PROFILE"

    static let json = """
    {
      "data": [{
        "type": "appAssetLibraryRefData",
        "id": "1",
        "attributes": {
          "features": [
            {
              "featureId": "APP_STORE_VERSIONS",
              "placementPolicies": [
                {"placementType": "APP_PREVIEW", "groupLimits": [{"groupIds": ["\(iPhoneGroup)", "\(iPadGroup)"], "maxCount": 3}]},
                {"placementType": "PRODUCT_PAGE_HEADER_ASSET", "groupLimits": [{"groupIds": ["\(headerGroup)"], "maxCount": 1}]},
                {"placementType": "APP_STORE_SEARCH_RESULTS_ASSET", "groupLimits": [{"groupIds": ["\(searchGroup)"], "maxCount": 1}]}
              ]
            },
            {
              "featureId": "CUSTOM_PRODUCT_PAGES",
              "placementPolicies": [
                {"placementType": "APP_PREVIEW", "groupLimits": [{"groupIds": ["\(iPhoneGroup)"], "maxCount": 5}]}
              ]
            }
          ],
          "placementProfileGroups": [
            {"placementProfileGroupId": "\(iPhoneGroup)", "platform": "IPHONE_APP_STORE", "displayClassId": "IPHONE_69"}
          ],
          "imageSpecs": [
            {
              "specId": "spec-header",
              "shortName": "i3840x1646a0",
              "dimensions": {"minWidth": 3840, "maxWidth": 3840, "minHeight": 1646, "maxHeight": 1646},
              "aspectRatio": "21:9",
              "compatiblePlacementTypes": ["PRODUCT_PAGE_HEADER_ASSET"],
              "maxFileSize": 524288000,
              "universalAsset": false,
              "colorProfiles": ["P3"]
            },
            {
              "specId": "spec-wide",
              "shortName": "i5244x2950a0",
              "dimensions": {"minWidth": 5244, "maxWidth": 5244, "minHeight": 2950, "maxHeight": 2950},
              "compatiblePlacementTypes": ["PRODUCT_PAGE_HEADER_ASSET", "APP_STORE_SEARCH_RESULTS_ASSET"],
              "universalAsset": true
            },
            {
              "specId": "spec-search",
              "dimensions": {"minWidth": 1920, "maxWidth": 3840, "minHeight": 1280, "maxHeight": 2560},
              "aspectRatio": "3:2",
              "compatiblePlacementTypes": ["APP_STORE_SEARCH_RESULTS_ASSET"]
            },
            {"shortName": "no ID, skipped"},
            42
          ],
          "videoSpecs": [
            {
              "specId": "spec-preview-iphone",
              "shortName": "v886x1920f23~30t15~30u1",
              "dimensions": {"minWidth": 886, "maxWidth": 886, "minHeight": 1920, "maxHeight": 1920},
              "compatiblePlacementTypes": ["APP_PREVIEW"],
              "frameRates": [{"minFps": 23, "maxFps": 30}],
              "duration": {"min": "PT15S", "max": "PT30S"},
              "audioRequired": true,
              "maxFileSize": 524288000
            },
            {
              "specId": "spec-preview-iphone-landscape",
              "dimensions": {"minWidth": 1920, "maxWidth": 1920, "minHeight": 886, "maxHeight": 886},
              "compatiblePlacementTypes": ["APP_PREVIEW"]
            },
            {
              "specId": "spec-preview-ipad",
              "dimensions": {"minWidth": 1200, "maxWidth": 1200, "minHeight": 1600, "maxHeight": 1600},
              "compatiblePlacementTypes": ["APP_PREVIEW"]
            }
          ],
          "placementTypes": [
            {
              "placementTypeId": "PRODUCT_PAGE_HEADER_ASSET",
              "acceptsAssetCategories": ["CREATIVE_ASSETS"],
              "specMappings": [{"placementGroupId": "\(headerGroup)", "specs": ["spec-header", "spec-wide"]}]
            },
            {
              "placementTypeId": "APP_STORE_SEARCH_RESULTS_ASSET",
              "acceptsAssetCategories": ["CREATIVE_ASSETS"],
              "specMappings": [{"placementGroupId": "\(searchGroup)", "specs": ["spec-search", "spec-wide"]}]
            },
            {
              "placementTypeId": "APP_PREVIEW",
              "acceptsAssetCategories": ["APP_SCREENSHOTS_AND_PREVIEWS"],
              "specMappings": [
                {"placementGroupId": "\(iPhoneGroup)", "specs": ["spec-preview-iphone", "spec-preview-iphone-landscape"]},
                {"placementGroupId": "\(iPadGroup)", "specs": [{"specId": "spec-preview-ipad"}]}
              ]
            }
          ],
          "displayClasses": [{"displayClassId": "IPHONE_69", "deviceFamily": "IPHONE", "screenDimensions": ["6.9"]}]
        },
        "links": {"self": "https://api.appstoreconnect.apple.com/v1/appAssetLibraryRefData/1"}
      }],
      "links": {"self": "https://api.appstoreconnect.apple.com/v1/appAssetLibraryRefData"},
      "meta": {"paging": {"total": 1, "limit": 50}}
    }
    """

    /// The sample, parsed; empty if it ever stops parsing, which the
    /// parsing tests catch.
    static var refData: AssetLibraryRefData {
        (try? AssetLibraryRefData(json: Data(json.utf8))) ?? AssetLibraryRefData()
    }
}
