//
//  ProposePrivacyAnswersToolTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `propose_privacy_answers`: suggestions land in the worksheet unreviewed,
/// the person's answers stay theirs, open questions and the scan are
/// recorded, and bad answers are refused with what to fix.
@MainActor
@Suite("propose_privacy_answers")
struct ProposePrivacyAnswersToolTests {
    private let services = DebugAppInformationServices(privacy: PrivacyWorksheet())
    private let lumen = "6450000001"

    private var worksheet: PrivacyWorksheet { services.privacy.worksheet(for: lumen) }

    private func call(_ arguments: [String: JSONValue]) async throws -> MCPToolOutcome {
        let workspace = MCPTestFixtures.workspace(appInformation: services)
        var arguments = arguments
        arguments["appId"] = "Lumen Journal"
        return try await ProposePrivacyAnswersTool().call(MCPToolArguments(arguments), in: MCPToolContext(workspace: workspace, clientName: "Claude Code"))
    }

    private let purchases: JSONValue = [
        "type": "purchases",
        "collected": true,
        "purposes": ["APP_FUNCTIONALITY"],
        "linked": true,
        "tracking": false,
        "confidence": "high",
        "rationale": "RevenueCat keeps purchase history per app user ID.",
        "evidence": [
            ["kind": "sdk_manifest", "sdk": "RevenueCat", "version": "5.14.2", "entry": "NSPrivacyCollectedDataTypePurchaseHistory"],
            ["kind": "code", "path": "Lumen/Paywall/PaywallModel.swift", "line": 88, "excerpt": "try await Purchases.shared.purchase(package: package)"],
        ],
    ]

    @Test func answersWaitUnreviewedWithTheirEvidence() async throws {
        let outcome = try await call([
            "collects": true,
            "answers": [purchases],
            "open_questions": [[
                "id": "q1",
                "question": "Does your support backend keep the email address after it replies?",
                "affects": ["email"],
                "if_yes": ["summary": "Email Address becomes collected.", "collected": true, "purposes": ["APP_FUNCTIONALITY"], "linked": true],
                "if_no": ["summary": "Email Address stays not collected.", "collected": false],
            ]],
            "scan": ["repository": "northpier/lumen", "commit": "4f2c91a", "sdks": [["name": "RevenueCat", "version": "5.14.2"]]],
        ])
        #expect(outcome.result["queued"] == 1)
        #expect(outcome.result["results"] == [["type": "purchases", "status": "queued"]])
        #expect(outcome.result["collects"] == "queued")
        #expect(outcome.result["openQuestions"] == "queued")
        #expect(outcome.logLines == [.init(target: "Lumen Journal · App Privacy · Purchase History", outcome: .proposed)])

        let entry = try #require(worksheet[.purchases])
        #expect(entry.status == .unreviewed)
        #expect(entry.answer == PrivacyAnswer(collected: true, purposes: [.appFunctionality], linked: true))
        #expect(entry.suggestion?.evidence.count == 2)
        #expect(entry.suggestion?.evidence.last?.line == 88)
        #expect(worksheet.manifestDeclarations[.purchases] == ["RevenueCat 5.14.2"])
        #expect(worksheet.openQuestions.first?.ifYes?.answer?.linked == true)
        #expect(worksheet.runningScan == nil)
        #expect(worksheet.lastScan?.source == "northpier/lumen @ 4f2c91a")
        #expect(worksheet.lastScan?.suggestionCount == 1)
    }

    @Test func notFinalKeepsTheScanRunning() async throws {
        _ = try await call(["answers": [purchases], "final": false])
        #expect(worksheet.runningScan?.answeredTypes == [.purchases])
        #expect(worksheet.scans.isEmpty)
    }

    @Test func thePersonsAnswerStaysAndTheAssistantsIsAConflict() async throws {
        services.privacy.update(lumen) { $0.edit(.purchases, to: PrivacyAnswer(collected: true, purposes: [.analytics], linked: true)) }
        let outcome = try await call(["answers": [purchases]])
        #expect(outcome.result["conflicts"] == 1)
        #expect(outcome.result["results"]?.arrayValue?.first?["status"] == "conflict")
        #expect(worksheet[.purchases]?.answer.purposes == [.analytics])
        #expect(worksheet[.purchases]?.conflict?.answer.purposes == [.appFunctionality])
    }

    @Test(arguments: [
        (["type": "fingerprint", "collected": true, "purposes": ["ANALYTICS"]] as JSONValue,
         "Unknown data type “fingerprint”. Use an id from get_privacy_questionnaire."),
        (["type": "email", "collected": true, "purposes": ["SUPPORT"]] as JSONValue,
         "Purpose “SUPPORT” isn’t one of Apple’s six. Did you mean APP_FUNCTIONALITY?"),
        (["type": "email", "collected": true] as JSONValue,
         "Collected data needs at least one purpose. Use the ids from get_privacy_questionnaire."),
    ])
    func aBadAnswerIsRefusedWithWhatToFix(answer: JSONValue, reason: String) async throws {
        let outcome = try await call(["answers": [answer, purchases]])
        let results = try #require(outcome.result["results"]?.arrayValue)
        #expect(results.first?["status"] == "refused")
        #expect(results.first?["reason"] == .string(reason))
        #expect(results.last?["status"] == "queued")
        #expect(outcome.result["refused"] == 1)
        #expect(outcome.logLines.first?.outcome == .refused)
        #expect(worksheet.entries.keys.sorted { $0.rawValue < $1.rawValue } == [.purchases])
    }

    @Test func trackingAtHighConfidenceNeedsEvidenceOfTracking() async throws {
        let unsupported: JSONValue = ["type": "deviceId", "collected": true, "purposes": ["THIRD_PARTY_ADVERTISING"], "tracking": true, "confidence": "high"]
        let refused = try await call(["answers": [unsupported]])
        #expect(refused.result["results"]?.arrayValue?.first?["status"] == "refused")

        let medium: JSONValue = ["type": "deviceId", "collected": true, "purposes": ["THIRD_PARTY_ADVERTISING"], "tracking": true, "confidence": "medium"]
        let queued = try await call(["answers": [medium]])
        #expect(queued.result["results"]?.arrayValue?.first?["status"] == "queued")

        let evidenced: JSONValue = [
            "type": "advertising", "collected": true, "purposes": ["THIRD_PARTY_ADVERTISING"], "tracking": true, "confidence": "high",
            "evidence": [["kind": "code", "path": "Ads/Ads.swift", "line": 4, "excerpt": "ATTrackingManager.requestTrackingAuthorization"]],
        ]
        let accepted = try await call(["answers": [evidenced]])
        #expect(accepted.result["results"]?.arrayValue?.first?["status"] == "queued")
        #expect(worksheet[.advertising]?.answer.tracking == true)
    }

    @Test func aQuestionAboutAnUnknownTypeIsRefused() async throws {
        let outcome = try await call(["open_questions": [["id": "q9", "question": "Do you fingerprint?", "affects": ["fingerprint"]]]])
        let refusal: JSONValue = [
            "id": "q9", "status": "refused", "reason": "Unknown data type “fingerprint”. Use an id from get_privacy_questionnaire.",
        ]
        #expect(outcome.result["openQuestions"] == [refusal])
        #expect(worksheet.questions.isEmpty)
    }

    @Test func itIsGatedByTheAppInformationSwitch() {
        #expect(ProposePrivacyAnswersTool().definition.proposalKind == .appInformation)
    }
}
#endif
