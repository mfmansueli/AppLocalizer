//
//  LiveScreenshotPushServices+Extras.swift
//  AppLocalizer
//

import Foundation

extension LiveScreenshotPushServices: ExtrasPushProviding {
    var assetLibrary: any AssetLibraryPushing { client }
    var productPageTesting: any ProductPageTesting { client }
    var assetLibraryFiles: any AssetLibraryManaging { client }
}
