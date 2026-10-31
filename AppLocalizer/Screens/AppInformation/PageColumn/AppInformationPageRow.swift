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
    /// Open suggestions on the page: "2 suggestions" replaces the status.
    var suggestionCount = 0
    /// Still to come from Suggest Everything: "3 suggestions · 4 coming".
    var comingCount = 0
    let hasPendingChanges: Bool

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            VStack(alignment: .leading, spacing: 1) {
                Text(page.title)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(suggestionCount > 0 || comingCount > 0 ? AnyShapeStyle(Palette.machineTranslated) : AnyShapeStyle(.secondary))
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

    private var subtitle: String? {
        let suggestions: String? = switch suggestionCount {
        case 0: comingCount > 0 ? String(localized: "0 suggestions") : status
        case 1: String(localized: "1 suggestion")
        default: String(localized: "\(suggestionCount) suggestions")
        }
        guard comingCount > 0, let suggestions else { return suggestions }
        return suggestions + " · " + String(localized: "\(comingCount) coming")
    }

    /// "Age Rating, 9+, not pushed" or "General, 2 suggestions".
    private var accessibilityText: String {
        [page.title, subtitle, hasPendingChanges ? String(localized: "not pushed") : nil].compactMap(\.self).joined(separator: ", ")
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
