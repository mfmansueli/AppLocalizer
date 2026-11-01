//
//  BuildIconAssetAttributes.swift
//  AppLocalizer
//

import Foundation

/// The `builds` attributes the app library asks for: the icon App Store
/// Connect took from the build's binary (`iconAssetToken`).
struct BuildIconAssetAttributes: Decodable, Sendable {
    var iconAssetToken: IconAsset?

    /// Where Apple serves the icon. `templateUrl` ends in `{w}x{h}bb.{f}`,
    /// the size and format to serve it at.
    struct IconAsset: Decodable, Sendable {
        var templateUrl: String?

        /// The icon, `side` pixels square, as PNG.
        func url(side: Int) -> URL? {
            guard let templateUrl, templateUrl.contains("{w}") else { return nil }
            return URL(string: templateUrl
                .replacingOccurrences(of: "{w}", with: "\(side)")
                .replacingOccurrences(of: "{h}", with: "\(side)")
                .replacingOccurrences(of: "{f}", with: "png"))
        }
    }
}
