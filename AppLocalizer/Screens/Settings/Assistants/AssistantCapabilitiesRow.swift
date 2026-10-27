//
//  AssistantCapabilitiesRow.swift
//  AppLocalizer
//

import SwiftUI

/// "What a paired assistant can do", in plain words: what it can and can't,
/// side by side, so the limits are stated before anything is paired.
struct AssistantCapabilitiesRow: View {
    static let can = [
        String(localized: "Read your apps’ listings, prices, app information, captures, captions and templates"),
        String(localized: "Measure a caption and render a preview to check its own work"),
        String(localized: "Send proposals: store text, prices, app information, a template revision, captions for a locale"),
    ]

    static let cannot = [
        String(localized: "Push anything to App Store Connect"),
        String(localized: "Change anything without your review"),
        String(localized: "Draw your app’s interface, or see your API key"),
    ]

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.large) {
            column(title: "It can", items: Self.can, systemImage: "checkmark")
                .accessibilityIdentifier("settings.ai.can")
            Divider()
            column(title: "It can’t", items: Self.cannot, systemImage: "xmark")
                .accessibilityIdentifier("settings.ai.cannot")
        }
        .padding(.vertical, Spacing.xxSmall)
    }

    private func column(title: LocalizedStringKey, items: [String], systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(title)
                .font(.callout.weight(.semibold))
            ForEach(items, id: \.self) { item in
                Label {
                    Text(item)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: systemImage)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.label2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
