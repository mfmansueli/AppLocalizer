//
//  ListingFieldTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("ListingField")
struct ListingFieldTests {
    @Test func columnsInOrderWithAPINames() {
        #expect(ListingField.allCases.map(\.shortTitle) == [
            "Name", "Subtitle", "Privacy", "Promo", "Description", "Keywords", "What’s New", "Support", "Marketing",
        ])
        #expect(ListingField.privacyPolicyURL.rawValue == "privacyPolicyUrl")
        #expect(ListingField.whatsNew.title == "What’s New")
    }

    @Test func nameSubtitleAndPrivacyAreAppLevel() {
        #expect(ListingField.appLevel == [.name, .subtitle, .privacyPolicyURL])
        #expect(ListingField.versionLevel.count == 6)
        #expect(ListingFieldLevel.app.groupTitle(version: "1.4") == "App information · all versions")
        #expect(ListingFieldLevel.version.groupTitle(version: "1.4") == "Version 1.4")
        #expect(ListingFieldLevel.app.badgeTitle(version: "1.4") == "App information")
    }

    @Test func limits() {
        #expect(ListingField.name.limit == ListingTextLimit(30))
        #expect(ListingField.subtitle.limit == ListingTextLimit(30))
        #expect(ListingField.promotionalText.limit == ListingTextLimit(170))
        #expect(ListingField.description.limit == ListingTextLimit(4000))
        #expect(ListingField.whatsNew.limit == ListingTextLimit(4000))
        #expect(ListingField.keywords.limit == ListingTextLimit(100, unit: .bytes))
        #expect(ListingField.supportURL.limit == nil)
        #expect(ListingField.allCases.filter(\.isURL) == [.privacyPolicyURL, .supportURL, .marketingURL])
    }

    @Test func whatsNewDoesntApplyToAFirstVersion() {
        #expect(!ListingField.whatsNew.applies(toFirstVersion: true))
        #expect(ListingField.whatsNew.applies(toFirstVersion: false))
        #expect(ListingField.description.applies(toFirstVersion: true))
    }

    @Test func versions() {
        let editable = ListingVersion("1.4", state: .prepareForSubmission)
        let live = ListingVersion("1.3", state: .readyForDistribution)
        #expect(editable.title == "Version 1.4 · Prepare for Submission")
        #expect(editable.pickerTitle == "1.4 · Prepare for Submission")
        #expect(editable.pickerSubtitle == "Editable")
        #expect(live.pickerSubtitle == "Live · read-only")
        #expect(editable.isEditable && !live.isEditable)
        #expect(ListingVersionState(apiValue: "METADATA_REJECTED").isEditable)
        #expect(ListingVersionState(apiValue: "SOMETHING_NEW") == .inReview)
    }

    @Test func aDraftReviewSubmissionIsStillEditable() {
        let added = ListingVersion("1.0", state: ListingVersionState(apiValue: "READY_FOR_REVIEW"))
        #expect(added.state == .readyForReview)
        #expect(added.isEditable)
        #expect(added.title == "Version 1.0 · Ready for Review")
        #expect(!ListingVersionState(apiValue: "WAITING_FOR_EXPORT_COMPLIANCE").isEditable)
        #expect(!ListingVersionState(apiValue: "PENDING_APPLE_RELEASE").isLive)
    }
}
