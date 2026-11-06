//
//  GuidedReviewShots.swift
//  AppLocalizer
//

import SwiftUI

/// The new set's screenshots in Review & push, in the language and on the
/// device chosen, side by side (scrolling sideways when they don't fit).
/// A click opens one full size.
struct GuidedReviewShots: View {
    @Bindable var studio: ScreenshotStudioModel
    let locale: String
    let device: ScreenshotDisplayType
    /// The width the shots have.
    let width: CGFloat

    var body: some View {
        let shots = studio.guidedNewShots(locale: locale, device: device)
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: Spacing.small) {
                ForEach(Array(shots.enumerated()), id: \.element.id) { index, shot in
                    Button {
                        studio.openGuidedShots(shots, locale: locale, device: device, at: index)
                    } label: {
                        GuidedShotImage(studio: studio, shot: shot, width: shotWidth(shot, count: shots.count))
                    }
                    .buttonStyle(.plain)
                    .help(Text("Click to view larger"))
                    .accessibilityIdentifier("autopilot.guided.review.shot.\(shot.slot)")
                }
            }
            .padding(Spacing.medium)
        }
        .frame(minHeight: 300)
        .modifier(GuidedSelectableCard(padding: 0))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(shots.count) screenshots"))
        .accessibilityIdentifier("autopilot.guided.review.shots")
    }

    /// Five phones fill the width, up to 150 pt each; landscape ones take
    /// twice the room, and the watch half.
    private func shotWidth(_ shot: StudioShot, count: Int) -> CGFloat {
        let shown = CGFloat(min(max(count, 1), 5))
        let phone = min(150, max(80, ((width - Spacing.medium * 2 - Spacing.small * (shown - 1)) / shown).rounded(.down)))
        if shot.aspect < 1 { return phone * 2 }
        if device == .watch { return (phone * 0.7).rounded() }
        return phone
    }
}
