//
//  CaptionProposalItem.swift
//  AppLocalizer
//

import Foundation

/// One caption in a caption proposal: `{ loc, slot, headline, subhead? }`.
/// It isn't measured when it arrives but whenever it's shown, so a template
/// change never makes it stale; its fit simply updates.
struct CaptionProposalItem: Codable, Hashable, Sendable, Identifiable {
    var locale: String
    /// 0-based.
    var slot: Int
    var headline: String
    /// Nil keeps the caption's subhead.
    var subhead: String?
    /// Nil while it waits.
    var decision: Decision?

    enum Decision: String, Codable, Hashable, Sendable {
        case accepted
        case rejected
    }

    var key: LocaleSlot { LocaleSlot(locale: locale, slot: slot) }
    var id: LocaleSlot { key }

    /// The caption it would write over `current`, keeping the subhead when
    /// it proposes none.
    func caption(over current: ScreenshotCaption?, provenance: CaptionProvenance) -> ScreenshotCaption {
        let subhead = subhead ?? current?.subhead
        return ScreenshotCaption(headline: headline, subhead: subhead, provenance: provenance)
    }
}
