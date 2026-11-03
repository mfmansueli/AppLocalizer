//
//  AutopilotReadyNote.swift
//  AppLocalizer
//

import SwiftUI

/// Something to check before pushing, with a button to it.
struct AutopilotReadyNote: View {
    let title: String
    let detail: String
    var button: String?
    let identifier: String
    /// The artwork's findings, as pills and a line under the detail.
    var checks: [ArtworkCheck] = []
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.callout).foregroundStyle(Palette.label2).fixedSize(horizontal: false, vertical: true)
                ArtworkCheckPills(checks: checks)
                    .padding(.top, 2)
                    .accessibilityIdentifier("\(identifier).checks")
            }
            Spacer(minLength: Spacing.small)
            if let button, let action {
                Button(button, action: action)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }
}
