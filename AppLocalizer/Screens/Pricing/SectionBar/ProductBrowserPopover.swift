//
//  ProductBrowserPopover.swift
//  AppLocalizer
//

import SwiftUI

/// Every subscription group with its subscriptions, then the in-app
/// purchases: name, product ID, duration, review state and base price.
struct ProductBrowserPopover: View {
    let catalog: PricingCatalog
    let selectedID: String?
    let onSelect: (PricingProduct) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                ForEach(catalog.groups) { group in
                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        Text(group.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.label2)
                            .padding(.horizontal, Spacing.small)
                        ForEach(group.products) { product in
                            row(product)
                        }
                    }
                }
            }
            .padding(Spacing.small)
        }
        .frame(width: 400)
        .frame(maxHeight: 420)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("pricing.productBrowser.popover")
    }

    private func row(_ product: PricingProduct) -> some View {
        Button {
            onSelect(product)
        } label: {
            HStack(spacing: Spacing.small) {
                Image(systemName: product.isInAppPurchase ? "bag" : "arrow.triangle.2.circlepath")
                    .foregroundStyle(Palette.label2)
                    .frame(width: 18)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(product.name).font(.body.weight(.medium))
                    Text([product.productID, product.durationText, product.reviewState].joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .lineLimit(1)
                }
                Spacer(minLength: Spacing.small)
                Text(product.basePriceText ?? "—")
                    .monospacedDigit()
                    .foregroundStyle(Palette.label2)
                if product.id == selectedID {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Palette.accentText)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(product.id == selectedID ? Palette.fill1 : .clear, in: RoundedRectangle(cornerRadius: Radius.field))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(product.id == selectedID ? .isSelected : [])
        .accessibilityIdentifier("pricing.product.\(product.productID)")
    }
}
