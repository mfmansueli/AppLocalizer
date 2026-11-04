//
//  DebugScreenshotPushServices+Extras.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

extension DebugScreenshotPushServices: ExtrasPushProviding {
    var assetLibrary: any AssetLibraryPushing { DebugAssetLibrary(delay: extrasScript.delay, processingChecks: extrasScript.processingChecks) }
    var productPageTesting: any ProductPageTesting { DebugProductPageTesting(script: extrasScript) }
    var assetLibraryFiles: any AssetLibraryManaging { libraryFiles }
}
#endif
