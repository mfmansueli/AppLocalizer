//
//  RetentionOfferDraft.swift
//  AppLocalizer
//

import Foundation

/// New Offer…: a retention offer as the sheet (or an assistant) fills it in.
/// Its price is the one in the United States; every other country gets
/// Apple's equalized price when it's pushed.
struct RetentionOfferDraft: Hashable, Sendable {
    /// Only the person sees it; a blank name gets one from the terms.
    var name = ""
    var subscriptionID: String
    var mode = RetentionOfferMode.payAsYouGo
    var months = 3
    var priceText = ""
    var paidMonths = 1
    var waitMonths: Int?

    /// The months the sheet offers: 1, 2, 3 and 6, and a year for an
    /// annual subscription.
    static func monthChoices(for period: SubscriptionPeriod?) -> [Int] {
        period == .oneYear ? [1, 2, 3, 6, 12] : [1, 2, 3, 6]
    }

    /// A first draft: pay as you go for 3 months at half the usual price.
    static func starting(for subscription: RetentionSubscription) -> RetentionOfferDraft {
        var draft = RetentionOfferDraft(subscriptionID: subscription.id)
        if subscription.period == .oneYear {
            draft.mode = .free
            draft.months = 1
        }
        if let base = subscription.basePrice {
            var half = base / 2
            var rounded = Decimal()
            NSDecimalRound(&rounded, &half, 2, .down)
            draft.priceText = NSDecimalNumber(decimal: rounded).stringValue
        }
        return draft
    }

    /// The price typed, with or without the dollar sign: "2.49", "$2.49",
    /// or "2,49".
    var price: Decimal? {
        var text = priceText.trimmingCharacters(in: .whitespaces)
        if text.contains(","), !text.contains(".") { text = text.replacingOccurrences(of: ",", with: ".") }
        let format = CurrencyFormat.usd
        return format.parse(text) ?? format.parse(format.prefix + text)
    }

    func term(for subscription: RetentionSubscription) -> RetentionOfferTerm? {
        RetentionOfferTerm.make(mode: mode, months: months, period: subscription.period)
    }

    /// Everything that keeps it from being added.
    func problems(for subscription: RetentionSubscription, existing: [RetentionOffer]) -> [RetentionOfferProblem] {
        var problems: [RetentionOfferProblem] = []
        if existing.count(where: { $0.subscriptionID == subscription.id }) >= RetentionLimits.offersPerSubscription {
            problems.append(.tooManyOffers(subscription: subscription.name))
        }
        if RetentionLimits.length(of: referenceName(for: subscription)) > RetentionLimits.referenceNameLength {
            problems.append(.nameTooLong)
        }
        if mode.hasPrice {
            if let price, price > 0 {
                if let base = subscription.basePrice, mode == .payAsYouGo, subscription.period != nil, price >= base {
                    problems.append(.priceNotLower(usual: CurrencyFormat.usd.format(base)))
                }
            } else {
                problems.append(.invalidPrice)
            }
        }
        if term(for: subscription) == nil { problems.append(.termUnavailable) }
        if !RetentionLimits.paidMonthsChoices.contains(paidMonths) { problems.append(.invalidPaidMonths) }
        if let waitMonths, !RetentionLimits.waitMonths.contains(waitMonths) { problems.append(.invalidWaitMonths) }
        let id = offerID(for: subscription)
        if existing.contains(where: { $0.subscriptionID == subscription.id && $0.offerID == id }), !name.isEmpty {
            problems.append(.offerIDTaken(id))
        }
        return problems
    }

    /// The name it's created with: the person's, else "$2.49 a month for 3
    /// months" or "1 month free".
    func referenceName(for subscription: RetentionSubscription) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let length = RetentionOfferDuration.monthsTitle(months)
        let price = price.map { CurrencyFormat.usd.format($0) } ?? ""
        switch mode {
        case .free: return String(localized: "\(length) free")
        case .payAsYouGo:
            let per = subscription.period == .oneYear ? String(localized: "a year") : String(localized: "a month")
            return String(localized: "\(price) \(per) for \(length)")
        case .payUpFront: return String(localized: "\(price) up front for \(length)")
        }
    }

    /// `offerId`: the name in lowercase letters, digits and underscores,
    /// after `retention.`, e.g. `retention.half_price_for_3_months`.
    func offerID(for subscription: RetentionSubscription) -> String {
        Self.offerID(from: referenceName(for: subscription))
    }

    static func offerID(from name: String) -> String {
        let folded = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX")).lowercased()
        var slug = ""
        for scalar in folded.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar), scalar.isASCII {
                slug.unicodeScalars.append(scalar)
            } else if !slug.hasSuffix("_"), !slug.isEmpty {
                slug += "_"
            }
        }
        while slug.hasSuffix("_") { slug.removeLast() }
        return "retention." + (slug.isEmpty ? "offer" : String(slug.prefix(48)))
    }

    /// The offer it becomes, waiting in Review & Push; nil while it has
    /// problems.
    func offer(for subscription: RetentionSubscription, existing: [RetentionOffer]) -> RetentionOffer? {
        guard problems(for: subscription, existing: existing).isEmpty, let term = term(for: subscription) else { return nil }
        let offerID = offerID(for: subscription)
        return RetentionOffer(
            id: RetentionOffer.newPrefix + offerID,
            subscriptionID: subscription.id,
            referenceName: referenceName(for: subscription),
            offerID: offerID,
            mode: mode,
            duration: term.duration,
            periodCount: term.periodCount,
            usPrice: mode.hasPrice ? price : nil,
            paidMonths: paidMonths,
            waitMonths: waitMonths,
            isShown: true,
            isQueued: true
        )
    }

    /// The sheet's summary: "$2.49 a month for 3 months on Lumen Plus
    /// Monthly."
    func summary(for subscription: RetentionSubscription) -> String {
        let length = RetentionOfferDuration.monthsTitle(months)
        let price = price.map { CurrencyFormat.usd.format($0) } ?? "—"
        switch mode {
        case .free:
            return String(localized: "Free for \(length) on \(subscription.name).")
        case .payAsYouGo:
            let per = subscription.period == .oneYear ? String(localized: "a year") : String(localized: "a month")
            return String(localized: "\(price) \(per) for \(length) on \(subscription.name).")
        case .payUpFront:
            return String(localized: "\(price) up front for \(length) on \(subscription.name).")
        }
    }

    /// What the price field's note says: "USD a month, then the usual $4.99
    /// a month".
    func priceNote(for subscription: RetentionSubscription) -> String {
        switch mode {
        case .free:
            return ""
        case .payAsYouGo:
            let per = subscription.period == .oneYear ? String(localized: "a year") : String(localized: "a month")
            guard let base = subscription.basePrice else { return String(localized: "USD \(per)") }
            return String(localized: "USD \(per), then the usual \(CurrencyFormat.usd.format(base)) \(per)")
        case .payUpFront:
            return String(localized: "USD once, for the whole period")
        }
    }
}
