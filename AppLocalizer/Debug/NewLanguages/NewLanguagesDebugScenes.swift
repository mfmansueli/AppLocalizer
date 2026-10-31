//
//  NewLanguagesDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Languages the app supports that its App Store page doesn't have: Lumen
/// Journal's project has Polish, Turkish and Hebrew, and Claude Code drafted
/// their pages.
/// - `sp-newlang`: English (U.S.) with the banner; `sp-newlang-tab`:
///   Polish's tab before it's added; `sp-newlang-added`: Hebrew added with
///   every draft accepted.
/// - `langs-sheet`: "Languages in the app, not on the App Store".
/// - `review-newlang`: Review & Push with "Create the Polish page".
/// - `ov-newlang`: Overview's New languages and Languages lines;
///   `ev-newlang`: Suggest Everything waiting, its scope listing the new
///   pages.
enum NewLanguagesDebugScenes {
    static let ids = ["sp-newlang", "sp-newlang-tab", "sp-newlang-added", "langs-sheet", "review-newlang", "ov-newlang", "ev-newlang"]

    @MainActor
    static func view(for id: String) -> AnyView? {
        switch id {
        case "sp-newlang":
            storePage { $0.openEditor(.englishUS) }
        case "sp-newlang-tab":
            storePage { $0.openEditor(.polish) }
        case "sp-newlang-added":
            storePage { model in
                model.openEditor(.hebrew)
                model.createPage(.hebrew)
                model.acceptAllSuggestions(in: .hebrew)
            }
        case "langs-sheet":
            storePage { model in
                model.openEditor(.englishUS)
                model.presentNewLanguages()
            }
        case "review-newlang":
            SuggestionsDebugScenes.with(.connected, DebugMainScene(
                services: services { $0.openEditor(.polish) },
                section: .storePage,
                pendingChanges: NewLanguagesDebugData.polishChanges(),
                suggestions: NewLanguagesDebugData.store(),
                presentedSheet: .review
            ))
        case "ov-newlang":
            SuggestionsDebugScenes.with(.connected, DebugMainScene(services: services(), section: .overview, suggestions: NewLanguagesDebugData.store()))
        case "ev-newlang":
            everything()
        default:
            nil
        }
    }

    @MainActor
    private static func everything() -> AnyView {
        OverviewSectionView.debugRequestsSuggestEverything = true
        return SuggestionsDebugScenes.with(.connected, DebugMainScene(services: services(), section: .overview, suggestions: NewLanguagesDebugData.store()))
    }

    @MainActor
    private static func storePage(opening: @escaping @MainActor (StorePageViewModel) async -> Void) -> AnyView {
        SuggestionsDebugScenes.with(.connected, DebugMainScene(services: services(opening), section: .storePage, suggestions: NewLanguagesDebugData.store()))
    }

    /// The sample services with Lumen's project languages.
    @MainActor
    private static func services(_ opening: (@MainActor (StorePageViewModel) async -> Void)? = nil) -> WorkspaceServices {
        var storePage = DebugStorePageServices()
        storePage.appSupport = DebugAppSupport.center()
        storePage.opening = opening.map(DebugStorePageServices.Opening.init)
        var services = WorkspaceServices.debug
        services.storePage = storePage
        return services
    }
}
#endif
