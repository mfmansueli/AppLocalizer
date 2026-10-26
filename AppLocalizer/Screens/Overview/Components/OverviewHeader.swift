//
//  OverviewHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The overview's top: icon, name, bundle ID, SKU and the version the Store
/// Page edits, plus the quick actions.
struct OverviewHeader: View {
    let app: StoreApp
    let storePage: StorePageSummary?
    /// Hidden for apps set to Keep my prices or that sell nothing.
    let showsReviewSuggestions: Bool
    let onReviewSuggestions: () -> Void
    let onTranslateMissing: () -> Void
    let onReviewAndPush: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.large) {
            AppIconTile(name: app.name, icon: app.icon, size: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.title.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Palette.label2)
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

    private var detail: AttributedString {
        var parts = [AttributedString(app.bundleID, attributes: AttributeContainer().font(.subheadline.monospaced()))]
        if let sku = app.sku {
            var skuText = AttributedString(String(localized: "SKU "))
            skuText.append(AttributedString(sku, attributes: AttributeContainer().font(.subheadline.monospaced())))
            parts.append(skuText)
        }
        if let version = storePage?.versionString {
            let state = storePage?.versionState.map { " · \($0)" } ?? ""
            parts.append(AttributedString(String(localized: "Version \(version)\(state)")))
        }
        return parts.dropFirst().reduce(into: parts[0]) { result, part in
            result.append(AttributedString(" · "))
            result.append(part)
        }
    }
}
