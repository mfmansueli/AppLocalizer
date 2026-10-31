//
//  SuggestionsDebugData.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The design's suggestions for Lumen Journal 1.4 that don't come from the
/// built-in checks: Claude Code's What's New, promotional text and subtitle
/// in English and What's New in German, the AI provider's German keywords,
/// and Claude Code's secondary category and App Review notes. The built-in
/// ones (keywords, URLs, copyright, contact phone) come from the checks
/// when the pages load.
@MainActor
enum SuggestionsDebugData {
    static let client = StorePageSampleData.assistantClient
    static var appID: StoreApp.ID { DebugFixtures.AppID.lumen }

    /// A store with the assistant's and the AI provider's suggestions, or
    /// none for the built-in-only scenes; with `includesCodeAnswers`, also
    /// Claude Code's Age Rating and Accessibility answers (board 19).
    static func store(includesAssistant: Bool = true, includesCodeAnswers: Bool = false) -> FieldSuggestionStore {
        let store = FieldSuggestionStore()
        guard includesAssistant else { return store }
        for item in storePage + appInformation + (includesCodeAnswers ? codeAnswers : []) {
            store.add(appID: appID, target: item.target, value: item.value, reason: item.reason, source: item.source)
        }
        return store
    }

    /// The Age Rating questions Claude Code answers in `in-age`.
    static let ageRatingAnswers: [AgeRatingQuestion] = [.wellness, .webAccess, .userGeneratedContent, .messaging, .parentalControls, .ageAssurance]

    /// "Ask Claude Code…" was clicked: the prompt is out and two of four
    /// suggestions have arrived.
    static func streamingStore() -> FieldSuggestionStore {
        let store = FieldSuggestionStore()
        let prompt = SuggestionPrompt.text(for: .storePage, app: StorePageSampleData.appName, version: "1.4", primaryLanguage: StoreLocale.englishUS.name)
        store.beginRequest(appID: appID, area: .storePage, client: client, prompt: prompt)
        store.noteExpectedTotal(4, client: client, appID: appID)
        for item in storePage.prefix(2) {
            store.add(appID: appID, target: item.target, value: item.value, reason: item.reason, source: item.source)
        }
        return store
    }

    // MARK: - Suggest Everything

    /// Board 20's run for Lumen 1.4: five Store Page fields, the secondary
    /// category, six Age Rating questions, five accessibility features and
    /// the App Review notes, in the order the plan lists them.
    static var runPlan: [SuggestionTarget] {
        let order = SuggestionPage.allCases
        return runItems.map(\.target).sorted { lhs, rhs in
            (order.firstIndex { $0 == SuggestionPage(lhs.scope) } ?? 0) < (order.firstIndex { $0 == SuggestionPage(rhs.scope) } ?? 0)
        }
    }

    /// Suggest Everything receiving: Claude Code announced `runPlan` and
    /// sent the first `arrived` of its suggestions (9 is "9 of 18": English
    /// 3/3, General, 2 Age Rating answers, iPhone and one Apple Watch
    /// feature, and the notes; 12 adds German, a question and a feature).
    /// `now` dates what arrives.
    static func runStore(arrived: Int, now: @escaping () -> Date = Date.init) -> FieldSuggestionStore {
        let store = FieldSuggestionStore(now: now)
        let prompt = SuggestEverythingScope(appName: StorePageSampleData.appName, versionString: "1.4").prompt
        store.beginRun(appID: appID, client: client, prompt: prompt)
        let run = store.startRun(appID: appID, client: client, plan: runPlan)
        for item in runItems.prefix(arrived) {
            addRunItem(item, to: store, runID: run.id)
        }
        return store
    }

    /// Sends the run's next suggestion, e.g. the last one, which finishes it.
    static func sendNextRunItem(to store: FieldSuggestionStore) {
        guard let run = store.run, let item = runItems.first(where: { !run.arrived.contains($0.target) }) else { return }
        addRunItem(item, to: store, runID: run.id)
    }

    private static func addRunItem(_ item: Item, to store: FieldSuggestionStore, runID: SuggestionRun.ID) {
        store.add(appID: appID, target: item.target, value: item.value, reason: item.reason, source: item.source, runID: runID)
    }

    /// In the order Claude Code sends them.
    private static var runItems: [Item] {
        let all = storePage + appInformation + codeAnswers + [japaneseWhatsNew]
        let order: [SuggestionTarget] = [
            .storePage(.englishUS, .whatsNew),
            .storePage(.englishUS, .promotionalText),
            .storePage(.englishUS, .subtitle),
            .appInformation(.secondaryCategory),
            AppInformationSuggestionSlot.ageRating(.wellness).target,
            AppInformationSuggestionSlot.ageRating(.webAccess).target,
            AppInformationSuggestionSlot.accessibility(.iPhone, .reducedMotion).target,
            AppInformationSuggestionSlot.accessibility(.appleWatch, .voiceOver).target,
            .appInformation(.notes),
            .storePage(.german, .whatsNew),
            AppInformationSuggestionSlot.ageRating(.userGeneratedContent).target,
            AppInformationSuggestionSlot.accessibility(.appleWatch, .largerText).target,
            AppInformationSuggestionSlot.ageRating(.messaging).target,
            .storePage(.japanese, .whatsNew),
            AppInformationSuggestionSlot.ageRating(.parentalControls).target,
            AppInformationSuggestionSlot.ageRating(.ageAssurance).target,
            AppInformationSuggestionSlot.accessibility(.appleWatch, .differentiateWithoutColor).target,
            AppInformationSuggestionSlot.accessibility(.appleWatch, .reducedMotion).target,
        ]
        return order.compactMap { target in all.first { $0.target == target } }
    }

    private static var japaneseWhatsNew: Item {
        Item(
            .storePage(.japanese, .whatsNew),
            """
            • 週ごとのふりかえり：毎週日曜日に、あなたの一週間を穏やかにまとめます
            • 何年分もの記録をすばやく検索
            • 古いデバイスでのiCloud同期を修正
            """,
            "Translated from the English suggestion with your glossary.",
            .assistant(client: client)
        )
    }

    private struct Item {
        var target: SuggestionTarget
        var value: String
        var reason: String
        var source: SuggestionSource

        init(_ target: SuggestionTarget, _ value: String, _ reason: String, _ source: SuggestionSource) {
            self.target = target
            self.value = value
            self.reason = reason
            self.source = source
        }
    }

    private static var storePage: [Item] {
        [
            Item(
                .storePage(.englishUS, .whatsNew),
                """
                • Weekly reflections: a calm summary of your week, every Sunday
                • Faster search across years of entries
                • Fixes iCloud sync on older devices
                """,
                "Written from the 23 commits since the v1.3 tag in northpier/lumen. Internal changes are left out.",
                .assistant(client: client)
            ),
            Item(
                .storePage(.englishUS, .promotionalText),
                "Weekly reflections are here: your best moments, gathered on one calm page every Sunday.",
                "Promotional text can change without a new review. This announces 1.4’s main feature, from CHANGELOG.md.",
                .assistant(client: client)
            ),
            Item(
                .storePage(.englishUS, .subtitle),
                "Private diary, mood & prompts",
                "“Private” is the word people praise most in your last 220 reviews (41 times).",
                .assistant(client: client)
            ),
            Item(
                .storePage(.german, .whatsNew),
                """
                • Wochenrückblick: eine ruhige Zusammenfassung deiner Woche, jeden Sonntag
                • Schnellere Suche über Jahre an Einträgen
                • Behebt die iCloud-Synchronisierung auf älteren Geräten
                """,
                "Translated from the English suggestion with your glossary (“Eintrag”, informal “du”).",
                .assistant(client: client)
            ),
            Item(
                .storePage(.german, .keywords),
                "tagebuch,stimmung,dankbarkeit,reflexion,schreiben,achtsamkeit,gewohnheit,erinnerungen,journal",
                "Many German searches use the English word “journal”. It fits in the 15 bytes left.",
                .aiProvider
            ),
        ]
    }

    /// Claude Code's answers from the code: six Age Rating questions,
    /// Reduced Motion on iPhone, and four features on Apple Watch.
    private static var codeAnswers: [Item] {
        let age: [(AgeRatingQuestion, AgeRatingAnswer, String)] = [
            (
                .wellness,
                .affirmative,
                "Mood tracking and mindfulness prompts are wellness features (MoodView.swift, Prompts/mindful.json). Lumen gives no medical advice."
            ),
            (.webAccess, .negative, "The only web view opens Lumen’s own help pages (HelpView.swift, lumen.example/help)."),
            (.userGeneratedContent, .negative, "Entries stay in each person’s private iCloud database. Nothing is shared with other people."),
            (.messaging, .negative, "No messaging between people anywhere in the code."),
            (.parentalControls, .negative, "No parental controls or content restrictions in the app."),
            (.ageAssurance, .negative, "Lumen doesn’t ask for or check anyone’s age."),
        ]
        let features: [(DeviceFamily, AccessibilityFeature, String)] = [
            (.iPhone, .reducedMotion, "All 4 animated views check Reduce Motion (accessibilityReduceMotion) and switch to fades."),
            (.appleWatch, .voiceOver, "All 11 controls in LumenWatch have accessibility labels, and the mood picker reads its value."),
            (.appleWatch, .largerText, "The watch app uses text styles only, no fixed font sizes."),
            (.appleWatch, .differentiateWithoutColor, "Mood levels use a shape and a label as well as color, as on iPhone."),
            (.appleWatch, .reducedMotion, "The only animation, the ring fill, respects Reduce Motion."),
        ]
        return age.map { Item(AppInformationSuggestionSlot.ageRating($0.0).target, $0.1.rawValue, $0.2, .assistant(client: client)) }
            + features.map {
                Item(AppInformationSuggestionSlot.accessibility($0.0, $0.1).target, AppInformationSuggestionSlot.supported, $0.2, .assistant(client: client))
            }
    }

    private static var appInformation: [Item] {
        [
            Item(
                .appInformation(.secondaryCategory),
                "PRODUCTIVITY",
                "Lumen has no HealthKit or health features in the code, and 1.4 adds weekly reflections and a planner.",
                .assistant(client: client)
            ),
            Item(
                .appInformation(.release),
                ReleaseOption.afterApproval.rawValue,
                "1.1, 1.2 and 1.3 were each released by hand within an hour of approval.",
                .assistant(client: client)
            ),
            Item(
                .appInformation(.notes),
                """
                Lumen Plus is an auto-renewable subscription; sandbox purchases work in the review environment.

                To see Weekly Reflections (new in 1.4) without waiting a week: Settings → Debug → Add Sample Week. \
                The Debug menu only appears in review and TestFlight builds.
                """,
                "Weekly Reflections needs 7 days of entries. DebugMenu.swift adds a sample week in review builds.",
                .assistant(client: client)
            ),
        ]
    }
}
#endif
