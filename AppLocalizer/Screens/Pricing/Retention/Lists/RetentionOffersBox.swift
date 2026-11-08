//
//  RetentionOffersBox.swift
//  AppLocalizer
//

import SwiftUI

/// Retention Offers: each subscription's offers with their terms, New
/// Offer…, and what the offer type is.
struct RetentionOffersBox: View {
    let model: RetentionModel

    var body: some View {
        RetentionBox(title: String(localized: "Retention Offers")) {
            Button("New Offer…") { model.isOfferSheetPresented = true }
                .buttonStyle(.link)
                .font(.callout)
                .disabled(model.subscriptions.isEmpty)
                .accessibilityIdentifier("retention.newOffer")
        } content: {
            ForEach(model.offers) { offer in
                row(offer)
                Divider()
            }
            Text("A new offer type for people about to cancel. Up to \(RetentionLimits.offersPerSubscription) per subscription; Apple decides who’s eligible and shows the best one.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small + 2)
        }
        .accessibilityIdentifier("retention.offers")
    }

    private func row(_ offer: RetentionOffer) -> some View {
        let status = model.status(of: offer)
        return VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(offer.referenceName)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Spacer(minLength: Spacing.xSmall)
                Pill(text: status?.title ?? String(localized: "Ready"), style: status?.pillStyle ?? .neutral)
            }
            Text(model.detail(of: offer))
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small + 2)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("retention.offer.\(offer.offerID)")
    }
}
