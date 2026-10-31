//
//  SuggestEverythingScopeTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What Suggest Everything covers and asks for: everything while the
/// version can change, and only what's still open while it's in review.
@MainActor
@Suite("SuggestEverythingScope")
struct SuggestEverythingScopeTests {
    private let information = DebugAppInformationContent.lumen(versionID: nil)
    private let inReview = StorePageVersion(id: "v2", listingVersion: ListingVersion("1.4", state: .waitingForReview), platform: "IOS")

    private func slots(_ content: AppInformationContent, accessibility: AccessibilityContent? = nil) -> AppInformationSlotValues {
        let builder = AppInformationChangeBuilder(appID: DebugFixtures.AppID.lumen, ids: content.ids, versionString: content.version?.versionString)
        return AppInformationSlotValues(content: content, accessibility: accessibility, builder: builder, changes: [])
    }

    @Test func anEditableVersionCoversEverything() {
        let scope = SuggestEverythingScope(
            appName: "Lumen Journal",
            listing: StorePageContentFixtures.editable.listing(),
            information: slots(information, accessibility: DebugAppInformationContent.accessibility(.lumen))
        )
        #expect(scope.versionString == StorePageContentFixtures.editableVersion.versionString)
        #expect(scope.rows.map(\.page) == [.storePage, .general, .ageRating, .accessibility, .appReview])
        #expect(scope.rows.map(\.isLocked) == [false, false, false, false, false])
        #expect(scope.rows[0].detail == "Every field in English (U.S.) and German")
        #expect(scope.rows[1].detail == "Copyright, categories, release")
        #expect(scope.rows[2].detail == "7 questions not answered, and a check of the rest")
        #expect(scope.rows[3].detail.hasSuffix(", every feature"))
        #expect(scope.rows[4].detail == "Contact and notes")
        #expect(scope.prompt.hasPrefix("Suggest everything for Lumen Journal \(scope.versionString ?? "") in AppLocalizer. Read the project first"))
        #expect(scope.prompt.contains("every Store Page field in every language"))
        #expect(scope.prompt.hasSuffix("Skip fields I’ve already changed."))
    }

    @Test func inReviewOnlyWhatCanStillChangeIsAsked() {
        let listing = StorePageContentFixtures.content(version: inReview, ids: StorePageContentFixtures.ids).listing()
        var content = information
        content.version = inReview
        let scope = SuggestEverythingScope(appName: "Lumen Journal", listing: listing, information: slots(content))

        // Accessibility couldn't be read, so it isn't listed.
        #expect(scope.rows.map(\.page) == [.storePage, .general, .ageRating, .appReview])
        #expect(scope.rows[0].detail == "Name, Subtitle, and Privacy Policy URL only, in 2 languages. The rest is locked while 1.4 is in review.")
        #expect(scope.rows[1].detail == "Categories only. The rest is locked while 1.4 is in review.")
        #expect(scope.rows[3].detail == "Locked while 1.4 is in review")
        #expect(scope.rows[3].isLocked)
        #expect(scope.prompt == """
        Suggest everything AppLocalizer can still change for Lumen Journal 1.4 while it’s in review: Name, Subtitle, \
        and Privacy Policy URL in every language, categories, and Age Rating. Read the project first. Skip fields I’ve already changed.
        """)
    }

    @Test func aLiveVersionIsLockedWhileItsOnTheAppStore() {
        let scope = SuggestEverythingScope(appName: "Lumen Journal", listing: StorePageContentFixtures.liveOnly.listing(), information: nil)
        #expect(scope.rows.first?.detail.hasSuffix("is on the App Store.") == true)
        #expect(scope.prompt.contains("while it’s on the App Store"))
    }

    @Test func beforeAnythingIsReadThePromptAsksForEverything() {
        let scope = SuggestEverythingScope(appName: "Lumen Journal", versionString: "1.4")
        #expect(scope.rows.isEmpty)
        #expect(scope.prompt == """
        Suggest everything for Lumen Journal 1.4 in AppLocalizer. Read the project first, then suggest every Store Page field in \
        every language, including languages the app supports that aren’t on the App Store yet, and App Information: General, Age \
        Rating, Accessibility for each device, and App Review. Skip fields I’ve already changed.
        """)
        #expect(SuggestEverythingScope(appName: "Lumen Journal", versionString: nil).prompt.hasPrefix("Suggest everything for Lumen Journal in"))
    }

    @Test func newLanguagesArePartOfTheStorePage() {
        let scope = SuggestEverythingScope(
            appName: "Lumen Journal",
            listing: StorePageContentFixtures.editable.listing(),
            information: nil,
            newLanguages: [.polish, .turkish, .hebrew]
        )
        #expect(scope.rows.first?.detail == """
        Every field in English (U.S.) and German, and new pages for Polish, Turkish, and Hebrew: the app supports them, the App \
        Store doesn’t have them yet
        """)
        #expect(scope.prompt.contains("including languages the app supports that aren’t on the App Store yet"))
    }

    @Test func loadingReadsTheProjectsLanguages() async {
        let workspace = MCPTestFixtures.workspace(apps: [StorePageContentFixtures.app], storePage: NewLanguagesFixtures.services())
        let scope = await SuggestEverythingScope.load(app: StorePageContentFixtures.app, in: workspace)
        #expect(scope.newLanguages == [.polish, .turkish, .hebrew])
        #expect(scope.rows.first?.detail.contains("new pages for Polish, Turkish, and Hebrew") == true)
    }

    @Test func theBusyLineSaysWhatTheAskStillSends() {
        var request = AssistantSuggestionRequest(appID: "1", area: .storePage, client: "Claude Code", prompt: "", startedAt: .now, received: 2)
        #expect(SuggestEverythingPopover.busyText(request)
            == "Claude Code is still sending Store Page suggestions. Those keep coming; this run skips the fields they cover.")
        request.total = 4
        #expect(SuggestEverythingPopover.busyText(request)
            == "Claude Code is still sending Store Page suggestions (2 of 4). Those keep coming; this run skips the fields they cover.")
    }
}
#endif
