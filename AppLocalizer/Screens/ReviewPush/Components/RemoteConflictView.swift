//
//  RemoteConflictView.swift
//  AppLocalizer
//

import SwiftUI

/// Under a review row whose value changed in App Store Connect since the
/// last fetch: both values, and the person picks one.
struct RemoteConflictView: View {
    let mine: String
    let conflict: RemoteConflict
    let onKeepMine: () -> Void
    let onUseRemote: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Label("Changed in App Store Connect since your last fetch.", systemImage: "exclamationmark.triangle.fill")
                .font(.callout.weight(.semibold))
                .labelStyle(ConflictLabelStyle())
            HStack(spacing: Spacing.small) {
                Button("Keep mine · \(mine)", action: onKeepMine)
                    .accessibilityIdentifier("review.keepMine")
                Button("Use App Store Connect's · \(conflict.remoteDisplayValue)", action: onUseRemote)
                    .accessibilityIdentifier("review.useRemote")
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.warningTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    /// The warning glyph in the warning color, the text in the label color.
    private struct ConflictLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: Spacing.xSmall) {
                configuration.icon.foregroundStyle(Palette.warning)
                configuration.title
            }
        }
    }
}

#Preview {
    RemoteConflictView(
        mine: "R$ 109,90",
        conflict: RemoteConflict(remoteRawValue: "199.9", remoteDisplayValue: "R$ 199,90"),
        onKeepMine: {},
        onUseRemote: {}
    )
    .frame(width: 720)
    .padding()
}
