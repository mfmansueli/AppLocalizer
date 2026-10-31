//
//  StorePageNewLanguagesTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Languages the app's project has and its App Store page doesn't: the
/// banner and the picker suggest them, Add All, Create Page, editing or
/// accepting adds them as new pages, Not Now and Don’t Add take them back,
/// and the sheet adds the checked ones.
@MainActor
@Suite("StorePageViewModel+NewLanguages")
struct StorePageNewLanguagesTests {
    private let app = StorePageContentFixtures.app
    private let queue = ChangeQueue()
    private let suggestions = FieldSuggestionStore()

    private func makeModel(_ services: FakeStorePageServices = NewLanguagesFixtures.services()) async -> StorePageViewModel {
        let model = StorePageViewModel(app: app, services: services, queue: queue, suggestions: suggestions)
        await model.load()
        return model
    }

    /// Claude Code's name for a language's page.
    private func draft(_ locale: StoreLocale, name: String) {
        _ = suggestions.add(appID: app.id, target: .storePage(locale, .name), value: name, reason: "Translated.", source: .assistant(client: "Claude Code"))
    }

    private func newPageID(_ locale: StoreLocale, at level: ListingFieldLevel) -> String {
        switch level {
        case .app: "storePage.app1.appInfo.info.\(locale.code).new"
        case .version: "storePage.app1.version.v2.\(locale.code).new"
        }
    }

    // MARK: - Suggesting

    @Test func theProjectsLanguagesTheAppStoreLacksAreSuggested() async {
        let model = await makeModel()
        #expect(model.pendingLocales == [.polish, .turkish, .hebrew])
        #expect(model.editorLocales == [.englishUS, .german, .polish, .turkish, .hebrew])
        #expect(model.isNewLanguage(.polish))
        #expect(!model.isNewLanguage(.german))
        #expect(model.newLanguagesBannerText == """
        Lumen Journal’s 2.0 build supports 3 more languages than its App Store page: Polish, Turkish, Hebrew. People who use them \
        see the English page.
        """)
        #expect(model.addAllLanguagesTitle == "Add All 3")
        #expect(model.newLanguageTitle(.polish) == "Polish isn’t on the App Store yet")
        #expect(queue.changes.isEmpty)
    }

    @Test func aLanguagesCardSaysWhatTheProjectHasAndWhoDraftedIt() async {
        draft(.hebrew, name: "Lumen — יומן")
        let model = await makeModel()
        #expect(model.newLanguageText(.hebrew) == """
        Lumen Journal’s 2.0 build is translated into Hebrew (Localizable.xcstrings: 401 of 418 strings (95%); right to left; tested \
        in LumenUITests). People who use Hebrew see the English page today. Claude Code drafted the page below.
        """)
        #expect(model.newLanguageText(.turkish).hasSuffix("Connect an assistant or an AI provider to draft its text."))
    }

    @Test func withoutAReportOrAnEditableVersionNothingIsSuggested() async {
        let unreported = await makeModel(FakeStorePageServices())
        #expect(unreported.pendingLocales.isEmpty)
        #expect(unreported.newLanguagesBannerText == nil)

        let live = await makeModel(NewLanguagesFixtures.services(contents: [StorePageContentFixtures.liveOnly]))
        #expect(live.pendingLocales.isEmpty)
    }

    // MARK: - Adding

    @Test func addAllCreatesEachPageOnPushEvenWithoutText() async throws {
        let model = await makeModel()
        model.addAllPendingLanguages()
        #expect(model.pendingLocales.isEmpty)
        #expect(model.addedLanguages == [.polish, .turkish, .hebrew])
        #expect(model.toast?.text == """
        Added Polish, Turkish, Hebrew. The pages are created in App Store Connect when you push; their drafted text is in each tab.
        """)
        #expect(model.toast?.canUndo == true)
        let change = try #require(queue.change(id: newPageID(.polish, at: .version)))
        #expect(change.group == "Store Page · Polish (new)")
        #expect(change.title == "Polish · New page")
        #expect(change.source == .builtInSuggestion)
        #expect(change.creation?.title == "Create the Polish page")
        #expect(change.creation?.detail == "A new App Store language for Lumen Journal")
        #expect(change.creation?.fields.isEmpty == true)
        #expect(change.requests.first?.path == "/v1/appStoreVersionLocalizations")
        #expect(queue.change(id: newPageID(.polish, at: .app)) == nil)
        #expect(queue.changes.count == 3)

        model.undoToast()
        #expect(queue.changes.isEmpty)
        #expect(model.pendingLocales == [.polish, .turkish, .hebrew])
        #expect(model.toast == nil)
    }

    @Test func createPageAddsOneAndSaysWhatsNext() async {
        let model = await makeModel()
        model.openEditor(.polish)
        model.createPage(.polish)
        #expect(model.isAddedLanguage(.polish))
        #expect(model.editorLocale == .polish)
        #expect(model.pendingLocales == [.turkish, .hebrew])
        #expect(model.toast?.text == """
        Added Polish. The page is created in App Store Connect when you push; accept or edit the drafted text below.
        """)
    }

    @Test func acceptingASuggestionOnASuggestedLanguageAddsIt() async throws {
        draft(.polish, name: "Lumen — Dziennik")
        let model = await makeModel()
        let suggestion = try #require(model.shownSuggestion(.name, in: .polish))
        model.acceptSuggestion(suggestion)

        #expect(model.isAddedLanguage(.polish))
        let created = try #require(queue.change(id: newPageID(.polish, at: .app)))
        #expect(created.group == "Store Page · Polish (new)")
        #expect(created.creation?.detail == "A new App Store language for Lumen Journal, with the text below")
        #expect(created.creation?.fields.map(\.newValue) == ["Lumen — Dziennik"])
        #expect(created.creation?.fields.first?.source == .assistant(client: "Claude Code"))
        #expect(created.creation?.source == .builtInSuggestion)
        #expect(queue.change(id: newPageID(.polish, at: .version)) != nil)

        model.undoLastSuggestionBatch()
        #expect(queue.changes.isEmpty)
        #expect(model.isPendingLanguage(.polish))
    }

    @Test func typingInASuggestedLanguageAddsIt() async {
        let model = await makeModel()
        model.edit(.subtitle, in: .turkish, to: "Ruh hali günlüğü")
        #expect(model.isAddedLanguage(.turkish))
        #expect(queue.change(id: newPageID(.turkish, at: .app))?.creation?.title == "Create the Turkish page")
    }

    // MARK: - Taking back

    @Test func notNowStopsSuggestingItAndGoesToThePrimaryLanguage() async {
        let center = NewLanguagesFixtures.center()
        let model = await makeModel(NewLanguagesFixtures.services(center))
        model.openEditor(.polish)
        model.declineLanguage(.polish)
        #expect(center.isDeclined("pl", for: app.id))
        #expect(model.pendingLocales == [.turkish, .hebrew])
        #expect(model.editorLocale == .englishUS)
        #expect(!model.editorLocales.contains(.polish))
        #expect(queue.changes.isEmpty)
    }

    @Test func dontAddRemovesThePageAndReopensItsSuggestions() async {
        draft(.hebrew, name: "Lumen — יומן")
        let model = await makeModel()
        model.createPage(.hebrew)
        model.acceptAllSuggestions(in: .hebrew)
        #expect(queue.change(id: newPageID(.hebrew, at: .app)) != nil)

        model.removeLanguage(.hebrew)
        #expect(queue.changes.isEmpty)
        #expect(!model.isAddedLanguage(.hebrew))
        #expect(model.isPendingLanguage(.hebrew))
        #expect(model.shownSuggestion(.name, in: .hebrew)?.value == "Lumen — יומן")
    }

    // MARK: - The sheet

    @Test func theSheetAddsTheCheckedLanguages() async {
        let model = await makeModel(NewLanguagesFixtures.services(NewLanguagesFixtures.center(declined: ["he"])))
        model.presentNewLanguages()
        #expect(model.sheet == .newLanguages)
        #expect(model.newLanguageRows.map(\.locale) == [.polish, .turkish, .hebrew])
        #expect(model.newLanguageRows[0].evidence == "Localizable.xcstrings: 412 of 418 strings (98%)")
        #expect(model.newLanguageRows[0].drafted == "Not drafted yet: connect an assistant or an AI provider, or write it yourself.")
        // Hebrew was said Not Now to: listed, not checked.
        #expect(model.selectedNewLanguages == [.polish, .turkish])
        #expect(model.addSelectedLanguagesTitle == "Add 2 Languages")
        #expect(model.newLanguagesSheetSubtitle == """
        Found in Lumen Journal 2.0: Localizable.xcstrings in the Xcode project. Adding one creates its App Store page when you push.
        """)

        model.toggleNewLanguage(.turkish)
        #expect(model.addSelectedLanguagesTitle == "Add 1 Language")
        model.addSelectedLanguages()
        #expect(model.sheet == nil)
        #expect(model.addedLanguages == [.polish])
        #expect(model.newLanguageRows.first?.isAdded == true)
    }

    @Test func checkingADeclinedLanguageAddsItAgain() async {
        let center = NewLanguagesFixtures.center(declined: ["he"])
        let model = await makeModel(NewLanguagesFixtures.services(center))
        model.presentNewLanguages()
        model.toggleNewLanguage(.hebrew)
        model.addSelectedLanguages()
        #expect(model.addedLanguages == [.polish, .turkish, .hebrew])
        #expect(!center.isDeclined("he", for: app.id))
    }
}
