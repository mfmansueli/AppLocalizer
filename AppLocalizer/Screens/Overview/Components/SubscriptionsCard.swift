//
//  SubscriptionsCard.swift
//  AppLocalizer
//

import SwiftUI

/// Subscription groups, subscriptions and in-app purchases with their base
/// prices.
struct SubscriptionsCard: View {
    let summary: PricingSummary

    var body: some View {
        Card {
            OverviewCardTitle(title: String(localized: "Subscriptions"), systemImage: "tag")
            if summary.sellsAnything {
                Text(headline)
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 0) {
                    ForEach(summary.products) { product in
                        OverviewRow {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(product.name)
                                    .lineLimit(1)
                                Text("\(product.productID) · \(product.duration)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(Palette.label2)
                                    .lineLimit(1)
                            }
                        } value: {
                            Text(product.basePrice ?? "—")
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                    }
                }
            } else {
                Text("None")
                    .font(.title3.weight(.semibold))
                Text("This app has no subscriptions or in-app purchases. Store Page and App Information still work.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityIdentifier("overview.subscriptionsCard")
    }

    private var headline: String {
        var parts: [String] = []
        if summary.groupCount > 0 {
            parts.append(summary.groupCount == 1 ? String(localized: "1 group") : String(localized: "\(summary.groupCount) groups"))
        }
        if summary.subscriptionCount > 0 {
            parts.append(summary.subscriptionCount == 1
                ? String(localized: "1 subscription")
                : String(localized: "\(summary.subscriptionCount) subscriptions"))
        }
        if summary.inAppPurchaseCount > 0 {
            parts.append(summary.inAppPurchaseCount == 1
                ? String(localized: "1 in-app purchase")
                : String(localized: "\(summary.inAppPurchaseCount) in-app purchases"))
        }
        return parts.joined(separator: " · ")
    }
}
