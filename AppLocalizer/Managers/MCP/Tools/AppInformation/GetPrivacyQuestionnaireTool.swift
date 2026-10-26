//
//  GetPrivacyQuestionnaireTool.swift
//  AppLocalizer
//

import Foundation

/// `get_privacy_questionnaire`: Apple's App Privacy terms (what "collect",
/// "linked" and "tracking" mean, the 35 data types and the six purposes)
/// and the app's worksheet as it stands. Calling it starts a scan on the
/// App Privacy page, so the person sees the assistant at work.
struct GetPrivacyQuestionnaireTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "get_privacy_questionnaire",
        title: "Read the App Privacy questionnaire",
        description: """
        Returns Apple's App Privacy questionnaire for an app: the definitions of collect, linked to the user and \
        tracking, every data type with its id, category, fastlane key and privacy-manifest key, the six purposes, \
        the confidence levels, and the answers already in the app's worksheet (with who gave them). App Store \
        Connect has no API for App Privacy: answers you propose with propose_privacy_answers go into AppLocalizer's \
        worksheet, where the person reviews each one and enters them in App Store Connect themselves. Calling this \
        shows the person that a scan has started.
        """,
        inputSchema: MCPToolDefinition.schema(
            ["appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps.")],
            required: ["appId"]
        ),
        proposalKind: nil
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let app = try await context.workspace.app(matching: arguments.string("appId"))
        let store = context.workspace.services.appInformation.privacy
        store.update(app.id) { $0.beginScan(by: context.clientName, at: Date()) }
        let worksheet = store.worksheet(for: app.id)
        let result: JSONValue = [
            "app": ["appId": .string(app.id), "name": .string(app.name), "bundleId": .string(app.bundleID)],
            "note": """
            App Store Connect has no API for App Privacy. Your answers go into AppLocalizer's worksheet as suggestions; \
            the person reviews each one, then copies them into App Store Connect. Suggestions aren't legal advice.
            """,
            "definitions": [
                "collect": """
                Transmitting data off the device in a way that lets the developer or its third-party partners access it \
                for longer than it takes to serve the request in real time. Data processed only on the device isn't collected.
                """,
                "linked": "Linked to the user: tied to their identity through an account, a device or other details.",
                "tracking": """
                Linking data from this app with data from other companies' apps, websites or offline properties for \
                targeted advertising or advertising measurement, or sharing it with a data broker.
                """,
            ],
            "dataTypes": .array(PrivacyDataType.allCases.map(\.questionnaireJSON)),
            "purposes": .array(PrivacyPurpose.allCases.map { ["id": .string($0.rawValue), "name": .string($0.title)] }),
            "confidence": .object(Dictionary(uniqueKeysWithValues: PrivacyConfidence.allCases.map { ($0.rawValue, JSONValue.string($0.meaning)) })),
            "evidenceKinds": .array(PrivacyEvidenceKind.allCases.map { .string($0.rawValue) }),
            "worksheet": worksheet.questionnaireJSON,
        ]
        return .read(result, target: String(localized: "\(app.name) · App Privacy"))
    }
}
