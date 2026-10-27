//
//  AppPrivacyOverviewCard.swift
//  AppLocalizer
//

import SwiftUI

/// App Privacy on the overview: the worksheet, open questions, when it was
/// marked published, the last scan, and Out of date when App Store Connect
/// may no longer match.
struct AppPrivacyOverviewCard: View {
    let privacy: AppInformationSummary.Privacy
    let onOpen: () -> Void

    var body: some View {
        Card {
            HStack(alignment: .firstTextBaseline) {
                OverviewCardTitle(title: AppInformationPage.appPrivacy.title)
                Spacer(minLength: Spacing.small)
                if case .outOfDate = privacy.status {
                    AppPrivacyStatusPill(status: privacy.status, isShort: true)
                }
            }
            VStack(spacing: 0) {
                OverviewRow {
                    Text("Worksheet")
                } value: {
                    Text(privacy.worksheetTitle)
                }
                OverviewRow {
                    Text("Open questions")
                } value: {
                    Text(privacy.openQuestionCount == 0 ? String(localized: "None") : "\(privacy.openQuestionCount)")
                        .foregroundStyle(privacy.openQuestionCount == 0 ? Palette.label2 : Palette.label)
                }
                OverviewRow {
                    Text("App Store Connect")
                } value: {
                    Text(publishedText)
                        .foregroundStyle(Palette.label2)
                        .multilineTextAlignment(.trailing)
                }
                OverviewRow {
                    Text("Last scan")
                } value: {
                    Text(lastScanText)
                        .foregroundStyle(Palette.label2)
                        .multilineTextAlignment(.trailing)
                }
            }
            Button("Open App Privacy", action: onOpen)
                .controlSize(.small)
                .buttonBorderShape(.capsule)
                .accessibilityIdentifier("overview.appPrivacy.open")
        }
        .accessibilityIdentifier("overview.appPrivacyCard")
    }

    private var publishedText: String {
        guard let date = privacy.status.publishedDate else { return String(localized: "Not marked yet") }
        return String(localized: "Marked published \(date.formatted(date: .abbreviated, time: .omitted))")
    }

    private var lastScanText: String {
        guard let date = privacy.lastScanDate else { return String(localized: "Never") }
        let day = date.formatted(date: .abbreviated, time: .omitted)
        guard let assistant = privacy.lastScanAssistant else { return day }
        return "\(day) · \(assistant)"
    }
}
