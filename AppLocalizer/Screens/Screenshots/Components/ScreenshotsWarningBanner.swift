//
//  ScreenshotsWarningBanner.swift
//  AppLocalizer
//

import SwiftUI

/// A yellow warning banner ("No version to push to."), drawn like the
/// design system's `Banner`, which has no warning kind with a triangle yet.
struct ScreenshotsWarningBanner<Actions: View>: View {
    let title: String
    let message: String
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.warningMark)
                .accessibilityHidden(true)
            Text("\(Text(title).fontWeight(.semibold)) \(Text(message).foregroundStyle(Palette.label2))")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.medium)
            HStack(spacing: Spacing.small) {
                actions()
            }
            .controlSize(.small)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Palette.warningTint, in: RoundedRectangle(cornerRadius: Radius.banner))
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .contain)
    }
}
