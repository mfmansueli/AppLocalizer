//
//  PaywallModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The paywall sheet: what was blocked, the plan picked (Yearly with its
/// trial by default), buying it, and then what's unlocked with a button
/// that finishes what the person started.
@MainActor
@Observable
final class PaywallModel: Identifiable {
    let context: PaywallContext
    let entitlements: Entitlements
    var plan: ProPlan = .yearly
    private(set) var phase: PaywallPhase = .plans
    /// Under the button: why a purchase didn't go through, or that Restore
    /// found nothing.
    private(set) var message: String?
    /// The plan bought here, for what Done says.
    private(set) var bought: ProPlan?
    /// What the continue button does once the sheet has closed.
    @ObservationIgnored let onContinue: (() -> Void)?
    @ObservationIgnored private let now: () -> Date

    init(context: PaywallContext, entitlements: Entitlements, now: @escaping () -> Date = { .now }, onContinue: (() -> Void)? = nil) {
        self.context = context
        self.entitlements = entitlements
        self.now = now
        self.onContinue = onContinue
    }

    var offers: [ProOffer] { entitlements.offers }

    var selectedOffer: ProOffer? { entitlements.offer(for: plan) }

    /// "Save 50%" beside Yearly.
    func tag(for offer: ProOffer) -> String? {
        guard offer.plan == .yearly else { return nil }
        return ProOffer.savings(yearly: offer, monthly: entitlements.offer(for: .monthly))
    }

    var callToAction: String {
        if phase == .buying { return String(localized: "Waiting for the App Store…") }
        return selectedOffer?.callToAction ?? String(localized: "Loading Prices…")
    }

    var canBuy: Bool { phase != .buying && selectedOffer != nil }

    var finePrint: String? { selectedOffer?.finePrint }

    /// The plans couldn't be read: say so instead of an empty list.
    var offersProblem: String? {
        guard offers.isEmpty, !entitlements.isLoadingOffers else { return nil }
        return String(localized: "The App Store didn’t answer, so the plans aren’t shown. Check the connection and try again.")
    }

    func load() async {
        await entitlements.loadOffers()
    }

    func showCompare(_ shows: Bool) {
        guard phase == .plans || phase == .compare else { return }
        phase = shows ? .compare : .plans
    }

    func buy() async {
        guard canBuy else { return }
        let back = phase
        phase = .buying
        message = nil
        switch await entitlements.purchase(plan) {
        case .purchased:
            bought = plan
            phase = .done
        case .cancelled:
            phase = back
        case .pending:
            phase = back
            message = String(localized: "The purchase is waiting for approval. Pro starts by itself when it comes through.")
        case let .failed(reason):
            phase = back
            message = reason
        }
    }

    func restore() async {
        guard phase != .buying else { return }
        message = nil
        if await entitlements.restore() {
            bought = nil
            phase = .done
        } else {
            message = String(localized: "No earlier purchase of Pro was found for this Apple Account.")
        }
    }

    // MARK: - Done

    var doneTitle: String {
        switch entitlements.status {
        case .lifetime: String(localized: "Pro is yours")
        case let .subscribed(_, _, isTrial) where isTrial:
            String(localized: "Your free trial has started")
        default: String(localized: "You’re on Pro")
        }
    }

    /// "You won’t be charged until November 17."
    var doneSubtitle: String {
        if case let .subscribed(_, until?, true) = entitlements.status {
            return String(localized: "You won’t be charged until \(until.formatted(.dateTime.month(.wide).day())).")
        }
        return String(localized: "Thanks for supporting AppLocalizer.")
    }

    var continueTitle: String? {
        onContinue == nil ? nil : context.continueTitle
    }

    /// "Later" beside the continue button, "Done" alone.
    var closeTitle: String {
        continueTitle == nil ? String(localized: "Done") : String(localized: "Later")
    }
}
