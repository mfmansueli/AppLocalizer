//
//  StudioShotView.swift
//  AppLocalizer
//

import SwiftUI

/// One screenshot in the App Store preview at real proportions, with its
/// slot and chip underneath.
struct StudioShotView: View {
    let shot: StudioShot
    let image: CGImage?
    let width: CGFloat
    var showsLabel = true
    var cornerFraction: CGFloat = 0.05

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            StudioShotImage(image: image, width: width, aspect: shot.aspect, cornerFraction: cornerFraction)
            if showsLabel {
                HStack(spacing: Spacing.xSmall) {
                    Text(shot.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if let chip = shot.chip { StudioShotChipView(chip: chip) }
                }
                .frame(width: width)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText))
        .accessibilityIdentifier("studio.shot.\(shot.slot)")
    }

    private var accessibilityText: String {
        var parts = [String(localized: "Screenshot \(shot.slot + 1)"), shot.name]
        if let chip = shot.chip { parts.append(chip.title) }
        return parts.joined(separator: ", ")
    }
}
