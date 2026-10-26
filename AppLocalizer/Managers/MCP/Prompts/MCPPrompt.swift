//
//  MCPPrompt.swift
//  AppLocalizer
//

import Foundation

/// The prompts the server offers; Claude Code shows each as a slash command,
/// `/mcp__applocalizer__<name>`. Each one tells the assistant what to read
/// in the project and which tools to use, and to report what it couldn't
/// see. A prompt is offered once every tool it relies on is.
enum MCPPrompt: String, CaseIterable, Identifiable, Sendable {
    case translateMissing = "translate_missing"
    case fillPrivacyFromCode = "fill_privacy_from_code"
    case fillAgeRating = "fill_age_rating"
    case whatsNewFromGit = "whats_new_from_git"

    var id: Self { self }
    var name: String { rawValue }

    /// How Claude Code lists it.
    var slashCommand: String {
        "/mcp__\(MCPEndpoint.serverName)__\(name)"
    }

    var title: String {
        switch self {
        case .translateMissing: "Translate missing store text"
        case .fillPrivacyFromCode: "Draft App Privacy from the code"
        case .fillAgeRating: "Answer the age rating questionnaire"
        case .whatsNewFromGit: "Write What’s New from git"
        }
    }

    /// The description Settings shows next to the command.
    var summary: String {
        switch self {
        case .translateMissing: String(localized: "Translate every missing store-page field")
        case .fillPrivacyFromCode: String(localized: "Draft App Privacy from the project")
        case .fillAgeRating: String(localized: "Answer the age rating questionnaire")
        case .whatsNewFromGit: String(localized: "Write What’s New from git history since the last release")
        }
    }

    var requiredTools: Set<String> {
        switch self {
        case .translateMissing: ["list_apps", "list_missing_translations", "get_listing", "propose_listing_text"]
        case .fillPrivacyFromCode: ["list_apps", "get_privacy_draft", "propose_privacy_answers"]
        case .fillAgeRating: ["list_apps", "get_age_rating", "propose_age_rating"]
        case .whatsNewFromGit: ["list_apps", "get_listing", "propose_listing_text"]
        }
    }

    /// The `prompts/list` entry.
    var json: JSONValue {
        [
            "name": .string(name),
            "title": .string(title),
            "description": .string(summary),
            "arguments": [
                [
                    "name": "app",
                    "description": "The app's name, bundle ID or Apple ID. Leave it out when the project folder makes it clear.",
                    "required": false,
                ],
            ],
        ]
    }

    /// The `prompts/get` result for the app the person named.
    func message(app: String?) -> JSONValue {
        let appPhrase = app.map { "the app “\($0)”" } ?? "the app this project builds (find it with list_apps)"
        return [
            "description": .string(summary),
            "messages": [
                ["role": "user", "content": ["type": "text", "text": .string(instructions(appPhrase: appPhrase))]],
            ],
        ]
    }

    private func instructions(appPhrase: String) -> String {
        switch self {
        case .translateMissing:
            """
            Use AppLocalizer to translate the missing store-page fields of \(appPhrase). Call list_apps to get its \
            appId, then list_missing_translations for the editable version. For each missing field, read the source \
            text and the character limit, write a natural translation for that locale that fits the limit, and call \
            propose_listing_text. Keep brand and product names untranslated, as well as any terms in the glossary \
            get_listing returns. If a proposal is refused, read the reason, fix the text and propose again. When \
            you're done, summarize what you proposed and anything you skipped. The person reviews everything in \
            AppLocalizer before it's pushed.
            """
        case .fillPrivacyFromCode:
            """
            Draft the App Privacy answers of \(appPhrase) from this project, with AppLocalizer. Read \
            PrivacyInfo.xcprivacy, Package.resolved and the privacy manifests of third-party SDKs, Info.plist usage \
            strings, entitlements, App Tracking Transparency use, web views, and any chat or AI features. Call \
            get_privacy_draft to see the current draft, then propose_privacy_answers with each data type, its \
            purposes, whether it's linked to the person and used for tracking, and the evidence (file and line) for \
            each. List in couldNotSee what the code can't show, such as data a server collects. Nothing is \
            submitted: the person confirms every answer in AppLocalizer.
            """
        case .fillAgeRating:
            """
            Answer the age rating questionnaire of \(appPhrase) from this project, with AppLocalizer. Call \
            get_age_rating for the questions and current answers. Look for user-generated content, chat, web \
            access, gambling, contests, medical or wellness topics, and mature themes in the code and the bundled \
            content. Call propose_age_rating with an answer and evidence (file and line) for each question, and list \
            in couldNotSee what you couldn't check. The person reviews every answer in AppLocalizer.
            """
        case .whatsNewFromGit:
            """
            Write the What’s New text of \(appPhrase)'s next version from git history, with AppLocalizer. Find the \
            last release tag and read git log since then. Summarize the changes people will notice in a few short, \
            friendly lines, leaving out internal work. Call get_listing to see the editable version and the primary \
            locale, then propose_listing_text with field whatsNew in the primary locale. Mention which commits you \
            left out and why.
            """
        }
    }
}
