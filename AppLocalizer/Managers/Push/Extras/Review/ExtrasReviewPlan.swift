//
//  ExtrasReviewPlan.swift
//  AppLocalizer
//

import Foundation

/// An app's Autopilot extras in Review & Push: what waits to be pushed,
/// what's already on App Store Connect, and the Product Page Optimization
/// tests its artwork can start.
struct ExtrasReviewPlan: Hashable, Sendable {
    var appID: StoreApp.ID
    var appName: String
    var directionName: String
    /// Not pushed yet, artwork first, then App Previews; each by language.
    var items: [ExtrasReviewItem]
    var pushedCount: Int
    /// The artwork made, pushed or not, in each language.
    var artwork: [ExtrasArtworkFile]
    var primaryLocale: String
    /// The Product Page Optimization variant, once one was made.
    var variant: ExtrasArtworkVariant?
    /// Discarded in review: they stay off App Store Connect until Undo or
    /// until they're made again.
    var discardedCount = 0

    /// Nothing to show, push, test or undo.
    var isEmpty: Bool { items.isEmpty && artwork.isEmpty && discardedCount == 0 }
    var pushable: [ExtrasReviewItem] { items.filter { !$0.isBlocked } }
    var blocked: [ExtrasReviewItem] { items.filter(\.isBlocked) }

    /// The artwork kinds made, in order.
    var artworkKinds: [AutopilotArtworkKind] {
        AutopilotArtworkKind.allCases.filter { kind in artwork.contains { $0.kind == kind } }
    }

    /// What “Test with Product Page Optimization…” can test: the header and
    /// search results, or both from the one 16:9 image.
    var testPlacements: [ProductPageTestPlacement] {
        var placements: [ProductPageTestPlacement] = []
        for kind in artworkKinds {
            for placement in ProductPageTestPlacement.placements(for: kind) where !placements.contains(placement) {
                placements.append(placement)
            }
        }
        return placements
    }

    /// The artwork a placement's test changes.
    func kind(for placement: ProductPageTestPlacement) -> AutopilotArtworkKind? {
        artworkKinds.first { ProductPageTestPlacement.placements(for: $0).contains(placement) }
    }

    /// Whether the placement's current image still waits here: the test's
    /// control is what the page shows, so it should go first.
    func controlWaits(_ placement: ProductPageTestPlacement) -> Bool {
        guard let kind = kind(for: placement) else { return false }
        return items.contains { $0.artworkKind == kind }
    }

    /// "28 extras discarded: App Store Connect keeps what it has.", or nil.
    var discardedTitle: String? {
        switch discardedCount {
        case 0: nil
        case 1: String(localized: "1 extra discarded: App Store Connect keeps what it has.")
        default: String(localized: "\(discardedCount) extras discarded: App Store Connect keeps what it has.")
        }
    }

    /// "4 images and 2 App Previews", "1 image".
    var countTitle: String {
        let images = items.count { $0.artworkKind != nil }
        let previews = items.count - images
        let imageText = images == 1 ? String(localized: "1 image") : String(localized: "\(images) images")
        let previewText = previews == 1 ? String(localized: "1 App Preview") : String(localized: "\(previews) App Previews")
        switch (images, previews) {
        case (_, 0): return imageText
        case (0, _): return previewText
        default: return String(localized: "\(imageText) and \(previewText)")
        }
    }
}
