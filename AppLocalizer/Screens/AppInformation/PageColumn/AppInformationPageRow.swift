//
//  AppInformationPageRow.swift
//  AppLocalizer
//

import SwiftUI

/// A page in the page column: its name, its status under it, the blue dot
/// when it has changes waiting in Review & Push, and the suggestion count
/// or a check once it's up to date.
struct AppInformationPageRow: View {
    let page: AppInformationPage
    /// "7 suggested · 7 unanswered", "In progress", "Up to date".
    let status: String?
    var suggestionCount = 0
    /// Still to come from Suggest Everything: "3 suggested · 4 coming".
    var comingCount = 0
    var isUpToDate = false
    let hasPendingChanges: Bool

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            VStack(alignment: .leading, spacing: 1) {
                Text(page.title)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(suggestionCount > 0 || comingCount > 0 ? AnyShapeStyle(Palette.machineTranslated) : AnyShapeStyle(.secondary))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if hasPendingChanges {
                UnsavedDot(size: 7)
            }
            if suggestionCount > 0 {
                SuggestionBadge(count: suggestionCount)
            } else if isUpToDate {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.increase)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: 34)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText))
        .accessibilityIdentifier("appInformation.pageRow.\(page.rawValue)")
    }

    private var subtitle: String? {
        guard comingCount > 0 else { return status }
        return (status ?? "") + (status == nil ? "" : " · ") + String(localized: "\(comingCount) coming")
    }

    /// "Age Rating, 3 suggested, not pushed".
    private var accessibilityText: String {
        [page.title, subtitle, hasPendingChanges ? String(localized: "not pushed") : nil].compactMap(\.self).joined(separator: ", ")
    }
}

#Preview {
    List {
        AppInformationPageRow(page: .general, status: "2 suggested", suggestionCount: 2, hasPendingChanges: false)
        AppInformationPageRow(page: .ageRating, status: "Up to date", isUpToDate: true, hasPendingChanges: true)
        AppInformationPageRow(page: .appPrivacy, status: "In progress", hasPendingChanges: false)
    }
    .frame(width: 200, height: 200)
}
