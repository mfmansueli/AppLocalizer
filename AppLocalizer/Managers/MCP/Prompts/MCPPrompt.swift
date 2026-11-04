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
    /// What "Ask Claude Code…" copies, with the area as an argument.
    case suggest
    /// What Suggest Everything… copies: every field, as one run.
    case suggestAll = "suggest_all"
    /// What Start Autopilot copies: drive the Screenshot Autopilot run.
    case runScreenshots = "run_screenshots"

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
        case .suggest: "Suggest field values"
        case .suggestAll: "Suggest everything"
        case .runScreenshots: "Run Screenshot Autopilot"
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
        case .suggest: String(localized: "Suggest Store Page or App Information values for the person to accept")
        case .suggestAll: String(localized: "Suggest every Store Page and App Information field the code can answer")
        case .runScreenshots: String(localized: "Capture the app in Simulator for the screenshot run the person started, step by step")
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
        case .suggest: ["list_apps", "get_store_page", "get_app_information", "suggest_fields"]
        case .suggestAll: ["list_apps", "get_store_page", "get_app_information", "begin_suggestions", "suggest_fields", "end_suggestions"]
        case .runScreenshots: [
                "list_apps", "get_capture_plan", "update_capture_plan", "report_capture", "report_capture_problem", "next_step",
                "get_design_brief", "propose_direction", "revise_direction", "propose_captions", "report_app_support",
                "start_display_recording", "finish_display_recording", "propose_screens", "revise_app_preview", "render_artwork",
            ]
        }
    }

    /// The `prompts/list` entry.
    var json: JSONValue {
        var arguments: [JSONValue] = [
            [
                "name": "app",
                "description": "The app's name, bundle ID or Apple ID. Leave it out when the project folder makes it clear.",
                "required": false,
            ],
        ]
        if self == .suggest {
            arguments.insert(
                ["name": "area", "description": "store (Store Page text) or info (App Information and App Review).", "required": false],
                at: 0
            )
        }
        return [
            "name": .string(name),
            "title": .string(title),
            "description": .string(summary),
            "arguments": .array(arguments),
        ]
    }

    /// The `prompts/get` result for the app the person named; `area` is
    /// `suggest`'s.
    func message(app: String?, area: String? = nil) -> JSONValue {
        let appPhrase = app.map { "the app “\($0)”" } ?? "the app this project builds (find it with list_apps)"
        let text = self == .suggest
            ? Self.suggestInstructions(appPhrase: appPhrase, area: area.flatMap(SuggestionArea.init(rawValue:)))
            : instructions(appPhrase: appPhrase)
        return [
            "description": .string(summary),
            "messages": [
                ["role": "user", "content": ["type": "text", "text": .string(text)]],
            ],
        ]
    }

    /// `suggest`: what the Ask popover copies, with how to send the
    /// suggestions.
    private static func suggestInstructions(appPhrase: String, area: SuggestionArea?) -> String {
        let what = switch area {
        case .storePage:
            "Store Page text: What’s New, promotional text and subtitle, in the primary language and in every language that has a translation"
        case .appInformation:
            "App Information and App Review details, from the code"
        case nil:
            "Store Page text (What’s New, promotional text, subtitle) and App Information and App Review details"
        }
        return """
        Suggest \(what) for \(appPhrase) in AppLocalizer. Call list_apps to get its appId, then get_store_page \
        (each language's texts, the limits in characters or bytes, and the suggestions already open, so you don't \
        repeat them) and get_app_information (copyright, categories, release and App Review contact and notes). \
        Read the project: git log since the last release tag for What’s New, the README and the app's strings for \
        promotional text and subtitles, and the code for App Review notes such as sign-in, demo data and hidden \
        features. If App Review's contact (first name, last name, phone, email) is empty, suggest it from what \
        the project shows, such as a support or contact email in the app or its docs, or the git author (git \
        config user.name and user.email), with that as evidence; leave out what you can't find, and never make \
        up a phone number. Send them with suggest_fields, one item per field with the value, a one-sentence \
        reason and evidence (git range, file and line, or review), and pass total with how many you'll send in \
        all. If an \
        item is refused, read the reason (over_limit gives the count), fix it and send it again. Nothing changes \
        until the person accepts each suggestion in AppLocalizer.
        """
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
        case .suggest:
            Self.suggestInstructions(appPhrase: appPhrase, area: nil)
        case .suggestAll:
            """
            Suggest everything for \(appPhrase) in AppLocalizer: every Store Page field in every language, \
            including languages the app supports that aren’t on the App Store yet, and App Information's General, \
            Age Rating, Accessibility for each device, and App Review. Call list_apps to get its appId. Read the \
            project's targets, devices and string catalogs and send them with report_app_support first, so \
            AppLocalizer knows the languages the App Store page lacks. Then call get_store_page and \
            get_app_information: they say which fields are locked, which the person changed (a `live` value that \
            differs), the suggestions already open, and `languagesNotOnAppStore`, the languages to suggest every \
            field for as new pages (they stay suggestions until the person adds the page). Read the \
            project: git log since the last release tag, CHANGELOG.md, the README and the app's strings for \
            the Store Page, and the code for categories, App Review notes (sign-in, demo data, hidden features), \
            Age Rating's questions (user-generated content, web access, messaging, purchases) and each device's \
            Accessibility features (VoiceOver labels, Dynamic Type, Dark Mode, Reduce Motion, captions), \
            answering only what the code shows. If App Review's contact (first name, last name, phone, email) is \
            empty, suggest it from what the project shows, such as a support or contact email in the app or its \
            docs, or the git author (git config user.name and user.email), with that as evidence; leave out what \
            you can't find, and never make up a phone number. Then call begin_suggestions with your plan, one \
            entry {area, locale | page, device, field} per field you'll suggest, leaving out locked fields and the ones the \
            person changed; it returns a run and the entries it skipped. Send the suggestions with suggest_fields \
            and that run, in as many calls as you like, each with the value, a one-sentence reason and evidence \
            (git range, file and line, or review). If an item is refused, read the reason, fix it and send it \
            again; run_stopped means the person stopped receiving, so stop. Call end_suggestions when you're \
            done. Nothing changes until the person accepts each suggestion in AppLocalizer.
            """
        case .runScreenshots:
            Self.runScreenshotsInstructions(appPhrase: appPhrase)
        }
    }

    /// `run_screenshots`: drive the Autopilot run the person started.
    private static func runScreenshotsInstructions(appPhrase: String) -> String {
        """
        Run the Screenshot Autopilot plan the person started in AppLocalizer for \(appPhrase). Call list_apps for \
        its appId, then get_capture_plan (pass xcode and simulators): it gives the screens and the steps to reach \
        each, the devices, locales with their launch arguments, simulator setup commands and an upload URL. When \
        chooseScreens is true, decide first which screens show the app best: read the project (its views and \
        navigation, onboarding, UI tests, the App Store description) and pick its strongest moments, strongest \
        first and the first saying what the app is for: usually 5 to 8 on iPhone and iPad (at most 10), 3 or 4 \
        of the watch app's, and 3 Apple Vision Pro windows. Send them with update_capture_plan replace: true, \
        each with the steps to reach it and a short caption. Otherwise keep the plan's screens; if they lack \
        steps, write them from the project's UI tests, deep links or launch arguments and send them with \
        update_capture_plan. A screen whose steps are "auto" was added by the person by name: work out how to \
        reach it, add it to the UI tests and send its steps; screens addedBy the person stay when you replace. \
        List the watch app's screens and the Apple Vision Pro windows there too \
        (device watch or vision) when the plan has those devices. If you haven't told AppLocalizer what the \
        project supports, call report_app_support first (targets, devices, and every language in its string \
        catalogs). Go through the plan's preflight checks in the project and fix what fails before capturing \
        (UI tests that find buttons by their English title, sample data in one language). Build the app with \
        xcodebuild, boot each simulator (pair the watch with the iPhone), run the \
        setup commands, and for each device and locale launch the app with its arguments, reach each screen and \
        capture it (up to 3 times); locales marked notOnAppStoreYet are captured too. On iPhone Duo, a UI \
        test's own screenshot is the cover display: call start_display_recording before each UI test there and \
        finish_display_recording after it, which gives the inner display's screenshots as upload IDs. \
        Upload each PNG with curl --data-binary to the upload URL and call report_capture with the returned \
        upload ID, the attempt, a score from 0 to 1 and notes saying why. When a screen can't be reached, call \
        report_capture_problem with what happened and a fix (changesProject: true, once, when the fix is a \
        change to the project), and go on. next_step gives the rehearsal first: every screen in the primary \
        language and one other, before the rest. After each step call next_step and do \
        what it says: capture, wait (ask again after retryAfterSeconds), design (get_design_brief, then \
        propose_direction with templates in AppLocalizer's format, designed with the connected design project, \
        and the header and search as your own HTML pages when the brief has artworkDesign, tried with \
        render_artwork, only the pages when it says noScreenshots; report what you find in it with \
        report_design_source), revise_direction, write_captions (then \
        propose_captions with run), revise_app_preview (the person's note on the App Preview, then \
        revise_app_preview with the new cut), or suggest_screens (then propose_screens with run). Stop when it \
        says done. \
        The App Preview's music is the person's choice: change it with set_app_preview_music only when they ask. \
        Never draw the interface; use the real captures. \
        Nothing is uploaded to App Store Connect until the person pushes in AppLocalizer.
        """
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
