//
//  ScreenshotStudioModel+PlanExtras.swift
//  AppLocalizer
//

import Foundation

/// What the plan's "Also make · optional" says: who makes the header,
/// search artwork and App Preview, and what each choice means. And the
/// line the plan shows when its screens are hidden.
extension ScreenshotStudioModel {
    /// "Claude Design" with a Claude Design project, the assistant with
    /// another design project, else AppLocalizer.
    func extrasDesigner(client: String) -> String {
        switch designProject?.kind {
        case .some(.claudeDesign): DesignProjectKind.claudeDesign.title
        case .some(.figma), .some(.folder): client
        case .some(.none), nil: "AppLocalizer"
        }
    }

    /// "Made by Claude Design in the chosen direction and checked like the
    /// screenshots. Each waits in Review & Push."
    func extrasNote(client: String) -> String {
        let made = designProject.map { _ in
            String(localized: "Made by \(extrasDesigner(client: client)) in the chosen direction and checked like the screenshots. Each waits in Review & Push.")
        } ?? String(localized: "Made by AppLocalizer’s starters in the chosen direction and checked like the screenshots. Each waits in Review & Push.")
        return made + " " + Self.shownOnNote
    }

    /// Where the header and search artwork show.
    static let shownOnNote = String(localized: "Shown on iOS 27 and iPadOS 27 and later; earlier versions show your screenshots.")

    /// Under the artwork size: why two images.
    static let artworkSizeNote = String(localized: "Two images let each do its job; one image keeps them identical.")

    func artworkDetail(client: String) -> String {
        let header = AutopilotArtworkKind.header.pixelSize.title
        let search = AutopilotArtworkKind.search.pixelSize.title
        let wide = AutopilotArtworkKind.wide.pixelSize.title
        return String(localized: """
        \(extrasDesigner(client: client)) designs them from the same direction: search results show the app doing its core task with a \
        3–5 word headline in each language, the header one feeling or outcome with little or no text. Apple supports \(header) (21:9) \
        for the header and \(search) (3:2) for search results, or one \(wide) (16:9) image for both.
        """)
    }

    func appPreviewDetail(client: String) -> String {
        String(localized: "A 15–30 s video from real Simulator recordings of the plan’s screens, with captions and an end card in the chosen direction. \(client) records, \(extrasDesigner(client: client)) styles it, AppLocalizer assembles and checks it.")
    }

    /// "English (U.S.) only · other languages show it", "Every language (15)".
    func previewLanguagesTitle(_ languages: AutopilotPreviewLanguages, plan: AutopilotPlan) -> String {
        switch languages {
        case .primary:
            let name = StoreLocaleCatalog.locale(code: plan.primaryLocale)?.name ?? primaryLocale.name
            return String(localized: "\(name) only · other languages show it")
        case .all:
            return String(localized: "Every language (\(plan.localeCodes.count))")
        }
    }

    /// "12 screens on iPhone and iPad, from LumenUITests/ScreenshotTests.swift.
    /// Show them to edit how Claude Code reaches each one."
    func planScreensSummary(_ run: AutopilotRun, client: String) -> String {
        let plan = run.plan
        if run.skipsCapture {
            return run.keptDate.map { String(localized: "Nothing to capture in this run: it reuses the \($0) captures and picks.") }
                ?? String(localized: "Nothing to capture in this run.")
        }
        if run.onlyRecords {
            let count = plan.screens.count
            let screens = count == 1 ? String(localized: "1 screen") : String(localized: "\(count) screens")
            return String(localized: "\(screens) to record for the App Preview. Show them to edit how \(client) reaches each one.")
        }
        // The set's screens once, plus Apple Watch's and Apple Vision Pro's own.
        let count = plan.screens.count + plan.displayTypes.filter(\.hasOwnScreens).reduce(0) { $0 + plan.screens(on: $1).count }
        let screens = count == 1 ? String(localized: "1 screen") : String(localized: "\(count) screens")
        let place = plan.writtenFrom.map { String(localized: "\(screens) on \(plan.devicesTitle), from \($0).") }
            ?? String(localized: "\(screens) on \(plan.devicesTitle).")
        return place + " " + String(localized: "Show them to edit how \(client) reaches each one.")
    }
}
