//
//  StartingPriceView.swift
//  AppLocalizer
//

import SwiftUI

/// What Pricing shows for a subscription without a price yet (made in App
/// Store Connect without one, or one whose starting price couldn't be
/// set): Set Starting Price, or the one waiting in Review & Push.
struct StartingPriceView: View {
    @Bindable var viewModel: PricingViewModel

    var body: some View {
        ContentUnavailableView {
            Label("\(viewModel.selectedProduct?.name ?? "") has no price yet", systemImage: "tag")
        } description: {
            if let queued = viewModel.queuedStartingPrice {
                Text("Its starting price, \(queued.newValue), waits in Review & Push.")
            } else {
                Text("""
                Set its price in the United States; every other country or region gets Apple’s equalized price, \
                which you can change here after the push.
                """)
            }
        } actions: {
            HStack(spacing: Spacing.small) {
                Button(viewModel.queuedStartingPrice == nil ? "Set Starting Price…" : "Change Starting Price…") {
                    viewModel.isStartingPriceSheetPresented = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("pricing.setStartingPrice")
                if viewModel.queuedStartingPrice != nil {
                    Button("Review & Push…", action: viewModel.onOpenReview)
                        .accessibilityIdentifier("pricing.startingPrice.review")
                }
            }
            .buttonBorderShape(.capsule)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.noStartingPrice")
    }
}
