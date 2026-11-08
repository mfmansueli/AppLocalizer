//
//  ScreenshotStudioModel.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import Observation

/// The Screenshots section's first page: the App Store preview for a
/// device, language and set, the Live set / New set card, and Screenshot
/// Autopilot above them. Renders its shots at preview size on a queue of
/// its own.
@MainActor
@Observable
final class ScreenshotStudioModel {
    @ObservationIgnored unowned let screenshots: ScreenshotsViewModel
    /// The version's languages, names and subtitles. Its names go on the
    /// app's Autopilot run, for the artwork it renders.
    var storeTexts = StudioStoreTexts() {
        didSet { noteStoreNames() }
    }

    /// Nil shows the primary language.
    var localeCode: String?
    /// The device the preview shows. iPhone and iPad follow (and set) the
    /// Sets tab's; Apple Watch and Apple Vision Pro are the Studio's own.
    var device: ScreenshotDisplayType {
        get { ownDevice ?? screenshots.displayType }
        set {
            if newValue.isRendered {
                ownDevice = nil
                screenshots.displayType = newValue
            } else {
                ownDevice = newValue
            }
        }
    }

    private var ownDevice: ScreenshotDisplayType?
    var choice: StudioSetChoice = .live
    var appearance: StoreAppearance = .light
    var isAutopilotPresented = false
    var isDesignProjectPresented = false
    /// The step the Autopilot sheet shows; nil follows the run.
    var viewedStep: AutopilotStage?
    /// "Ask for changes" on Choose a direction.
    var revisionNote = ""
    /// Upload One by Hand…'s file picker, for this problem.
    var uploadingProblem: AutopilotProblem?
    /// Copy Again's confirmation on Capture's waiting step.
    var didCopyPrompt = false
    /// Plan's Show Screens / Hide Screens.
    var showsPlanScreens = true
    /// "+ Add a Screen…"'s form, while it's open.
    var screenDraft: AutopilotScreenDraft?
    /// What the person asks Suggest Screens for, e.g. "one that shows the
    /// streak", per device (iPhone for the set's).
    var screenAsks: [ScreenshotDisplayType: String] = [:]
    /// Suggest Screens copied its prompt (no helper to start Claude Code).
    var didCopySuggestPrompt = false
    /// The full-size viewer over the app or the Autopilot sheet, while
    /// it's open.
    var viewer: StudioViewer?
    /// The viewer marks the part of the header iPhone shows.
    var viewerShowsGuide = false
    /// The template whose preview the viewer shows (the Look step's), so
    /// its language can switch in place.
    var viewerTemplate: TemplateStarter?
    /// The device whose Review & push screenshots the viewer shows, so
    /// their language can switch in place.
    var viewerReviewDevice: ScreenshotDisplayType?
    /// "Ask for changes" on Watch the App Preview.
    var previewNote = ""
    /// The App Preview Watch the App Preview plays; nil is the primary
    /// language on the first device.
    var watchedLocale: String?
    var watchedDevice: ScreenshotDisplayType?
    /// Why the music file the person chose can't be used.
    var musicError: String?
    /// Plays the App Preview at Watch the App Preview and in the viewer.
    let previewPlayer = AppPreviewPlayerModel()
    /// The plan's Expected result box is open.
    var showsArtworkDirection = false
    /// Why the last reference couldn't be added.
    var referenceError: String?
    /// The app icon's colors, for the header templates' previews on the
    /// plan; nil until read (`loadHeaderColors`).
    var headerColors: IconPalette?
    /// Pick's tab; nil is the first the run has.
    var pickTab: AutopilotPickTab?
    /// Pick's device on the Screenshots tab; nil is the first.
    var pickDevice: AutopilotPickDevice?
    /// The recording Pick plays; nil is the first device in the primary
    /// language.
    var pickRecording: AutopilotRecordingTarget?
    /// Plays the raw App Preview recording at Pick and in the viewer.
    let recordingPlayer = AppPreviewPlayerModel()
    /// Where a header or search loop is as it plays in the viewer.
    let artworkLoop = ArtworkLoopClock()
    /// The Claude Code run AppLocalizer started for this Autopilot run.
    var launchedRunID: ClaudeCodeRun.ID?
    /// The guided sheet's own state.
    var guided = GuidedSheetModel()
    /// Starts Claude Code when its helper is saved; the Autopilot sheet
    /// sets it.
    @ObservationIgnored weak var launcher: ClaudeCodeLauncher?
    let renderQueue: ScreenshotRenderQueue
    /// Directions' layouts by direction and version, for their thumbnails.
    @ObservationIgnored var directionLayouts: [String: [ScreenshotLayout]] = [:]

    init(screenshots: ScreenshotsViewModel) {
        self.screenshots = screenshots
        let services = screenshots.services
        let app = screenshots.app
        renderQueue = ScreenshotRenderQueue(
            cache: screenshots.renderQueue.cache,
            holdCount: services.renderHoldCount,
            captureImage: { [services, app] capture, width in await services.captureImage(capture, for: app, pixelWidth: width) },
            liveImage: { [services] screenshot, width in await services.liveImage(screenshot, pixelWidth: width) }
        )
    }

    var app: StoreApp { screenshots.app }
    var primaryLocale: StoreLocale { screenshots.context.primaryLocale }

    // MARK: - Header

    /// Primary first.
    var locales: [StoreLocale] {
        storeTexts.locales.isEmpty ? [primaryLocale] : storeTexts.locales
    }

    var selectedLocale: String {
        get { localeCode ?? primaryLocale.code }
        set { localeCode = newValue }
    }

    /// iPhone, iPhone Duo and iPad, then Mac, Apple Watch and Apple Vision
    /// Pro when the app runs there: the project says so, App Store Connect
    /// has a macOS or visionOS version or watch screenshots, or the set or
    /// plan has them.
    var devices: [ScreenshotDisplayType] {
        var own = Set(appSupport?.profile(for: app.id)?.devices.map(\.displayType) ?? [])
        if screenshots.context.hasVisionVersion { own.insert(.visionPro) }
        if screenshots.context.hasWatchApp { own.insert(.watch) }
        if screenshots.context.hasMacVersion { own.insert(.mac) }
        own.formUnion(run?.plan.displayTypes ?? [])
        own.formUnion(screenshots.document?.displays ?? [])
        own.formUnion(screenshots.live.screenshotSets.filter { !$0.screenshots.isEmpty }.map(\.displayType))
        return ScreenshotDisplayType.studio.filter { $0.isStandard || own.contains($0) }
    }

    var appSupport: AppSupportCenter? { screenshots.services.appSupport }

    /// "Version 1.4 · what people see before they download".
    var subtitle: String {
        String(localized: "Version \(screenshots.context.version.versionString) · what people see before they download")
    }

    // MARK: - Preview

    var builder: StudioPreviewBuilder {
        let document = screenshots.document
        var ownSlotNames: [ScreenshotDisplayType: [String]] = [:]
        for display in ScreenshotDisplayType.studio where display.mayHaveOwnScreens {
            if let screens = document?.screens(on: display) { ownSlotNames[display] = screens.map(\.name) }
        }
        return StudioPreviewBuilder(
            displayType: devices.contains(device) ? device : .iPhone,
            locale: selectedLocale,
            primaryLocale: primaryLocale,
            choice: choice,
            matrix: screenshots.matrix,
            live: screenshots.live,
            slotNames: (0..<max(document?.slotCount ?? 0, 10)).map { document?.slotName($0) ?? String(localized: "Slot \($0 + 1)") },
            ownSlotNames: ownSlotNames,
            storeTexts: storeTexts,
            appName: app.name,
            templateName: document?.template?.name,
            run: run,
            pushedChecksums: Set(document?.pushed.map(\.checksum) ?? [])
        )
    }

    var hasNewSet: Bool { builder.hasNewSet }

    var preview: StudioPreview { builder.preview() }

    var summary: StudioSetSummary {
        StudioSetSummaryBuilder(
            preview: builder,
            templateVersion: screenshots.document?.history?.currentNumber,
            captureCount: screenshots.document?.captures.captures.count ?? 0,
            devices: devices,
            extras: screenshots.document?.extras
        ).summary()
    }

    /// The width a shot renders at: twice the preview's points.
    static func pixelWidth(for display: ScreenshotDisplayType) -> Int {
        switch display {
        case .iPad, .visionPro: 640
        case .iPhoneDuo: 490
        case .watch: 300
        default: 320
        }
    }

    /// Queues the shots' renders and live images.
    func loadImages(for preview: StudioPreview) {
        let width = Self.pixelWidth(for: preview.displayType)
        renderQueue.render(preview.shots.compactMap(\.image.renderJob), pixelWidth: width)
        let lives = preview.shots.compactMap { shot -> LiveScreenshot? in
            if case let .live(live) = shot.image { return live }
            return nil
        }
        renderQueue.loadLive(lives, pixelWidth: width)
    }

    func image(for shot: StudioShot) -> CGImage? {
        switch shot.image {
        case let .render(job): renderQueue.images[job.key] ?? screenshots.renderQueue.images[job.key]
        case let .live(live): renderQueue.liveImages[live.id] ?? screenshots.renderQueue.liveImages[live.id]
        case .none: nil
        }
    }

    /// Sets, Template and Captions.
    func openSets() {
        screenshots.tab = .sets
    }

    // MARK: - Autopilot

    var autopilot: AutopilotCenter? { screenshots.services.autopilot }
    var run: AutopilotRun? { autopilot?.run(for: app.id) }
    var designProject: DesignProject? { autopilot?.designProject(for: app.id) }
    /// Where Start takes the looks from: the design project, the assistant
    /// designing from the app's own design, or AppLocalizer's starters.
    var plannedDesignKind: DesignProjectKind {
        run?.plan.designKind(for: designProject) ?? designProject?.kind ?? .none
    }

    var context: AutopilotContext {
        AutopilotContext(app: app, services: screenshots.services, primaryLocale: primaryLocale)
    }

    /// Run Autopilot…: a plan from the screens the set has, or the run in
    /// progress.
    func runAutopilot() {
        guard let autopilot else { return }
        let support = AutopilotSupport.make(
            profile: appSupport?.profile(for: app.id),
            declined: appSupport?.declinedLanguages[app.id] ?? [],
            storeLocales: locales.map(\.code),
            hasVisionVersion: screenshots.context.hasVisionVersion,
            hasWatchApp: screenshots.context.hasWatchApp,
            hasMacVersion: screenshots.context.hasMacVersion,
            live: screenshots.live
        )
        let plan = AutopilotPlanner.plan(
            document: screenshots.document, live: screenshots.live, primaryLocale: primaryLocale,
            localeCodes: locales.map(\.code), previous: run, support: support
        )
        autopilot.prepare(appID: app.id, versionString: screenshots.context.version.versionString, plan: plan)
        viewedStep = nil
        isAutopilotPresented = true
    }

    func openAutopilot() {
        viewedStep = nil
        isAutopilotPresented = true
    }

    /// Steps the run has reached can be looked at again.
    func canView(_ step: AutopilotStage) -> Bool {
        guard let run else { return step == .plan }
        // Nothing to watch in a run without an App Preview.
        if step == .watchPreview, run.plan.previewDisplays.isEmpty { return false }
        return step.number <= run.stage.number
    }

    /// The run reached Ready: the new set shows.
    func runDidChange(from old: AutopilotStage?, to new: AutopilotStage?) {
        guard old != new else { return }
        // The App Previews Localize made, to watch.
        if new == .watchPreview {
            Task { [screenshots] in await screenshots.reloadDocument() }
        }
        if new == .ready {
            // Held strongly: the task may run after the section closes.
            Task { [screenshots] in
                await screenshots.reloadDocument()
                choice = .new
            }
        }
    }
}
