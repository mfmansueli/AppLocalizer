//
//  AutopilotWatchPicksRow.swift
//  AppLocalizer
//

import SwiftUI

/// Apple Watch's picks under the iPhone columns: each watch screen's best
/// capture, with the others small underneath to pick instead.
struct AutopilotWatchPicksRow: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let isEditable: Bool

    private static let pickWidth: CGFloat = 66
    private static let otherWidth: CGFloat = 30

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.large) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ScreenshotDisplayType.watch.title).font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 150, alignment: .leading)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Spacing.medium) {
                    ForEach(Array(screens.enumerated()), id: \.element.id) { index, screen in
                        column(index: index, screen: screen)
                    }
                }
                .padding(3)
            }
        }
        .padding(Spacing.medium)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.pick.watch")
    }

    private var screens: [AutopilotScreen] { run.plan.screens(on: .watch) }

    /// "Best of 3 each · ranked the same way".
    private var subtitle: String {
        let most = screens.map { run.candidates(for: $0.id).count }.max() ?? 0
        return most > 1
            ? String(localized: "Best of \(most) each · ranked the same way")
            : String(localized: "Ranked the same way")
    }

    private func column(index: Int, screen: AutopilotScreen) -> some View {
        let candidates = run.candidates(for: screen.id)
        let picked = run.pickedCapture(for: screen.id)
        let others = candidates.filter { $0.id != picked?.id }
        return VStack(alignment: .leading, spacing: Spacing.xSmall) {
            if let picked {
                StudioShotImage(
                    image: studio.image(for: picked, width: 160), width: Self.pickWidth,
                    aspect: aspect(picked), cornerFraction: 0.24
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Self.pickWidth * 0.24 + 3, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .padding(-3)
                )
                .help(Text(picked.notes))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Apple Watch \(screen.name), picked: \(picked.notes)"))
                .accessibilityIdentifier("autopilot.pick.watch.picked.\(index)")
            } else {
                RoundedRectangle(cornerRadius: Self.pickWidth * 0.24, style: .continuous)
                    .fill(Palette.fill1)
                    .frame(width: Self.pickWidth, height: Self.pickWidth * 514 / 422)
                    .accessibilityLabel(Text("\(screen.name): no capture"))
            }
            if !others.isEmpty {
                HStack(spacing: 3) {
                    ForEach(others) { capture in
                        Button {
                            studio.pick(capture, for: screen.id)
                        } label: {
                            StudioShotImage(
                                image: studio.image(for: capture, width: 80), width: Self.otherWidth,
                                aspect: aspect(capture), cornerFraction: 0.24
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isEditable)
                        .help(Text(capture.notes))
                        .accessibilityLabel(Text("Pick Apple Watch \(screen.name) attempt \(capture.attempt): \(capture.notes)"))
                        .accessibilityIdentifier("autopilot.pick.watch.other.\(index).\(capture.attempt)")
                    }
                }
            }
            Text(screen.name)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
                .frame(width: Self.pickWidth, alignment: .leading)
        }
    }

    private func aspect(_ capture: AutopilotCapture) -> Double {
        Double(capture.pixelSize.height) / Double(max(capture.pixelSize.width, 1))
    }
}
