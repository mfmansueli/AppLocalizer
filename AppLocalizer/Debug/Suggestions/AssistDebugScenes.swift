//
//  AssistDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Board 19 of the design: suggestions from an API key, and Claude Code's
/// Age Rating and Accessibility answers.
/// - `setup-key-1` … `setup-key-done`: the setup sheet with a key, its
///   check (and a rejected key), what requests include, and the test.
/// - `sp-key`, `sp-key-ask`: Store Page with a key, and Generate
///   Suggestions… open; `asst-pop-key`: the Assistant button's popover.
/// - `in-age`, `in-age-done`: Age Rating's suggested answers, then
///   accepted; `in-key`: Age Rating with a key, which doesn't read code.
/// - `in-ax`, `in-ax-iphone`: Accessibility's suggestions for Apple Watch
///   and iPhone.
enum AssistDebugScenes {
    static let ids = [
        "setup-key-1", "setup-key-2", "setup-key-bad", "setup-key-3", "setup-key-done",
        "sp-key", "sp-key-ask", "asst-pop-key",
        "in-age", "in-age-done", "in-key", "in-ax", "in-ax-iphone",
    ]

    /// The design's key, long enough for the canned service to accept.
    static let key = "sk-ant-api03-7Hd2kQ9xLmP4vR8sT1wY6zN3bF5gJ0cE4f2Q"
    /// Too short: the canned service rejects it (401).
    static let rejectedKey = "sk-ant-api03-7Hd2kQ9x"

    @MainActor
    static func view(for id: String) -> AnyView? {
        if id.hasPrefix("setup-key-") { return setupScene(id) }
        switch id {
        case "sp-key":
            return withKey(SuggestionsDebugScenes.storePage(.off, store: keyStore()) { $0.openEditor(.englishUS) })
        case "sp-key-ask":
            return withKey(SuggestionsDebugScenes.storePage(.off, store: keyStore()) { model in
                model.openEditor(.englishUS)
                model.requestsAsk = true
            })
        case "asst-pop-key":
            AssistantToolbarIndicator.debugShowsPopover = true
            return withKey(DebugMainScene(section: .overview, suggestions: keyStore()))
        case "in-age":
            return SuggestionsDebugScenes.appInformationScene(page: .ageRating, store: codeStore()) { $0.showsOnlySuggestedFields = true }
        case "in-age-done":
            return SuggestionsDebugScenes.appInformationScene(page: .ageRating, store: codeStore()) { model in
                model.acceptAllSuggestions(in: .appInformation(.ageRating))
            }
        case "in-key":
            return withKey(SuggestionsDebugScenes.appInformationScene(page: .ageRating, state: .off, store: keyStore()) {
                $0.showsOnlySuggestedFields = true
            })
        case "in-ax", "in-ax-iphone":
            let family: DeviceFamily = id == "in-ax" ? .appleWatch : .iPhone
            return SuggestionsDebugScenes.appInformationScene(page: .accessibility, store: codeStore()) { $0.accessibilitySuggestionFamily = family }
        default:
            return nil
        }
    }

    // MARK: - Setup

    @MainActor
    private static func setupScene(_ id: String) -> AnyView? {
        let step: AssistantSetupStep
        switch id {
        case "setup-key-1": step = .assistant
        case "setup-key-2", "setup-key-bad": step = .server
        case "setup-key-3": step = .snippet
        case "setup-key-done": step = .test
        default: return nil
        }
        AssistantSetupSheet.debugStep = step
        AssistantSetupSheet.debugMethod = .apiKey
        if step != .assistant { AssistantSetupSheet.debugKey = id == "setup-key-bad" ? rejectedKey : key }
        return AnyView(DebugMainScene(section: .overview, suggestions: SuggestionsDebugData.store(includesAssistant: false), presentedSheet: .assistantSetup))
    }

    // MARK: - Stores

    /// Built-in suggestions only: the key's come from Generate.
    @MainActor
    private static func keyStore() -> FieldSuggestionStore {
        SuggestionsDebugData.store(includesAssistant: false)
    }

    @MainActor
    private static func codeStore() -> FieldSuggestionStore {
        SuggestionsDebugData.store(includesCodeAnswers: true)
    }

    // MARK: - The key

    @MainActor
    static func withKey(_ content: some View) -> AnyView {
        AnyView(content.modifier(KeyOn()))
    }

    /// Sets up the design's Anthropic key once the scene appears: Claude
    /// Sonnet 5.5, ~/Developer/Lumen's 23 commits since v1.3 and the 1.4
    /// changelog, reviews, and two recent requests.
    private struct KeyOn: ViewModifier {
        @Environment(KeyAssistantController.self) private var keyAssistant

        func body(content: Content) -> some View {
            content.task { apply() }
        }

        private func apply() {
            guard !keyAssistant.isReady else { return }
            keyAssistant.debugProjectFolder = AssistDebugScenes.projectFolder
            try? keyAssistant.save(
                KeyAssistantConfiguration(
                    vendor: .anthropic,
                    model: AIProviderVendor.claudeModels[0],
                    keySuffix: "",
                    readsProjectFolder: true,
                    projectFolderPath: "~/Developer/Lumen",
                    readsReviews: true,
                    usesKeyForTranslations: false
                ),
                key: AssistDebugScenes.key
            )
            keyAssistant.noteRequest(String(localized: "Test request"), tokens: 400, at: .now.addingTimeInterval(-8 * 60))
            keyAssistant.noteRequest("Store Page · English (U.S.), German", tokens: 9400, at: .now.addingTimeInterval(-2 * 60))
        }
    }

    static let projectFolder = ProjectFolderExcerpt(
        tag: "v1.3",
        commits: (1...23).map { index in
            [
                "Add weekly reflections summary", "Mood tags on entries", "Speed up search index", "Fix iCloud sync on iOS 17",
                "Polish reflection card", "Update German strings",
            ][index % 6] + (index > 6 ? " (\(index))" : "")
        },
        changelog: ChangelogSection(markdown: """
        ## 1.4
        - Weekly reflections: a calm summary of your week, every Sunday.
        - Mood tags on every entry.
        - Search is twice as fast.

        ## 1.3
        - Prompts for days you don’t know what to write.
        """, version: "1.4")
    )
}
#endif
