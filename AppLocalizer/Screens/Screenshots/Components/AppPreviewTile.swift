//
//  AppPreviewTile.swift
//  AppLocalizer
//

import SwiftUI

/// The read-only Preview column: a locale's App Preview with its length
/// (when known) and a lock, or a dash when it has none.
struct AppPreviewTile: View {
    let previews: LiveAppPreviewSet?
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        if let previews {
            VStack(spacing: Spacing.xSmall) {
                Image(systemName: "play.fill")
                Text(previews.durationTitle ?? String(localized: "Preview"))
                    .font(.caption.monospacedDigit())
                Image(systemName: "lock.fill").imageScale(.small)
            }
            .foregroundStyle(.white)
            .frame(width: width, height: height)
            .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: Radius.badge, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(accessibilityText(previews)))
        } else {
            Text(verbatim: "—")
                .foregroundStyle(Palette.label3)
                .frame(width: width)
                .accessibilityLabel(Text("No App Preview"))
        }
    }

    private func accessibilityText(_ previews: LiveAppPreviewSet) -> String {
        if let duration = previews.durationTitle {
            return String(localized: "App Preview, \(duration), read-only")
        }
        return String(localized: "App Preview, read-only")
    }
}
