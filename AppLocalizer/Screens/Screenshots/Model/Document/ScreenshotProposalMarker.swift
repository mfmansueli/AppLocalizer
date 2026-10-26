//
//  ScreenshotProposalMarker.swift
//  AppLocalizer
//

import Foundation

/// A proposal waiting for review, as far as the Sets matrix cares: who
/// sent it and which captions (locale × slot) it would change. Cells with
/// one show the assistant's monogram. The proposal itself (operations,
/// reason, status) is the Proposals sheet's business.
struct ScreenshotProposalMarker: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var client: String
    var receivedAt: Date
    /// `locale` → slots the proposal changes captions in. Empty for a
    /// template proposal.
    var captionSlots: [String: [Int]]
    /// The template version a template proposal is based on.
    var basedOnVersion: Int?

    var source: ChangeSource { .assistant(client: client) }

    func touches(locale: String, slot: Int) -> Bool {
        captionSlots[locale]?.contains(slot) ?? false
    }
}
