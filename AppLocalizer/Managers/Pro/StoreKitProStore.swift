//
//  StoreKitProStore.swift
//  AppLocalizer
//

import Foundation
import StoreKit

/// AppLocalizer Pro on the App Store, with StoreKit 2: the three products'
/// prices, buying one, and what the person owns
/// (`Transaction.currentEntitlements`, then `Transaction.updates`).
struct StoreKitProStore: ProStore {
    func offers() async -> [ProOffer] {
        guard let products = try? await Product.products(for: ProPlan.allCases.map(\.productID)) else { return [] }
        var offers: [ProOffer] = []
        for plan in ProPlan.allCases {
            guard let product = products.first(where: { $0.id == plan.productID }) else { continue }
            await offers.append(Self.offer(plan, product))
        }
        return offers
    }

    func status() async -> ProStatus {
        var best = ProStatus.free
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result, transaction.revocationDate == nil,
                  let plan = ProPlan(productID: transaction.productID) else { continue }
            if plan == .lifetime { return .lifetime }
            best = .subscribed(plan: plan, until: transaction.expirationDate, isTrial: transaction.offer?.paymentMode == .freeTrial)
        }
        return best
    }

    func purchase(_ plan: ProPlan) async -> ProPurchaseOutcome {
        do {
            guard let product = try await Product.products(for: [plan.productID]).first else {
                return .failed(String(localized: "The App Store doesn’t have this plan right now. Try again in a moment."))
            }
            switch try await product.purchase() {
            case let .success(.verified(transaction)):
                await transaction.finish()
                return await .purchased(status())
            case .success(.unverified):
                return .failed(String(localized: "The App Store couldn’t verify the purchase. Nothing was charged; try again."))
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed(String(localized: "The purchase didn’t finish."))
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func restore() async -> ProStatus {
        try? await AppStore.sync()
        return await status()
    }

    func statusUpdates() -> AsyncStream<ProStatus> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    if case let .verified(transaction) = result { await transaction.finish() }
                    await continuation.yield(status())
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The plan with StoreKit's price in the person's currency, a month of
    /// Yearly in the same format, and the trial while they can still have it.
    private static func offer(_ plan: ProPlan, _ product: Product) async -> ProOffer {
        var offer = ProOffer(plan: plan, displayPrice: product.displayPrice, price: product.price)
        if plan == .yearly {
            offer.monthlyDisplayPrice = (product.price / 12).formatted(product.priceFormatStyle)
        }
        if let subscription = product.subscription, let intro = subscription.introductoryOffer, intro.paymentMode == .freeTrial,
           await subscription.isEligibleForIntroOffer
        {
            offer.trialDays = days(in: intro.period)
        }
        return offer
    }

    private static func days(in period: Product.SubscriptionPeriod) -> Int {
        switch period.unit {
        case .day: period.value
        case .week: period.value * 7
        case .month: period.value * 30
        case .year: period.value * 365
        @unknown default: period.value
        }
    }
}
