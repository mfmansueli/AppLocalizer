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
    /// `CaptionAssistantPrompt.promptName`, which the Translate sheet copies.
    case translateCaptions = "translate_captions"
    case shortenOverflowingCaptions = "shorten_overflowing_captions"
    case reviseTemplate = "revise_template"

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
        case .translateCaptions: "Translate screenshot captions"
        case .shortenOverflowingCaptions: "Shorten overflowing captions"
        case .reviseTemplate: "Revise the screenshot template"
        }
    }

    /// The description Settings shows next to the command.
    var summary: String {
        switch self {
        case .translateMissing: String(localized: "Translate every missing store-page field")
        case .fillPrivacyFromCode: String(localized: "Draft App Privacy from the project")
        case .fillAgeRating: String(localized: "Answer the age rating questionnaire")
        case .whatsNewFromGit: String(localized: "Write What’s New from git history since the last release")
        case .translateCaptions: String(localized: "Translate missing screenshot captions as proposals")
        case .shortenOverflowingCaptions: String(localized: "Propose shorter versions of captions that overflow")
        case .reviseTemplate: String(localized: "Propose a template revision that keeps every locale fitting")
        }
    }

    var requiredTools: Set<String> {
        switch self {
        case .translateMissing: ["list_apps", "list_missing_translations", "get_listing", "propose_listing_text"]
        case .fillPrivacyFromCode: ["list_apps", "get_privacy_questionnaire", "propose_privacy_answers"]
        case .fillAgeRating: ["list_apps", "get_age_rating", "propose_age_rating"]
        case .whatsNewFromGit: ["list_apps", "get_listing", "propose_listing_text"]
        case .translateCaptions: ["list_apps", "get_screenshot_context", "get_captions", "get_capture", "measure_caption", "propose_captions"]
        case .shortenOverflowingCaptions: ["list_apps", "get_captions", "measure_caption", "propose_captions"]
        case .reviseTemplate: ["list_apps", "get_template", "get_captions", "measure_caption", "render_preview", "propose_template"]
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
            Draft the App Privacy answers of \(appPhrase) from this project, with AppLocalizer. Call \
            get_privacy_questionnaire for Apple's definitions, the data type and purpose ids, and the answers already \
            in the worksheet. Read PrivacyInfo.xcprivacy, Package.resolved and the privacy manifests of third-party \
            SDKs, Info.plist usage strings, entitlements, App Tracking Transparency use, and any code that sends data \
            off the device. Call propose_privacy_answers with collects, each data type with its purposes, whether \
            it's linked to the person and used for tracking, a confidence and the evidence (SDK manifest entry, or \
            file and line), and the scan details. Ask in open_questions what the code can't show, such as what a \
            server keeps, with what Yes and No would mean. If an answer is refused, fix it and send it again. \
            Nothing is submitted: the person reviews every answer in AppLocalizer and enters them in App Store Connect.
            """
        case .fillAgeRating:
            """
            Answer the age rating questionnaire of \(appPhrase) from this project, with AppLocalizer. Call \
            get_age_rating for the questions, the answers each takes and the current answers. Look for user-generated \
            content, chat, web access, advertising, gambling, contests, medical or wellness topics, and mature themes \
            in the code and the bundled content. Call propose_age_rating with an answer, why, and evidence (file and \
            line) for each question, and say in could_not_see what you couldn't check. The person confirms every \
            answer in AppLocalizer before it's pushed.
            """
        case .whatsNewFromGit:
            """
            Write the What’s New text of \(appPhrase)'s next version from git history, with AppLocalizer. Find the \
            last release tag and read git log since then. Summarize the changes people will notice in a few short, \
            friendly lines, leaving out internal work. Call get_listing to see the editable version and the primary \
            locale, then propose_listing_text with field whatsNew in the primary locale. Mention which commits you \
            left out and why.
            """
        case .translateCaptions, .shortenOverflowingCaptions, .reviseTemplate:
            screenshotInstructions(appPhrase: appPhrase)
        }
    }

    private func screenshotInstructions(appPhrase: String) -> String {
        switch self {
        case .shortenOverflowingCaptions:
            """
            Use AppLocalizer to fix the screenshot captions of \(appPhrase) that don’t fit. Call list_apps to get \
            its appId, then get_captions and find every caption whose fit says it overflows or shrinks to the \
            smallest size. Write a shorter caption in the same language that keeps the meaning, check it with \
            measure_caption until it fits at full size, and send them together with propose_captions, saying \
            why. If a caption is refused, read how much it’s over and try again. Nothing changes until the \
            person accepts the proposal in AppLocalizer.
            """
        case .reviseTemplate:
            """
            Use AppLocalizer to propose a revision of the screenshot template of \(appPhrase) that keeps every \
            locale’s captions fitting. Call list_apps to get its appId, get_template for the template JSON and \
            its version, and get_captions to see which captions shrink or overflow. Try changes such as a smaller \
            headline size, hyphenation or a narrower device with measure_caption and render_preview (pass them \
            as templatePatch), keeping the primary locale at full size. Then call propose_template with the \
            version you read, the operations and why. The person reviews the before and after and accepts it as \
            the next version.
            """
        default:
            """
            Use AppLocalizer to translate the missing screenshot captions of \(appPhrase). Call list_apps to get \
            its appId, then get_screenshot_context for the slots, the locales in scope and the primary captions, \
            and get_captions to find the slots without a caption. Use get_capture to see the screen a caption \
            describes. Write natural, short marketing captions in each language, keep brand names untranslated, \
            check each with measure_caption until it fits, and send them with propose_captions, one call per \
            locale, saying why. If an item is refused, read how much it’s over, shorten it and propose again. \
            The person accepts or rejects them in AppLocalizer; nothing is pushed.
            """
        }
    }
}
