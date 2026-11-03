//
//  ExtrasPushProviding.swift
//  AppLocalizer
//

import Foundation

/// Screenshot push services that can also send Autopilot's extras through
/// the App Asset Library and make Product Page Optimization tests. The API
/// client does both; DEBUG scenes simulate App Store Connect.
@MainActor
protocol ExtrasPushProviding {
    var assetLibrary: any AssetLibraryPushing { get }
    var productPageTesting: any ProductPageTesting { get }
}
