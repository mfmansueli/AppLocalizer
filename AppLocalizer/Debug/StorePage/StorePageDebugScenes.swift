//
//  StorePageDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// The Store Page section's DEBUG scenes (`-AppLocalizerDebugScene <id>`),
/// named after the design's screenshots. `DebugSceneView` asks here for any
/// id it doesn't know itself. Every scene is Lumen Journal's store page on
/// top of the sample workspace (Habitat's three pending changes):
///
/// - `store-coverage`: the grid, with the German subtitle (over the limit)
///   and the French promotional text already queued.
/// - `store-editor`: the Arabic editor, right to left, with a subtitle
///   over the limit and an invalid support URL queued.
/// - `store-keywords`: the German editor at its keywords, edited to show
///   bytes, a duplicate, words already in the name and wasted spaces.
/// - `store-translate`, `store-translating`, `store-suggestions`: Korean,
///   Chinese (Simplified) and Dutch added; the Translate sheet, the batch
///   stopped at "Korean · Description", and the suggestions with the first
///   three accepted.
/// - `store-iap`: the In-App Texts view.
/// - `store-import`: the translator's XLIFF in the import diff.
/// - `store-find`: Find and Replace, "Lumen Plus" → "Lumen Premium".
/// - `store-noversion`: only the live 1.3 exists.
/// - `store-emptylocale`: Korean just added, open in the editor.
/// - `store-loading`, `store-ratelimited`: the first load never finishes;
///   App Store Connect's rate limit.
enum StorePageDebugScenes {
    static let ids = [
        "store-coverage", "store-editor", "store-keywords", "store-translate", "store-translating", "store-suggestions",
        "store-iap", "store-import", "store-find", "store-noversion", "store-emptylocale",
        "store-loading", "store-ratelimited",
    ]

    @MainActor
    static func view(for id: String) -> AnyView? {
        switch id {
        case "store-translate", "store-translating", "store-suggestions": translationScene(id)
        case "store-noversion": scene(DebugStorePageServices(hasEditableVersion: false))
        case "store-loading": scene(DebugStorePageServices(delay: .seconds(24 * 60 * 60)))
        case "store-ratelimited": scene(DebugStorePageServices(error: .rateLimited))
        default: editingScene(id)
        }
    }

    /// Scenes that open a view, a locale or a sheet on the sample data.
    @MainActor
    private static func editingScene(_ id: String) -> AnyView? {
        switch id {
        case "store-coverage":
            // Coverage is in ⋯ More now; the scene opens on it.
            scene(pending: DebugStorePageContent.pendingChanges(for: StorePageSampleData.listing)) { $0.mode = .coverage }
        case "store-editor":
            scene(pending: DebugStorePageContent.pendingChanges(for: arabicEdits)) { $0.openEditor(.arabic) }
        case "store-keywords":
            scene(pending: DebugStorePageContent.pendingChanges(for: germanKeywords)) { $0.openEditor(.german, field: .keywords) }
        case "store-iap":
            scene { $0.mode = .inAppTexts }
        case "store-import":
            scene { $0.showImport(Data(StorePageSampleData.translatorXLIFF.utf8), fileName: StorePageSampleData.translatorFileName) }
        case "store-find":
            scene { model in
                model.findQuery = FindReplaceQuery(find: "Lumen Plus", replacement: "Lumen Premium")
                model.presentFindReplace()
            }
        case "store-emptylocale":
            scene { $0.addLocale(.korean) }
        default:
            nil
        }
    }

    // MARK: - Scenes

    @MainActor
    static func scene(
        _ storePage: DebugStorePageServices = DebugStorePageServices(),
        pending: [PendingChange] = [],
        opening: (@MainActor (StorePageViewModel) async -> Void)? = nil
    ) -> AnyView {
        var storePage = storePage
        if let opening { storePage.opening = DebugStorePageServices.Opening(opening) }
        var services = WorkspaceServices.debug
        services.storePage = storePage
        return AnyView(DebugMainScene(services: services, section: .storePage, pendingChanges: DebugWorkspace.pendingChanges + pending))
    }

    /// The three translation scenes: locales added, the sample glossary,
    /// then the sheet, the running batch or the finished suggestions.
    @MainActor
    private static func translationScene(_ id: String) -> AnyView {
        var translator = DebugListingTranslator()
        switch id {
        case "store-translating": translator.holdsAt = ListingFieldKey(.korean, .description)
        case "store-suggestions": translator.delay = .zero
        default: break
        }
        return scene(DebugStorePageServices(translator: translator)) { model in
            for locale in StorePageSampleData.addedLocales {
                model.addLocale(locale)
            }
            model.mode = .coverage
            model.translation.glossary = StorePageSampleData.glossary
            model.presentTranslate()
            guard id != "store-translate" else { return }
            await model.translation.checkAvailability()
            model.startTranslation()
            guard id == "store-suggestions" else { return }
            await model.translation.waitUntilFinished()
            for suggestion in model.translation.review?.suggestions.prefix(3) ?? [] {
                model.translation.accept(suggestion.id)
            }
        }
    }

    // MARK: - Edits

    /// The editor screenshot's Arabic subtitle (32 of 30) and support URL
    /// without https://.
    private static var arabicEdits: StoreListing {
        var listing = StorePageSampleData.fetchedListing
        listing.edit(.subtitle, in: .arabic, to: "ملاحظات خاصة وأسئلة لطيفة كل يوم")
        listing.edit(.supportURL, in: .arabic, to: "lumen.example/ar/support")
        return listing
    }

    /// The keyword screenshot's German keywords: 114 of 100 bytes, with a
    /// duplicate, words already in the name and a wasted space.
    private static var germanKeywords: StoreListing {
        var listing = StorePageSampleData.fetchedListing
        listing.edit(
            .keywords,
            in: .german,
            to: "tagebuch, stimmung,dankbarkeit,reflexion,schreiben,achtsamkeit,gewohnheit,erinnerungen,rückblick,notizen,stimmung"
        )
        return listing
    }
}
#endif
