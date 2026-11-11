//
//  PaywallModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("PaywallModel")
struct PaywallModelTests {
    private static let acceptAll = PaywallContext.acceptAllLanguages(suggestions: 32, languages: 6)

    private func make(
        _ context: PaywallContext = PaywallModelTests.acceptAll, store: FakeProStore = FakeProStore(), continues: Bool = true
    ) async -> PaywallModel {
        let model = PaywallModel(context: context, entitlements: Entitlements(store: store), onContinue: continues ? {} : nil)
        await model.load()
        return model
    }

    @Test func yearlyWithItsTrialIsSelectedFirst() async {
        let model = await make()
        #expect(model.plan == .yearly)
        #expect(model.phase == .plans)
        #expect(model.callToAction == "Start 7-Day Free Trial")
        #expect(model.finePrint?.hasPrefix("Free for 7 days, then $59.99 a year.") == true)
        #expect(model.tag(for: FakeProStore.usOffers[0]) == "Save 50%")
        #expect(model.tag(for: FakeProStore.usOffers[1]) == nil)
    }

    @Test func pickingAPlanChangesTheButton() async {
        let model = await make()
        model.plan = .monthly
        #expect(model.callToAction == "Subscribe for $9.99 a Month")
        model.plan = .lifetime
        #expect(model.callToAction == "Buy Pro for $149.99")
    }

    @Test func theCardSaysWhatWasBlockedInThePersonsNumbers() {
        #expect(Self.acceptAll.title == "Accept All Languages is part of Pro")
        #expect(Self.acceptAll.detail?.hasPrefix("Accept 32 suggestions in 6 languages in one step.") == true)
        #expect(Self.acceptAll.detail?.contains("at a time stays free") == true)
        #expect(Self.acceptAll.feature == .acceptAll)
        #expect(Self.acceptAll.continueTitle == "Accept 32 Suggestions…")
        #expect(PaywallContext.recommendedPrices(countries: 104).detail?.hasPrefix("Set 104 prices") == true)
        #expect(PaywallContext.autopilot.feature == .autopilot)
        #expect(PaywallContext.retention.continueTitle == "Open Retention")
    }

    /// From the toolbar: the plans, with no card and nothing to finish.
    @Test func theToolbarsPaywallHasNoCard() async {
        let model = await make(.menu, continues: false)
        #expect(model.context.title == nil)
        #expect(model.context.detail == nil)
        #expect(model.context.feature == nil)
        #expect(model.continueTitle == nil)
        #expect(model.closeTitle == "Done")
    }

    @Test func buyingYearlyStartsTheTrialAndOffersToFinish() async {
        let store = FakeProStore()
        let model = await make(store: store)
        await model.buy()
        #expect(store.purchases == [.yearly])
        #expect(model.phase == .done)
        #expect(model.doneTitle == "Your free trial has started")
        #expect(model.doneSubtitle.hasPrefix("You won’t be charged until "))
        #expect(model.continueTitle == "Accept 32 Suggestions…")
        #expect(model.closeTitle == "Later")
    }

    @Test func lifetimeIsTheirs() async {
        let model = await make(.menu, continues: false)
        model.plan = .lifetime
        await model.buy()
        #expect(model.doneTitle == "Pro is yours")
        #expect(model.doneSubtitle == "Thanks for supporting AppLocalizer.")
    }

    @Test func closingTheAppStoresSheetGoesBackToThePlans() async {
        let store = FakeProStore()
        store.outcome = .cancelled
        let model = await make(store: store)
        await model.buy()
        #expect(model.phase == .plans)
        #expect(model.message == nil)
    }

    @Test func aFailedOrPendingPurchaseSaysWhy() async {
        let store = FakeProStore()
        store.outcome = .failed("The App Store couldn’t be reached.")
        let model = await make(store: store)
        await model.buy()
        #expect(model.phase == .plans)
        #expect(model.message == "The App Store couldn’t be reached.")
        store.outcome = .pending
        await model.buy()
        #expect(model.message?.contains("waiting for approval") == true)
        #expect(!model.entitlements.isPro)
    }

    @Test func compareShowsTheSplitAndComesBack() async {
        let model = await make()
        model.showCompare(true)
        #expect(model.phase == .compare)
        await model.buy()
        #expect(model.phase == .done, "Buying works from the comparison too")
        model.showCompare(true)
        #expect(model.phase == .done)
    }

    @Test func restoreFindsAnEarlierPurchaseOrSaysThereIsNone() async {
        let store = FakeProStore()
        let model = await make(store: store)
        await model.restore()
        #expect(model.phase == .plans)
        #expect(model.message == "No earlier purchase of Pro was found for this Apple Account.")
        store.restored = .lifetime
        await model.restore()
        #expect(model.phase == .done)
        #expect(model.doneTitle == "Pro is yours")
    }

    @Test func withoutTheAppStoreItSaysSoAndCantBuy() async {
        let store = FakeProStore()
        store.offersOnSale = []
        let model = await make(store: store)
        #expect(model.offersProblem?.hasPrefix("The App Store didn’t answer") == true)
        #expect(!model.canBuy)
        #expect(model.callToAction == "Loading Prices…")
        await model.buy()
        #expect(store.purchases.isEmpty)
    }

    @Test func theComparisonHasEveryRowOfTheSplit() {
        let rows = ProComparisonRow.all
        #expect(rows.count == 10)
        #expect(rows.first?.free == "1 app, 1 account")
        #expect(rows.filter(\.isMissingInFree).map(\.feature) == [
            "Accept All Languages, Translate All", "Autopilot", "Recommended prices for 175 countries", "Retention messages and offers",
        ])
    }
}
