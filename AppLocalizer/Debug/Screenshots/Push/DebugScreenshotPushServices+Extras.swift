//
//  DebugScreenshotPushServices+Extras.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

extension DebugScreenshotPushServices: ExtrasPushProviding {
    var assetLibrary: any AssetLibraryPushing { DebugAssetLibrary(delay: extrasScript.delay) }
    var productPageTesting: any ProductPageTesting { DebugProductPageTesting(script: extrasScript) }
}
#endif
