//
//  ArtworkIcon.swift
//  AppLocalizer
//

import CoreGraphics
import SwiftUI

/// The app's icon for the artwork: App Store Connect's image when there is
/// one, else the tile AppLocalizer draws for it (a sample app's symbol).
@MainActor
enum ArtworkIcon {
    static let pixelSize = 512

    static func image(of app: StoreApp) async -> CGImage? {
        switch app.icon {
        case let .remote(url):
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
            return AppIconMargin.decodeTrimmed(data, maxPixelSize: pixelSize)
        case .symbol:
            let renderer = ImageRenderer(content: AppIconTile(name: app.name, icon: app.icon, size: CGFloat(pixelSize)))
            renderer.scale = 1
            return renderer.cgImage
        case nil:
            return nil
        }
    }
}
