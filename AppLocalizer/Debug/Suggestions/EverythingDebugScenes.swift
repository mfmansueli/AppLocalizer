//
//  EverythingDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Board 20 of the design: Suggest Everything with Claude Code.
/// - `ev-start`: Overview's entry points; `ev-pop`: the Assistant button's
///   popover with Suggest Everything….
/// - `ev-wait`, `ev-busy`: the prompt copied and waiting, alone or while a
///   per-page Ask still sends.
/// - `ev-run`, `ev-run-store`, `ev-run-info`, `ev-run-pop`: 9 of 18 on
///   Overview, German on the Store Page, Age Rating, and the Assistant
///   button's Show Progress.
/// - `ev-quiet`: nothing for 3 minutes; `ev-done`: the last one arrives
///   and the toast gives the total; `ev-stopped`: Stop Receiving at 12.
/// - `ev-key`: only an API key; `ev-none`: setup, saying why.
enum EverythingDebugScenes {
    static let ids = [
        "ev-start", "ev-pop", "ev-wait", "ev-busy",
        "ev-run", "ev-run-store", "ev-run-info", "ev-run-pop",
        "ev-quiet", "ev-done", "ev-stopped", "ev-key", "ev-none",
    ]

    @MainActor
    static func view(for id: String) -> AnyView? {
        switch id {
        case "ev-start":
            return overview(SuggestionsDebugData.store())
        case "ev-pop":
            AssistantToolbarIndicator.debugShowsPopover = true
            return overview(SuggestionsDebugData.store())
        case "ev-wait":
            OverviewSectionView.debugRequestsSuggestEverything = true
            return overview(SuggestionsDebugData.store())
        case "ev-busy":
            OverviewSectionView.debugRequestsSuggestEverything = true
            return overview(SuggestionsDebugData.streamingStore())
        case "ev-key":
            return AssistDebugScenes.withKey(DebugMainScene(section: .overview, suggestions: SuggestionsDebugData.store(includesAssistant: false)))
        case "ev-none":
            AssistantSetupSheet.debugReason = AssistantSetupSheet.suggestEverythingReason
            AssistantSetupSheet.debugStep = .assistant
            return AnyView(
                DebugMainScene(section: .overview, suggestions: SuggestionsDebugData.store(includesAssistant: false), presentedSheet: .assistantSetup)
            )
        default:
            return runScene(id)
        }
    }

    /// A run: 9 of 18 on Overview, German's Store Page, Age Rating, or with
    /// the Assistant button's popover open; quiet, finishing, or stopped.
    @MainActor
    private static func runScene(_ id: String) -> AnyView? {
        switch id {
        case "ev-run":
            return overview(SuggestionsDebugData.runStore(arrived: 9))
        case "ev-run-store":
            return SuggestionsDebugScenes.storePage(.connected, store: SuggestionsDebugData.runStore(arrived: 9)) { $0.openEditor(.german) }
        case "ev-run-info":
            return SuggestionsDebugScenes.appInformationScene(page: .ageRating, store: SuggestionsDebugData.runStore(arrived: 9)) {
                $0.showsOnlySuggestedFields = true
            }
        case "ev-run-pop":
            AssistantToolbarIndicator.debugShowsPopover = true
            return SuggestionsDebugScenes.storePage(.connected, store: SuggestionsDebugData.runStore(arrived: 9)) { $0.openEditor(.german) }
        case "ev-quiet":
            let clock = Clock(offset: -3 * 60)
            let store = SuggestionsDebugData.runStore(arrived: 12) { clock.now }
            clock.offset = 0
            return overview(store)
        case "ev-done":
            let store = SuggestionsDebugData.runStore(arrived: 17)
            return AnyView(overview(store).modifier(SendsLast(store: store)))
        case "ev-stopped":
            let store = SuggestionsDebugData.runStore(arrived: 12)
            store.stopRun()
            return overview(store)
        default:
            return nil
        }
    }

    @MainActor
    private static func overview(_ store: FieldSuggestionStore) -> AnyView {
        SuggestionsDebugScenes.with(.connected, DebugMainScene(section: .overview, suggestions: store))
    }

    /// What the store reads as now, set back for `ev-quiet`.
    private final class Clock {
        var offset: TimeInterval

        init(offset: TimeInterval) {
            self.offset = offset
        }

        var now: Date { Date().addingTimeInterval(offset) }
    }

    /// Sends the run's last suggestion a moment after the scene appears, so
    /// it finishes the way a real one does, with the toast.
    private struct SendsLast: ViewModifier {
        let store: FieldSuggestionStore

        func body(content: Content) -> some View {
            content.task {
                try? await Task.sleep(for: .seconds(1))
                SuggestionsDebugData.sendNextRunItem(to: store)
            }
        }
    }
}
#endif
