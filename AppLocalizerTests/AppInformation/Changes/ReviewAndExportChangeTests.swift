//
//  ReviewAndExportChangeTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// App Review's changes (one per field, or one `POST` for a version without
/// review details; the password only as a Keychain placeholder) and Export
/// Compliance's build flag.
@Suite("App Information changes · App Review and Export Compliance")
struct ReviewAndExportChangeTests {
    private typealias Support = AppInformationTestSupport
    private let builder = Support.builder
    private let saved = AppReviewValues(firstName: "Ana", lastName: "Ribeiro", phone: "+39 011 555 0142", email: "review@northpier.dev")

    @Test func aFieldPatchesTheReviewDetails() throws {
        var edited = saved
        edited.email = "appreview@northpier.dev"
        let change = try #require(builder.reviewFieldChange(.email, from: saved, to: edited))
        #expect(change.id == "appInformation.\(Support.appID).appReview.v14.email")
        #expect(change.title == "Email · 1.4")
        #expect(change.requests.first?.path == "/v1/appStoreReviewDetails/review-1")
        #expect(Support.attributes(change.requests.first)["contactEmail"] as? String == "appreview@northpier.dev")
        #expect(Support.attributes(change.restoreRequests.first)["contactEmail"] as? String == "review@northpier.dev")
        #expect(change.conflictCheck?.expected == "review@northpier.dev")
    }

    @Test func thePasswordIsAPlaceholderMaskedAndNeverRestored() throws {
        var edited = saved
        edited.signInRequired = true
        edited.password = "sandbox-2026"
        let change = try #require(builder.reviewFieldChange(.password, from: saved, to: edited))
        let placeholder = PushRequest.secretPlaceholder(named: builder.passwordSecretName)
        #expect(Support.attributes(change.requests.first)["demoAccountPassword"] as? String == placeholder)
        #expect(change.newValue == "••••••••")
        #expect(change.restoreRequests.isEmpty)
        #expect(change.conflictCheck == nil)
        let encoded = try String(data: JSONEncoder().encode(change), encoding: .utf8)
        #expect(encoded?.contains("sandbox-2026") == false)
        #expect(builder.passwordSecretName == "appInformation.\(Support.appID).appReview.v14.password")
    }

    @Test func theSecretIsReadBackFromTheStoreNotTheChange() throws {
        var edited = saved
        edited.password = "sandbox-2026"
        let change = try #require(builder.reviewFieldChange(.password, from: saved, to: edited))
        #expect(builder.review(saved, with: [change]) { "from-keychain" }.password == "from-keychain")
        #expect(builder.review(saved, with: [change]) { nil }.password.isEmpty)
    }

    @Test func notesOverTheLimitAreBlocked() {
        var edited = saved
        edited.notes = String(repeating: "a", count: AppReviewField.notesLimit + 1)
        #expect(builder.reviewFieldChange(.notes, from: saved, to: edited)?.blockedReason != nil)
        edited.notes = String(repeating: "a", count: AppReviewField.notesLimit)
        #expect(builder.reviewFieldChange(.notes, from: saved, to: edited)?.blockedReason == nil)
    }

    @Test func aVersionWithoutReviewDetailsGetsOnePost() throws {
        var ids = Support.ids
        ids.reviewDetailID = nil
        let builder = AppInformationChangeBuilder(appID: Support.appID, ids: ids, versionString: "1.4")
        #expect(builder.reviewFieldChange(.email, from: AppReviewValues(), to: saved) == nil)
        let change = try #require(builder.newReviewDetailChange(saved))
        #expect(change.id == "appInformation.\(Support.appID).appReview.v14.new")
        #expect(change.requests.first?.method == .post)
        #expect(change.requests.first?.path == "/v1/appStoreReviewDetails")
        let attributes = Support.attributes(change.requests.first)
        #expect(attributes["contactFirstName"] as? String == "Ana")
        #expect(attributes["demoAccountRequired"] as? Bool == false)
        #expect(attributes["demoAccountPassword"] == nil)
        #expect(change.newValue == "Ana Ribeiro · review@northpier.dev")
        #expect(builder.newReviewDetailChange(AppReviewValues()) == nil)
    }

    @Test func reviewIsCompleteWithContactAndADemoAccountWhenNeeded() {
        var values = saved
        #expect(values.isComplete)
        values.signInRequired = true
        #expect(!values.isComplete)
        values.userName = "review"
        values.password = "secret"
        #expect(values.isComplete)
        values.phone = " "
        #expect(!values.isComplete)
    }

    @Test func exportAnswersSendOnlyTheBuildsFlag() throws {
        let export = ExportComplianceValues(buildID: "b42", buildNumber: "42", usesNonExemptEncryption: false)
        let answers = ExportComplianceAnswers(answers: [.usesEncryption: true, .isExempt: false])
        let change = try #require(builder.encryptionChange(export, to: answers))
        #expect(change.title == "Non-exempt encryption · build 42")
        #expect(change.requests.first?.path == "/v1/builds/b42")
        #expect(Support.attributes(change.requests.first)["usesNonExemptEncryption"] as? Bool == true)
        #expect(Support.attributes(change.restoreRequests.first)["usesNonExemptEncryption"] as? Bool == false)
        #expect(change.conflictCheck?.expected == "0")
        #expect(builder.usesNonExemptEncryption(export, with: [change]) == true)

        #expect(builder.encryptionChange(export, to: ExportComplianceAnswers(answers: [.usesEncryption: false])) == nil)
        #expect(builder.encryptionChange(ExportComplianceValues(), to: answers) == nil)
    }

    @Test func exportAnswersAddUp() {
        #expect(ExportComplianceAnswers().status == "Not answered")
        #expect(ExportComplianceAnswers().visibleQuestions == [.usesEncryption])
        let exempt = ExportComplianceAnswers(answers: [.usesEncryption: true, .isExempt: true])
        #expect(exempt.usesNonExemptEncryption == false)
        #expect(exempt.status == "Exempt")
        #expect(exempt.visibleQuestions == ExportComplianceQuestion.allCases)
        #expect(ExportComplianceAnswers(answers: [.usesEncryption: true]).usesNonExemptEncryption == nil)
        #expect(ExportComplianceAnswers(usesNonExemptEncryption: true).status == "Docs needed")
        #expect(ExportComplianceAnswers(usesNonExemptEncryption: false)[.usesEncryption] == false)
    }
}
