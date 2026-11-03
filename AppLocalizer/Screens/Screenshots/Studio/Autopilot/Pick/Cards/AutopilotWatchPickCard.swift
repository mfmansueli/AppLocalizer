//
//  AutopilotWatchPickCard.swift
//  AppLocalizer
//

import SwiftUI

/// One Apple Watch screen at Pick: its best capture, ranked the same way
/// as iPhone's; a click shows it full size.
struct AutopilotWatchPickCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let screen: AutopilotScreen
    let index: Int

    private static let width: CGFloat = 110

    var body: some View {
        let picked = run.pickedCapture(for: screen.id)
        VStack(spacing: 6) {
            Button {
                studio.openWatchPicks(run, at: index)
            } label: {
                if let picked {
                    StudioShotImage(
                        image: studio.image(for: picked, width: 240), width: Self.width,
                        aspect: Double(picked.pixelSize.height) / Double(max(picked.pixelSize.width, 1)), cornerFraction: 0.24
                    )
                } else {
                    RoundedRectangle(cornerRadius: Self.width * 0.24, style: .continuous)
                        .fill(Palette.fill1)
                        .frame(width: Self.width, height: Self.width * 514 / 422)
                }
            }
            .buttonStyle(.plain)
            .disabled(picked == nil)
            .help(Text("Click to view larger"))
            .accessibilityLabel(Text("View \(screen.name) larger"))
            .accessibilityIdentifier("autopilot.pick.watch.\(index)")
            Text(screen.name)
                .font(.callout)
                .lineLimit(1)
                .frame(width: Self.width)
        }
    }
}
