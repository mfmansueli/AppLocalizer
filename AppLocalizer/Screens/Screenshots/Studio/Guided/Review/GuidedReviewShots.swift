//
//  GuidedReviewShots.swift
//  AppLocalizer
//

import SwiftUI

/// The new set's screenshots in Review & push, in the language and on the
/// device chosen, side by side (scrolling sideways when they don't fit),
/// each with its slot ("1 · Today"), and under them the device's size and
/// what the App Store does with it. A click opens one full size.
struct GuidedReviewShots: View {
    @Bindable var studio: ScreenshotStudioModel
    let locale: String
    let device: ScreenshotDisplayType
    /// The width the shots have.
    let width: CGFloat

    var body: some View {
        let shots = studio.guidedNewShots(locale: locale, device: device)
        VStack(spacing: 0) {
            strip(shots)
            Text(GuidedReviewDeviceNote.line(device, size: shots.first?.pixelSize, app: studio.app.name, count: shots.count))
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding([.horizontal, .bottom], Spacing.medium)
                .accessibilityIdentifier("autopilot.guided.review.deviceNote")
        }
        .frame(minHeight: 300)
        .modifier(GuidedSelectableCard(padding: 0))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(shots.count) screenshots"))
        .accessibilityIdentifier("autopilot.guided.review.shots")
    }

    private func strip(_ shots: [StudioShot]) -> some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: Spacing.small) {
                ForEach(Array(shots.enumerated()), id: \.element.id) { index, shot in
                    Button {
                        studio.openGuidedShots(shots, locale: locale, device: device, at: index)
                    } label: {
                        let width = shotWidth(shot, count: shots.count)
                        VStack(spacing: Spacing.xxSmall) {
                            GuidedShotImage(studio: studio, shot: shot, width: width)
                            Text(shot.label)
                                .font(.caption)
                                .foregroundStyle(Palette.label2)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(width: width)
                                .accessibilityHidden(true)
                        }
                    }
                    .buttonStyle(.plain)
                    .help(Text("Click to view larger"))
                    .accessibilityIdentifier("autopilot.guided.review.shot.\(shot.slot)")
                }
            }
            .padding(Spacing.medium)
        }
        .frame(maxHeight: .infinity)
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
