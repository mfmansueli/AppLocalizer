//
//  GuidedLookScrollTarget.swift
//  AppLocalizer
//

import Foundation

/// What the Look step scrolls into view when a template or scene is
/// clicked: its preview opens under the thumbnails, often below the
/// sheet's fold, and its pick button sat under the footer, so a click
/// meant for Add to My Picks went to Next instead.
enum GuidedLookScrollTarget: Hashable {
    /// The previewed template's name and pick button.
    case templateFocus
    /// The previewed header scene, its pick button at the bottom.
    case sceneFocus
}
