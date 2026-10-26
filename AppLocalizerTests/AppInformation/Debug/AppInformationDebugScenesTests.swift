//
//  AppInformationDebugScenesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Testing
@testable import AppLocalizer

/// Every App Information scene id (one per design screenshot) opens a
/// view, and the scenes' changes are the ones the design shows.
@MainActor
@Suite("AppInformationDebugScenes")
struct AppInformationDebugScenesTests {
    @Test(arguments: AppInformationDebugScenes.ids)
    func everySceneHasAView(id: String) {
        #expect(AppInformationDebugScenes.view(for: id) != nil)
    }

    @Test func unknownIDsAreLeftToOtherSections() {
        #expect(AppInformationDebugScenes.view(for: "store-coverage") == nil)
    }

    @Test func idsAreUnique() {
        #expect(Set(AppInformationDebugScenes.ids).count == AppInformationDebugScenes.ids.count)
    }

    @Test func theReviewSceneHasThreeDevicesAndOneCantPublish() throws {
        let changes = try [
            #require(DebugAppInformationChanges.iPhoneAddsReducedMotion),
            #require(DebugAppInformationChanges.iPadToSeven),
            #require(DebugAppInformationChanges.visionSwapsVoiceControl),
        ]
        #expect(changes.map { $0.option?.isEffective } == [true, true, false])
        #expect(changes[2].option?.disabledReason?.contains("Apple Vision Pro has no live version yet") == true)
        #expect(changes[0].newValue.hasPrefix("7 features"))
    }

    @Test func theAgeSceneHasSevenAnswersFiveOpen() {
        let answers = DebugAppInformationChanges.assistantAgeAnswers(confirmed: DebugAppInformationChanges.confirmedInAgeScene)
        #expect(answers.count == 7)
        #expect(answers.count { $0.blockedReason != nil } == 5)
    }
}
#endif
