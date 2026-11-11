//
//  ProOffer.swift
//  AppLocalizer
//

import Foundation

/// One plan as the App Store sells it to this person: its price in their
/// currency, always from StoreKit, never written here.
struct ProOffer: Hashable, Sendable, Identifiable {
    var plan: ProPlan
    /// "$59.99".
    var displayPrice: String
    var price: Decimal
    /// Yearly's price for one month, "$5.00"; nil for the others.
    var monthlyDisplayPrice: String?
    /// Days free before the first payment; nil without a trial, or once
    /// the person has used it.
    var trialDays: Int?

    var id: ProPlan { plan }

    /// "/ year", "/ month", "once".
    var period: String {
        switch plan {
        case .yearly: String(localized: "/ year")
        case .monthly: String(localized: "/ month")
        case .lifetime: String(localized: "once")
        }
    }

    /// The line under the plan's name: "$5.00 a month · 7 days free",
    /// "Cancel anytime", "Pay once, Pro forever".
    var subtitle: String {
        switch plan {
        case .yearly:
            let parts = [
                monthlyDisplayPrice.map { String(localized: "\($0) a month") },
                trialDays.map { String(localized: "\($0) days free") },
            ].compactMap(\.self)
            return parts.isEmpty ? String(localized: "Cancel anytime") : parts.joined(separator: " · ")
        case .monthly: return String(localized: "Cancel anytime")
        case .lifetime: return String(localized: "Pay once, Pro forever")
        }
    }

    /// The button: "Start 7-Day Free Trial", "Subscribe for $9.99 a
    /// Month", "Buy Pro for $149.99". It says exactly what happens.
    var callToAction: String {
        switch plan {
        case .yearly:
            if let trialDays { return String(localized: "Start \(trialDays)-Day Free Trial") }
            return String(localized: "Subscribe for \(displayPrice) a Year")
        case .monthly: return String(localized: "Subscribe for \(displayPrice) a Month")
        case .lifetime: return String(localized: "Buy Pro for \(displayPrice)")
        }
    }

    /// The full price, period and how renewal works, under the button:
    /// what App Review checks for subscriptions (guideline 3.1.2).
    var finePrint: String {
        let renewal = String(localized: """
        Renews automatically until you cancel, at least 24 hours before the end of the period, in your Apple Account settings.
        """)
        switch plan {
        case .yearly:
            let lead = trialDays.map { String(localized: "Free for \($0) days, then \(displayPrice) a year.") }
                ?? String(localized: "\(displayPrice) a year.")
            return lead + " " + renewal
        case .monthly:
            return String(localized: "\(displayPrice) a month.") + " " + renewal
        case .lifetime:
            return String(localized: "One payment. Pro stays on every Mac signed in to your Apple Account, including future updates.")
        }
    }

    /// "Save 50%" on Yearly against twelve months of Monthly; nil when it
    /// saves less than 5%, or for the other plans.
    static func savings(yearly: ProOffer?, monthly: ProOffer?) -> String? {
        guard let yearly, let monthly, monthly.price > 0 else { return nil }
        let twelve = monthly.price * 12
        let saved = NSDecimalNumber(decimal: (twelve - yearly.price) / twelve * 100).doubleValue
        let percent = Int(saved.rounded())
        guard percent >= 5 else { return nil }
        return String(localized: "Save \(percent)%")
    }
}
