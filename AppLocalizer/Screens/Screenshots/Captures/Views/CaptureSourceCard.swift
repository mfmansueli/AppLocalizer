//
//  CaptureSourceCard.swift
//  AppLocalizer
//

import SwiftUI

/// One of the drop zone's three ways in: fastlane snapshot, Xcode test
/// results, App Store Connect.
struct CaptureSourceCard: View {
    let title: String
    let message: String
    let identifier: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.label)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(Spacing.medium)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field + 2, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.field + 2, style: .continuous)
                    .strokeBorder(Palette.separator, lineWidth: 0.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
