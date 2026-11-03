//
//  AutopilotPickCard.swift
//  AppLocalizer
//

import SwiftUI

/// One screen at Pick: the capture used, with whose pick it is and why,
/// then every attempt, small, the one used ringed. A click on either opens
/// the viewer at that attempt, where another can be used.
struct AutopilotPickCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let screen: AutopilotScreen
    let index: Int

    static let pickWidth: CGFloat = 128
    static let attemptWidth: CGFloat = 36

    var body: some View {
        let attempts = studio.pickAttempts(run, screenID: screen.id)
        let used = attempts.first(where: \.isUsed)
        VStack(alignment: .leading, spacing: 6) {
            Text("\(index + 1) · \(screen.name)")
                .font(.callout.weight(.semibold))
                .lineLimit(1)
            if let used {
                Button {
                    studio.openAttempts(run, screenID: screen.id, at: used.rank)
                } label: {
                    StudioShotImage(image: studio.image(for: used.capture, width: 300), width: Self.pickWidth, aspect: aspect(used.capture))
                        .overlay(
                            RoundedRectangle(cornerRadius: Self.pickWidth * 0.05 + 2, style: .continuous)
                                .strokeBorder(Color.accentColor, lineWidth: 2)
                                .padding(-2)
                        )
                }
                .buttonStyle(.plain)
                .help(Text("Click to view larger"))
                .accessibilityLabel(Text("View \(screen.name) larger"))
                .accessibilityIdentifier("autopilot.pick.picked.\(index)")
                Pill(text: studio.pickBadge(run, screenID: screen.id), style: studio.isYourPick(run, screenID: screen.id) ? .neutral : .accent)
                    .accessibilityIdentifier("autopilot.pick.badge.\(index)")
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Palette.fill1)
                    .frame(width: Self.pickWidth, height: Self.pickWidth * 2.17)
                    .overlay(Text("No capture").font(.caption).foregroundStyle(Palette.label2))
            }
            Text(studio.pickReason(run, screenID: screen.id))
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("autopilot.pick.reason.\(index)")
            if attempts.count > 1 {
                HStack(spacing: 5) {
                    ForEach(attempts) { attempt in
                        attemptButton(attempt)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private func attemptButton(_ attempt: AutopilotPickAttempt) -> some View {
        let label = String(localized: "Attempt \(attempt.rank + 1): \(attempt.capture.notes) · click to view larger")
        return Button {
            studio.openAttempts(run, screenID: screen.id, at: attempt.rank)
        } label: {
            StudioShotImage(
                image: studio.image(for: attempt.capture, width: 90), width: Self.attemptWidth, aspect: aspect(attempt.capture), cornerFraction: 0.16
            )
            .overlay(
                RoundedRectangle(cornerRadius: Self.attemptWidth * 0.16 + 2, style: .continuous)
                    .strokeBorder(attempt.isUsed ? Color.accentColor : Palette.separator2, lineWidth: attempt.isUsed ? 2 : 0.5)
                    .padding(attempt.isUsed ? -2 : 0)
            )
        }
        .buttonStyle(.plain)
        .help(Text(label))
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(attempt.isUsed ? String(localized: "Used") : ""))
        .accessibilityIdentifier("autopilot.pick.attempt.\(index).\(attempt.capture.attempt)")
    }

    private func aspect(_ capture: AutopilotCapture) -> Double {
        Double(capture.pixelSize.height) / Double(max(capture.pixelSize.width, 1))
    }
}
