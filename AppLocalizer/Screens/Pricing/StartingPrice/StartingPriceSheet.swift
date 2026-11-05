//
//  StartingPriceSheet.swift
//  AppLocalizer
//

import SwiftUI

/// Set Starting Price: a subscription's price in the United States, in US
/// dollars. The push reads Apple's price points for it and sets that price
/// there and the equalized one everywhere else.
struct StartingPriceSheet: View {
    let productName: String
    let onCancel: () -> Void
    let onSave: (Decimal) -> Void

    @State private var text: String
    @State private var showsProblem = false

    init(productName: String, initialPrice: Decimal?, onCancel: @escaping () -> Void, onSave: @escaping (Decimal) -> Void) {
        self.productName = productName
        self.onCancel = onCancel
        self.onSave = onSave
        _text = State(initialValue: initialPrice.map { NSDecimalNumber(decimal: $0).stringValue } ?? "")
    }

    private var price: Decimal? {
        NewSubscription.price(from: text).flatMap { NewSubscription.isValidPrice($0) ? $0 : nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text("Starting price")
                        .font(.title2.weight(.semibold))
                    Text("For \(productName). Every other country or region gets Apple’s equalized price.")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: Spacing.small) {
                    Text("Price in the United States")
                    Spacer()
                    TextField("Price", text: $text, prompt: Text(verbatim: "9.99"))
                        .labelsHidden()
                        .multilineTextAlignment(.trailing)
                        .frame(width: 110)
                        .accessibilityIdentifier("pricing.startingPrice.price")
                    Text(verbatim: "USD")
                        .foregroundStyle(Palette.label2)
                }
                if showsProblem, price == nil {
                    Text(NewSubscriptionProblem.invalidPrice.message)
                        .font(.caption)
                        .foregroundStyle(Palette.danger)
                }
            }
            .padding(Spacing.xLarge)
            Divider()
            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("pricing.startingPrice.cancel")
                Button("Add to Review & Push") {
                    guard let price else { showsProblem = true; return }
                    onSave(price)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("pricing.startingPrice.add")
            }
            .buttonBorderShape(.capsule)
            .padding(.horizontal, Spacing.xLarge)
            .padding(.vertical, Spacing.medium)
        }
        .frame(width: 440)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.startingPriceSheet")
    }
}
