//
//  ExtrasPushItem.swift
//  AppLocalizer
//

import Foundation

/// One Autopilot extra to push for one language: a header or search
/// results image, or an App Preview, already made and saved on this Mac.
/// It's uploaded to the app's asset library, then placed on that
/// language's version localization.
struct ExtrasPushItem: Hashable, Sendable, Identifiable {
    var id: String
    var appID: StoreApp.ID
    /// "German · Header 21:9".
    var title: String
    /// The `appStoreVersionLocalizations` ID it's placed on.
    var localizationID: String
    var kind: ExtrasPushKind
    var fileName: String
    var pixelSize: PixelSize
    /// The name it has in the asset library, e.g. "Autopilot · de-DE · Header 21:9".
    var referenceName: String
    /// Live App Preview placements this one takes the place of. Artwork
    /// always replaces what's in its slot, so it ignores this.
    var replacesPlacementIDs: [String] = []
    /// The made PNG or video.
    var fileURL: URL
}
