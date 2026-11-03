//
//  AutopilotDuoPickCard.swift
//  AppLocalizer
//

import SwiftUI

/// One screen on iPhone Duo at Pick: the inner display's capture, the
/// cover display's, or both side by side, as the plan shows them. They
/// follow the iPhone pick; a click shows them full size.
struct AutopilotDuoPickCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let screen: AutopilotScreen
    let index: Int

    private static let height: CGFloat = 126

    var body: some View {
        let captures = studio.duoCaptures(run, screenID: screen.id)
        VStack(alignment: .leading, spacing: 6) {
            Text("\(index + 1) · \(screen.name)")
                .font(.callout.weight(.semibold))
                .lineLimit(1)
            Button {
                studio.openDuoPicks(run, at: index)
            } label: {
                HStack(alignment: .bottom, spacing: Spacing.small) {
                    if let inner = captures.inner { shot(inner, label: String(localized: "Inner display")) }
                    if let cover = captures.cover { shot(cover, label: String(localized: "Cover display")) }
                    if captures.inner == nil, captures.cover == nil {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Palette.fill1)
                            .frame(width: 168, height: Self.height)
                            .overlay(Text("No capture").font(.caption).foregroundStyle(Palette.label2))
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(captures.inner == nil && captures.cover == nil)
            .help(Text("Click to view larger"))
            .accessibilityLabel(Text("View \(screen.name) on iPhone Duo larger"))
            .accessibilityIdentifier("autopilot.pick.duo.\(index)")
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
    }

    private func shot(_ capture: AutopilotCapture, label: String) -> some View {
        let aspect = Double(capture.pixelSize.height) / Double(max(capture.pixelSize.width, 1))
        let width = (Self.height / aspect).rounded()
        return StudioShotImage(image: studio.image(for: capture, width: Int(width * 2)), width: width, aspect: aspect, cornerFraction: aspect > 1 ? 0.12 : 0.04)
            .overlay(
                RoundedRectangle(cornerRadius: width * (aspect > 1 ? 0.12 : 0.04) + 2, style: .continuous)
                    .strokeBorder(Color(white: 0.11), lineWidth: 2)
                    .padding(-2)
            )
            .accessibilityLabel(Text(label))
    }
}
