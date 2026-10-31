//
//  StudioShotChipView.swift
//  AppLocalizer
//

import SwiftUI

/// A shot's chip: English, New or Shortened, with why on hover.
struct StudioShotChipView: View {
    let chip: StudioShotChip

    var body: some View {
        Pill(text: chip.title, style: chip.style)
            .help(Text(chip.help))
            .accessibilityHint(Text(chip.help))
    }
}
