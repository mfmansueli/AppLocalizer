//
//  OverviewHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The overview's top: icon and name, the version the Store Page edits and
/// where the app is on the App Store, its bundle ID and SKU, plus the quick
/// actions.
struct OverviewHeader: View {
    let app: StoreApp
    let storePage: StorePageSummary?
    /// Countries and regions the app has prices in; nil before Pricing's
    /// summary is here, or when it sells nothing.
    var territoryCount: Int?
    /// Hidden for apps set to Keep my prices or that sell nothing.
    let showsReviewSuggestions: Bool
    let onReviewSuggestions: () -> Void
    let onTranslateMissing: () -> Void
    let onReviewAndPush: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.large) {
            AppIconTile(name: app.name, icon: app.icon, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.title.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                if let whereText {
                    Text(whereText)
                        .font(.subheadline)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("overview.header.where")
                }
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Palette.label3)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            .frame(minWidth: 160, alignment: .leading)
            Spacer(minLength: Spacing.medium)
            HStack(spacing: Spacing.small) {
                if showsReviewSuggestions {
                    Button(action: onReviewSuggestions) {
                        Label("Review Suggestions", systemImage: "tag")
                    }
                    .accessibilityIdentifier("overview.reviewSuggestions")
                }
                Button(action: onTranslateMissing) {
                    Label("Translate Missing…", systemImage: "globe")
                }
                .accessibilityIdentifier("overview.translateMissing")
                Button(action: onReviewAndPush) {
                    Label("Review & Push", systemImage: "arrow.up.circle")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("overview.reviewAndPush")
            }
            .buttonBorderShape(.capsule)
            .fixedSize()
        }
    }

    /// "Version 1.4 · Prepare for Submission · on the App Store in 12
    /// languages and 175 countries and regions".
    private var whereText: String? {
        var parts: [String] = []
        if let version = storePage?.versionString {
            parts.append(String(localized: "Version \(version)"))
            if let state = storePage?.versionState { parts.append(state) }
        }
        if let languages = storePage?.localeCount, languages > 0 {
            let languagesText = languages == 1 ? String(localized: "1 language") : String(localized: "\(languages) languages")
            if let territoryCount, territoryCount > 0 {
                parts.append(String(localized: "on the App Store in \(languagesText) and \(territoryCount) countries and regions"))
            } else {
                parts.append(String(localized: "on the App Store in \(languagesText)"))
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var detail: AttributedString {
        var text = AttributedString(app.bundleID, attributes: AttributeContainer().font(.caption.monospaced()))
        if let sku = app.sku {
            text.append(AttributedString(" · " + String(localized: "SKU ")))
            text.append(AttributedString(sku, attributes: AttributeContainer().font(.caption.monospaced())))
        }
        return text
    }
}
