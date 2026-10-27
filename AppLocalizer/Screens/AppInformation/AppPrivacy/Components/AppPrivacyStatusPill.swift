//
//  AppPrivacyStatusPill.swift
//  AppLocalizer
//

import SwiftUI

/// Where App Privacy stands: outlined when not started, neutral in
/// progress and done, green text when marked published, warning when out
/// of date.
struct AppPrivacyStatusPill: View {
    let status: PrivacyWorksheetStatus
    var isShort = false

    var body: some View {
        Group {
            if case .published = status {
                Text(title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .foregroundStyle(Palette.positive)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Palette.positive.opacity(0.14), in: Capsule())
            } else {
                Pill(text: title, style: style)
            }
        }
        .accessibilityLabel(Text("App Privacy: \(title)"))
        .accessibilityIdentifier("appInformation.appPrivacy.status")
    }

    private var title: String {
        isShort ? status.shortTitle : status.title
    }

    private var style: PillStyle {
        switch status {
        case .notStarted: .outline
        case .outOfDate: .warning
        case .inProgress, .done, .published: .neutral
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        AppPrivacyStatusPill(status: .notStarted)
        AppPrivacyStatusPill(status: .inProgress)
        AppPrivacyStatusPill(status: .done)
        AppPrivacyStatusPill(status: .published(.now))
        AppPrivacyStatusPill(status: .outOfDate(.now), isShort: true)
    }
    .padding()
}
