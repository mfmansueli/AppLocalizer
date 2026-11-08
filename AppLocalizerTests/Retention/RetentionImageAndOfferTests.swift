//
//  RetentionImageAndOfferTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A retention message's image (PNG, 3840 wide, 160 to 2160 tall, no
/// transparency) and retention offers: their terms, names, IDs and
/// Apple's limit of 10 a subscription.
@MainActor
@Suite("Retention images and offers")
struct RetentionImageAndOfferTests {
    // MARK: - Images

    @Test func onlyAnOpaquePNG3840WideFits() {
        #expect(RetentionImageRule.problems(width: 3840, height: 1000, isPNG: true, hasAlpha: false).isEmpty)
        #expect(RetentionImageRule.problems(width: 3840, height: 160, isPNG: true, hasAlpha: false).isEmpty)
        #expect(RetentionImageRule.problems(width: 3840, height: 2160, isPNG: true, hasAlpha: false).isEmpty)
        #expect(RetentionImageRule.problems(width: 3000, height: 1000, isPNG: true, hasAlpha: false) == [.wrongWidth(3000)])
        #expect(RetentionImageRule.problems(width: 3840, height: 2161, isPNG: true, hasAlpha: false) == [.wrongHeight(2161)])
        #expect(RetentionImageRule.problems(width: 3840, height: 159, isPNG: true, hasAlpha: false) == [.wrongHeight(159)])
        #expect(RetentionImageRule.problems(width: 3840, height: 1000, isPNG: false, hasAlpha: true) == [.notPNG, .transparency])
    }

    @Test func aFileIsReadForItsSizeAndTransparency() throws {
        let opaque = try RetentionTestFixtures.png(width: 3840, height: 1000)
        let clear = try RetentionTestFixtures.png(width: 3840, height: 1000, alpha: true)
        defer {
            try? FileManager.default.removeItem(at: opaque)
            try? FileManager.default.removeItem(at: clear)
        }
        let image = try #require(RetentionImageRule.image(at: opaque, name: "Moonrise"))
        #expect(image.pixelWidth == 3840)
        #expect(image.pixelHeight == 1000)
        #expect(image.fits)
        #expect(image.localPath == opaque.path)
        #expect(RetentionImageRule.image(at: clear)?.problems == [.transparency])
    }

    @Test func libraryImagesThatFitComeFirst() async {
        let model = RetentionModel(app: RetentionTestFixtures.app, services: DebugRetentionServices(), queue: ChangeQueue(), store: RetentionDraftStore())
        await model.loadLibrary()
        #expect(model.libraryImages.map(\.name) == ["Moonrise", "Pages and Moons", "Night Window", "Still Lake"])
        model.libraryState = .loaded([RetentionImage(name: "Wide", pixelWidth: 4000, pixelHeight: 1000)] + RetentionSampleData.images)
        #expect(model.libraryImages.last?.name == "Wide")
    }

    @Test func savedImagesGetASlugName() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "retention-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = try RetentionImageFiles.save(Data([1, 2, 3]), name: "Moonrise över Sidor!", appID: "app-1", in: directory)
        #expect(url.deletingLastPathComponent().lastPathComponent == "app-1")
        #expect(url.lastPathComponent.hasPrefix("moonrise-over-sidor-"))
        #expect(try Data(contentsOf: url) == Data([1, 2, 3]))
    }

    // MARK: - Offer terms

    @Test func payAsYouGoRepeatsTheBillingPeriod() {
        #expect(RetentionOfferTerm.make(mode: .payAsYouGo, months: 3, period: .oneMonth) == RetentionOfferTerm(duration: .oneMonth, periodCount: 3))
        #expect(RetentionOfferTerm.make(mode: .payAsYouGo, months: 3, period: .oneYear) == nil)
        #expect(RetentionOfferTerm.make(mode: .free, months: 1, period: .oneYear) == RetentionOfferTerm(duration: .oneMonth, periodCount: 1))
        #expect(RetentionOfferTerm.make(mode: .payUpFront, months: 6, period: .oneMonth) == RetentionOfferTerm(duration: .sixMonths, periodCount: 1))
    }

    @Test func theFirstDraftIsHalfPriceForThreeMonths() {
        let monthly = RetentionOfferDraft.starting(for: RetentionTestFixtures.monthly)
        #expect(monthly.mode == .payAsYouGo)
        #expect(monthly.months == 3)
        #expect(monthly.priceText == "2.49")
        let annual = RetentionOfferDraft.starting(for: RetentionTestFixtures.annual)
        #expect(annual.mode == .free)
        #expect(annual.months == 1)
    }

    @Test func anUnnamedOfferIsNamedAfterItsTerms() {
        let draft = RetentionOfferDraft(subscriptionID: RetentionTestFixtures.monthly.id, mode: .payAsYouGo, months: 3, priceText: "2.49")
        let offer = draft.offer(for: RetentionTestFixtures.monthly, existing: [])
        #expect(offer?.duration == .oneMonth)
        #expect(offer?.periodCount == 3)
        #expect(offer?.usPrice == Decimal(string: "2.49"))
        #expect(offer?.offerID.hasPrefix("retention.") == true)
        #expect(offer?.isQueued == true)
        #expect(RetentionOfferDraft.offerID(from: "Half price for 3 months!") == "retention.half_price_for_3_months")
        for typed in ["$2.49", "2,49", " 2.49 "] {
            #expect(RetentionOfferDraft(subscriptionID: "s", priceText: typed).price == Decimal(string: "2.49"))
        }
    }

    @Test func whatANewOfferCantBe() {
        let monthly = RetentionTestFixtures.monthly
        var draft = RetentionOfferDraft(subscriptionID: monthly.id, mode: .payAsYouGo, months: 3, priceText: "5.99")
        #expect(draft.problems(for: monthly, existing: []) == [.priceNotLower(usual: "$4.99")])
        draft.priceText = ""
        #expect(draft.problems(for: monthly, existing: []) == [.invalidPrice])
        draft = RetentionOfferDraft(subscriptionID: monthly.id, mode: .free, months: 1, paidMonths: 25, waitMonths: 1)
        #expect(draft.problems(for: monthly, existing: []) == [.invalidPaidMonths, .invalidWaitMonths])
    }

    @Test func aSubscriptionTakesTenOffers() {
        let monthly = RetentionTestFixtures.monthly
        let existing = (1...10).map { index in
            RetentionOffer(
                id: "o\(index)", subscriptionID: monthly.id, referenceName: "Offer \(index)", offerID: "retention.o\(index)",
                mode: .free, duration: .oneMonth, periodCount: 1
            )
        }
        let draft = RetentionOfferDraft(subscriptionID: monthly.id, mode: .free, months: 1)
        #expect(draft.problems(for: monthly, existing: Array(existing.prefix(9))).isEmpty)
        #expect(draft.problems(for: monthly, existing: existing) == [.tooManyOffers(subscription: "Lumen Plus Monthly")])
    }

    @Test func termsReadLikeTheDesign() throws {
        let half = try #require(RetentionSampleData.offers.first)
        #expect(half.terms(basePrice: Decimal(string: "4.99"), period: .oneMonth).contains("$2.49"))
        #expect(RetentionOffer.percentOff(price: Decimal(string: "2.49"), base: Decimal(string: "4.99")) == 50)
    }
}
#endif
