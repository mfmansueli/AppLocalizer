//
//  TranslationPlannerTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("TranslationPlanner")
struct TranslationPlannerTests {
    private typealias Fixtures = StorePageFixtures

    private var sampleWithAddedLocales: StoreListing {
        var listing = StorePageSampleData.listing
        for locale in StorePageSampleData.addedLocales {
            listing.addLocale(locale)
        }
        return listing
    }

    // MARK: - Planning

    @Test func samplePlanCoversEveryEmptyField() {
        let job = StorePageSampleData.listing.translationPlan()
        #expect(job.totalCount == 11)
        #expect(job.locales.count == 9)
        #expect(job.sourceLocale == .englishUS)
        #expect(!job.locales.contains(.englishUS))
    }

    @Test func addedLocalesGetEveryField() {
        let job = sampleWithAddedLocales.translationPlan()
        #expect(job.totalCount == 38)
        #expect(job.locales.count == 12)
        #expect(job.itemCount(in: .korean) == 9)
        #expect(job.summary == "38 empty fields in 12 locales. URLs are copied from English (U.S.), not translated.")
    }

    @Test func urlsAndSameLanguageLocalesAreCopied() {
        let job = sampleWithAddedLocales.translationPlan()
        for item in job.items {
            let shouldCopy = item.key.field.isURL || item.key.locale == .englishUK
            #expect(item.method == (shouldCopy ? .copy : .translate), "\(item.key.id)")
        }
    }

    @Test func scopes() {
        let listing = sampleWithAddedLocales
        let korean = listing.translationPlan(scope: .locale(.korean))
        #expect(korean.locales == [.korean])
        #expect(korean.totalCount == 9)
        let subtitles = listing.translationPlan(scope: .field(.subtitle))
        #expect(subtitles.items.allSatisfy { $0.key.field == .subtitle })
        #expect(subtitles.locales == [.korean, .chineseSimplified, .dutch])
    }

    @Test func readOnlyVersionsPlanOnlyAppInformation() {
        var listing = StorePageSampleData.liveListing
        listing.addLocale(.korean)
        let job = listing.translationPlan()
        #expect(job.items.map(\.key.field) == [.name, .subtitle, .privacyPolicyURL])
    }

    // MARK: - Running a job

    @Test func jobProgress() {
        var job = Fixtures.listing().translationPlan()
        #expect(job.items.map(\.key.field) == [.privacyPolicyURL, .promotionalText, .keywords, .whatsNew, .supportURL, .marketingURL])
        #expect(job.summary == "6 empty fields in 1 locale. URLs are copied from English (U.S.), not translated.")
        #expect(job.fractionCompleted == 0)
        #expect(job.nextQueued?.key.field == .privacyPolicyURL)

        job.completeCopies()
        #expect(job.doneCount == 3)
        #expect(job.fractionCompleted == 0.5)
        #expect(job.progressLine == "3 of 6")
        #expect(job.nextQueued?.key.field == .promotionalText)

        job.start(Fixtures.key(.german, .promotionalText))
        #expect(job.current?.key.field == .promotionalText)
        #expect(job.progressLine == "3 of 6 · German · Promotional Text")

        job.complete(Fixtures.key(.german, .promotionalText), with: "Wochenrückblicke sind da.")
        job.fail(Fixtures.key(.german, .keywords), message: "Unsupported language pair")
        #expect(job.failedCount == 1)
        #expect(job.finishedCount == 5)
        job.retryFailed()
        #expect(job.failedCount == 0)
        #expect(job.nextQueued?.key.field == .keywords)

        job.cancelRemaining()
        #expect(job.totalCount == 4)
        #expect(job.isFinished)
        #expect(job.fractionCompleted == 1)
    }

    @Test func applyingAJobTagsTextButNotURLs() {
        var listing = Fixtures.listing()
        var job = listing.translationPlan()
        job.completeCopies()
        job.complete(Fixtures.key(.german, .promotionalText), with: "Wochenrückblicke sind da.")
        let applied = listing.applyTranslations(of: job)
        #expect(applied == 4)
        #expect(listing.draft(.promotionalText, in: .german).isMachineTranslated)
        #expect(!listing.draft(.supportURL, in: .german).isMachineTranslated)
        #expect(listing.value(.supportURL, in: .german) == "https://lumen.example/support")
        #expect(listing.value(.keywords, in: .german).isEmpty)
    }

    @Test func sampleTranslatorCopiesWhatItCantTranslate() {
        let job = sampleWithAddedLocales.translationPlan()
        for item in job.items where item.method == .copy {
            #expect(StorePageSampleData.translation(for: item) != nil)
        }
    }

    // MARK: - Reviewing suggestions

    @Test func reviewingSuggestions() {
        var listing = Fixtures.listing()
        var job = listing.translationPlan()
        job.completeCopies()
        job.complete(Fixtures.key(.german, .promotionalText), with: "Wochenrückblicke sind da.")
        var review = listing.suggestions(from: job)
        #expect(review.suggestions.count == 4)
        #expect(review.statusLine == "0 accepted · 4 to decide")

        review.accept(Fixtures.key(.german, .promotionalText))
        review.reject(Fixtures.key(.german, .marketingURL))
        #expect(review.statusLine == "1 accepted · 2 to decide")
        review.undo(Fixtures.key(.german, .marketingURL))
        #expect(review.pendingCount == 3)

        let applied = listing.apply(review)
        #expect(applied == 1)
        #expect(listing.coverageState(of: .promotionalText, in: .german) == .machineTranslated)
        #expect(listing.value(.supportURL, in: .german).isEmpty)

        review.acceptAll()
        #expect(review.acceptedCount == 4)
        review.rejectAll()
        #expect(review.rejectedCount == 4)
        #expect(review.accepted.isEmpty)
    }

    @Test func rightToLeftSuggestions() {
        let promo = TranslationSuggestion(key: ListingFieldKey(.arabic, .promotionalText), currentText: "", suggestedText: "جديد")
        let url = TranslationSuggestion(key: ListingFieldKey(.arabic, .supportURL), currentText: "", suggestedText: "https://lumen.example")
        #expect(promo.isRightToLeft)
        #expect(!url.isRightToLeft)
        #expect(url.validation == .valid)
    }
}
