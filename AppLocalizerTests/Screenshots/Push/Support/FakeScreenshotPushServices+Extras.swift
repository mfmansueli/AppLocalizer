//
//  FakeScreenshotPushServices+Extras.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
@testable import AppLocalizer

extension FakeScreenshotPushServices: ExtrasPushProviding {
    var assetLibrary: any AssetLibraryPushing { extrasLibrary }
    var productPageTesting: any ProductPageTesting { productPageTester }
}
#endif
