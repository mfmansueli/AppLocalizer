//
//  AppInformationPageRow.swift
//  AppLocalizer
//

import SwiftUI

/// A page in the page column: its name, its one-line status under it, and
/// the blue dot when it has changes waiting in Review & Push.
struct AppInformationPageRow: View {
    let page: AppInformationPage
    let status: String?
    let hasPendingChanges: Bool

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            VStack(alignment: .leading, spacing: 1) {
                Text(page.title)
                    .lineLimit(1)
                if let status {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if hasPendingChanges {
                UnsavedDot(size: 7)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText))
        .accessibilityIdentifier("appInformation.pageRow.\(page.rawValue)")
    }

    /// "Age Rating, 9+, not pushed".
    private var accessibilityText: String {
        [page.title, status, hasPendingChanges ? String(localized: "not pushed") : nil].compactMap(\.self).joined(separator: ", ")
    }
}

#Preview {
    List {
        AppInformationPageRow(page: .general, status: "Lifestyle · Health & Fitness", hasPendingChanges: false)
        AppInformationPageRow(page: .ageRating, status: "9+", hasPendingChanges: true)
        AppInformationPageRow(page: .appPrivacy, status: nil, hasPendingChanges: false)
    }
    .frame(width: 172, height: 200)
}
