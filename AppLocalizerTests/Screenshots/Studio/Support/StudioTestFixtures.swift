//
//  StudioTestFixtures.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
@testable import AppLocalizer

/// Lumen Journal's App Store preview pieces for the Studio tests: the
/// standard sample's matrix and live sets (with variants), preview
/// builders on them, an Autopilot center of the test's own with a fixed
/// clock, and a loaded Screenshots view model whose `studio` uses it.
@MainActor
enum StudioTestFixtures {
    static let app = ScreenshotsTestFixtures.app
    /// The Studio scenes' clock: Oct 31, 14:32.
    static let now = StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 32)
    static let slotNames = ScreenshotsSampleData.slotNames

    // MARK: - Matrix and live sets

    /// The standard sample with its live sets, built once.
    static let matrix = ScreenshotsTestFixtures.matrix(ScreenshotsDebugDocuments.standard)

    static var live: LiveScreenshots { ScreenshotsDebugDocuments.live }

    /// The live sets without iPad: the App Store shows iPhone's on iPad.
    static var iPhoneOnlyLive: LiveScreenshots {
        var live = Self.live
        live.screenshotSets.removeAll { $0.displayType == .iPad }
        return live
    }

    /// The live sets without English (U.K.)'s hand-uploaded ones: all made
    /// with the template.
    static var templateOnlyLive: LiveScreenshots {
        var live = Self.live
        live.screenshotSets.removeAll { $0.locale == "en-GB" }
        return live
    }

    /// The standard sample's matrix against other live sets.
    static func matrix(live: LiveScreenshots) -> ScreenshotMatrix {
        ScreenshotMatrixBuilder().build(ScreenshotsTestFixtures.snapshot(ScreenshotsDebugDocuments.standard, live: live))
    }

    /// The standard matrix with only its first `count` failed cells still
    /// failing; the others wait in Review & Push.
    static func matrix(failing count: Int) -> ScreenshotMatrix {
        var matrix = Self.matrix
        for cell in matrix.failedCells.dropFirst(count) {
            matrix.cells[cell.key]?.state = .notPushed
        }
        return matrix
    }

    /// "Lumen · Caption above device".
    static var templateName: String? { ScreenshotsDebugDocuments.standard.template?.name }

    // MARK: - Builders

    /// The preview of the standard sample, with no store texts or run.
    static func builder(
        locale: String = "en-US",
        displayType: ScreenshotDisplayType = .iPhone,
        choice: StudioSetChoice = .live
    ) -> StudioPreviewBuilder {
        StudioPreviewBuilder(
            displayType: displayType, locale: locale, primaryLocale: .englishUS, choice: choice, matrix: matrix, live: live,
            slotNames: slotNames, storeTexts: StudioStoreTexts(), appName: app.name, templateName: templateName, run: nil
        )
    }

    /// Store texts whose languages are `codes`, with no names.
    static func storeTexts(_ codes: [String]) -> StudioStoreTexts {
        var texts = StudioStoreTexts()
        texts.locales = codes.compactMap { StoreLocaleCatalog.locale(code: $0) }
        return texts
    }

    // MARK: - Autopilot

    /// A center without persistence that holds its stages, on the scenes'
    /// clock, with `run` installed.
    static func center(_ run: AutopilotRun? = nil, project: DesignProject? = nil) -> AutopilotCenter {
        let center = AutopilotCenter()
        center.holdsStages = true
        center.now = { now }
        if let project { center.setDesignProject(project, for: app.id) }
        if let run { center.install(run) }
        return center
    }

    /// A loaded Screenshots view model on `document` and the sample live
    /// sets, with `center` as its Autopilot. Keep it while using its
    /// `studio`, which doesn't own it.
    static func screenshots(
        center: AutopilotCenter?,
        document: ScreenshotsDocument = ScreenshotsDebugDocuments.standard,
        live: LiveScreenshots = live,
        support: AppSupportCenter? = nil,
        hasVisionVersion: Bool = false,
        hasWatchApp: Bool = false,
        hasMacVersion: Bool = false
    ) async -> ScreenshotsViewModel {
        let services = StudioTestServices(document: document, live: live, autopilot: center)
        services.appSupport = support
        var context = ScreenshotsContext(primaryLocale: .englishUS, version: ScreenshotsTestFixtures.editableVersion)
        context.hasVisionVersion = hasVisionVersion
        context.hasWatchApp = hasWatchApp
        context.hasMacVersion = hasMacVersion
        let model = ScreenshotsViewModel(app: app, services: services, context: context)
        await model.load()
        model.renderQueue.cancel()
        return model
    }
}
#endif
