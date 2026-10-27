//
//  GetPrivacyQuestionnaireToolTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `get_privacy_questionnaire`: Apple's terms, the worksheet as it stands,
/// and the scan it starts on the page.
@MainActor
@Suite("get_privacy_questionnaire")
struct GetPrivacyQuestionnaireToolTests {
    private let services = DebugAppInformationServices(privacy: PrivacyWorksheet())

    private func call(_ appID: String = "Lumen") async throws -> MCPToolOutcome {
        let workspace = MCPTestFixtures.workspace(appInformation: services)
        let context = MCPToolContext(workspace: workspace, clientName: "Claude Code")
        return try await GetPrivacyQuestionnaireTool().call(MCPToolArguments(["appId": .string(appID)]), in: context)
    }

    @Test func returnsTheTermsTypesAndPurposes() async throws {
        let outcome = try await call()
        let types = try #require(outcome.result["dataTypes"]?.arrayValue)
        #expect(types.count == 35)
        let expected: JSONValue = [
            "id": "name", "name": "Name", "category": "Contact Info", "fastlaneKey": "NAME", "manifestKey": "NSPrivacyCollectedDataTypeName",
        ]
        #expect(types.first == expected)
        #expect(outcome.result["purposes"]?.arrayValue?.compactMap { $0["id"]?.stringValue } == PrivacyPurpose.allCases.map(\.rawValue))
        #expect(outcome.result["definitions"]?["tracking"]?.stringValue?.contains("data broker") == true)
        #expect(outcome.result["worksheet"]?["collects"] == .null)
        #expect(GetPrivacyQuestionnaireTool().definition.isReadOnly)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · App Privacy", outcome: .read)])
    }

    @Test func itStartsAScanOnThePage() async throws {
        _ = try await call()
        let worksheet = services.privacy.worksheet(for: "6450000001")
        #expect(worksheet.runningScan?.assistant == "Claude Code")
    }

    @Test func theWorksheetSaysWhoAnswered() async throws {
        services.privacy.update("6450000001") { worksheet in
            worksheet.setCollects(true)
            worksheet.edit(.email, to: PrivacyAnswer(collected: true, purposes: [.appFunctionality], linked: true))
        }
        let outcome = try await call()
        let answers = try #require(outcome.result["worksheet"]?["answers"]?.arrayValue)
        #expect(answers.first?["type"] == "email")
        #expect(answers.first?["answeredBy"] == "the person")
        #expect(answers.first?["purposes"] == ["APP_FUNCTIONALITY"])
        #expect(outcome.result["worksheet"]?["collects"] == true)
    }

    @Test func anUnknownAppIsNotFound() async {
        await #expect(throws: MCPToolError.self) { try await call("Nope") }
    }
}
#endif
