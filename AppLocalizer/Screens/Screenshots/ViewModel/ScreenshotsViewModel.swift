//
//  ScreenshotsViewModel.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import Observation

/// Screenshots: the app's screenshot document and what's live,
/// turned into the Sets matrix (built off the main actor), the render
/// queue that fills it, and the bar, banner, viewer and scope sheet around
/// it.
@MainActor
@Observable
final class ScreenshotsViewModel {
    let app: StoreApp
    let services: any ScreenshotsServices
    let renderQueue: ScreenshotRenderQueue
    /// Capture images for the editors' live previews.
    let captureImages: CaptureImageStore
    private(set) var context: ScreenshotsContext
    /// Every App Store locale, in App Store Connect's order.
    let locales: [StoreLocale]

    // MARK: - Loaded state

    private(set) var document: ScreenshotsDocument?
    private(set) var live = LiveScreenshots()
    private(set) var matrix: ScreenshotMatrix = .empty
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    /// The starter cards' previews, once rendered.
    var starterPreviews: [StarterPreview] = []
    /// The fonts templates can use, with fonts uploaded since launch.
    private(set) var fonts: ScreenshotFontCatalog

    // MARK: - Editors

    /// The Template tab.
    @ObservationIgnored lazy var templateEditor = TemplateEditorViewModel(screenshots: self)
    /// The Captions tab.
    @ObservationIgnored lazy var captions = CaptionsViewModel(screenshots: self)
    /// The Captures tab: imports and coverage.
    @ObservationIgnored lazy var captures = CapturesViewModel(screenshots: self)
    /// The Preview tab: the App Store preview and Screenshot Autopilot.
    @ObservationIgnored lazy var studio = ScreenshotStudioModel(screenshots: self)

    // MARK: - Navigation

    var tab: ScreenshotsTab = .sets
    var displayType: ScreenshotDisplayType = .iPhone {
        didSet { if displayType != oldValue { renderVisibleCells() } }
    }

    var thumbnailSize: ThumbnailSize = .medium
    var showsFallbackRows = false
    var viewer: ScreenshotViewerTarget?
    var scopeDraft: LocaleScopeDraft?
    /// Something to say after an action.
    var notice: String?

    init(app: StoreApp, services: any ScreenshotsServices, context: ScreenshotsContext, locales: [StoreLocale] = StoreLocaleCatalog.all) {
        self.app = app
        self.services = services
        self.context = context
        self.locales = locales
        fonts = services.fonts
        renderQueue = ScreenshotRenderQueue(
            cache: ScreenshotRenderCache(directory: services.renderCacheDirectory),
            holdCount: services.renderHoldCount,
            captureImage: { [services, app] capture, width in await services.captureImage(capture, for: app, pixelWidth: width) },
            liveImage: { [services] screenshot, width in await services.liveImage(screenshot, pixelWidth: width) }
        )
        captureImages = CaptureImageStore { [services, app] capture, width in
            await services.captureImage(capture, for: app, pixelWidth: width)
        }
        // A proposal an assistant sends, or one accepted in the Proposals
        // sheet, arrives as a saved document.
        services.documentCenter?.observe(app.id, owner: self) { [weak self] document in
            Task { await self?.adopt(document) }
        }
    }

    // MARK: - Loading

    /// Reads the document and the live sets, then builds the matrix.
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let document = try await services.loadDocument(for: app, primaryLocale: context.primaryLocale)
            self.document = document
            errorMessage = nil
            live = try await services.liveScreenshots(for: app, context: context)
        } catch {
            errorMessage = error.localizedDescription
        }
        await rebuild()
    }

    /// The Store Page loaded another version. Reloads only once the view
    /// has loaded; until then the first load picks the new context up.
    func update(context: ScreenshotsContext) async {
        guard context != self.context else { return }
        self.context = context
        if isLoaded { await load() }
    }

    var isLoaded: Bool { document != nil }

    /// Builds the matrix from the current document off the main actor,
    /// then queues the renders the current display type shows.
    func rebuild() async {
        guard let document else { return }
        let snapshot = ScreenshotsSnapshot(
            document: document, live: live, primaryLocale: context.primaryLocale, locales: locales,
            version: context.version, fonts: fonts
        )
        matrix = await Task.detached(priority: .userInitiated) {
            ScreenshotMatrixBuilder().build(snapshot)
        }.value
        renderVisibleCells()
        if document.template == nil, !document.captures.isEmpty { await renderStarterPreviews() }
    }

    /// Upload Font…: registers the file and adds its family to the fonts
    /// templates can use. Returns the family.
    func uploadFont(from url: URL) async throws -> String {
        let family = try await services.uploadFont(from: url)
        if !fonts.uploaded.contains(family) { fonts.uploaded.append(family) }
        return family
    }

    /// A document saved elsewhere (the Proposals sheet, an assistant's
    /// tool): shown from now on.
    func adopt(_ document: ScreenshotsDocument) async {
        guard isLoaded, document != self.document else { return }
        self.document = document
        await rebuild()
    }

    /// Reads the document again (Autopilot saved a new template version)
    /// and shows it.
    func reloadDocument() async {
        guard isLoaded, let document = try? await services.loadDocument(for: app, primaryLocale: context.primaryLocale) else { return }
        await adopt(document)
    }

    /// Saves the document and rebuilds.
    func commit(_ document: ScreenshotsDocument) async {
        self.document = document
        do {
            try await services.saveDocument(document, for: app)
        } catch {
            notice = String(localized: "Couldn’t save the screenshot settings: \(error.localizedDescription)")
        }
        await rebuild()
    }

    /// Queues the current display type's renders, primary locale first, and
    /// loads the live images its other rows show.
    func renderVisibleCells() {
        let jobs = matrix.renderJobs.filter { $0.layout.canvas.display == displayType }
        renderQueue.render(jobs, pixelWidth: ThumbnailSize.renderPixelWidth(for: displayType))
        let liveShots = matrix.cells.values.compactMap { cell -> LiveScreenshot? in
            guard cell.key.displayType == displayType, case let .live(shot) = cell.image else { return nil }
            return shot
        }
        renderQueue.loadLive(liveShots, pixelWidth: ThumbnailSize.renderPixelWidth(for: displayType))
    }

    // MARK: - Bar

    var hasCaptures: Bool { !(document?.captures.isEmpty ?? true) }
    var hasTemplate: Bool { document?.template != nil }

    /// "12 of 39 locales localized".
    var scopeTitle: String {
        let count = hasCaptures ? (document?.scope.count ?? 1) : 1
        return String(localized: "\(count) of \(locales.count) locales localized")
    }

    /// "40 not pushed · 2 checks failed · both display types".
    var statusText: String {
        guard hasCaptures else { return String(localized: "No captures yet") }
        guard hasTemplate else { return String(localized: "No template yet") }
        var parts = [String(localized: "\(matrix.pendingCount) not pushed")]
        let failed = matrix.failedCells.count
        if failed == 1 { parts.append(String(localized: "1 check failed")) }
        if failed > 1 { parts.append(String(localized: "\(failed) checks failed")) }
        parts.append(String(localized: "both display types"))
        return parts.joined(separator: " · ")
    }

    /// The red count on Captions: captions that overflow on this display
    /// type.
    var overflowingCaptions: Int {
        matrix.overflowingCaptionCount(on: displayType)
    }

    /// S / M / L shows once there's a matrix to size.
    var showsThumbnailSizes: Bool { tab == .sets && hasCaptures && hasTemplate }

    /// Why each display type templates don't render is left out.
    var otherDisplayTypeNotes: [(ScreenshotDisplayType, String)] {
        let notes = services.otherDisplayTypeNotes(for: app)
        return ScreenshotDisplayType.allCases.filter { !$0.isRendered }.compactMap { type in notes[type].map { (type, $0) } }
    }

    /// The canvas size a display type renders at, for the display menu.
    func pixelSize(for display: ScreenshotDisplayType) -> PixelSize {
        let orientation = document?.template?.canvas.orientation(for: display) ?? (display.isTablet ? .landscape : .portrait)
        return ScreenshotCanvas(display: display, orientation: orientation).pixelSize
    }

    // MARK: - Banner

    var banner: ScreenshotsBannerContent? {
        if !context.version.isEditable {
            let next = Self.nextVersionString(after: context.version.versionString)
            return .noVersion(
                title: String(localized: "No version to push to."),
                message: String(localized: "Version \(context.version.versionString) is live. Screenshots can only change with a version that’s being prepared, so create \(next) in App Store Connect. You can keep editing; renders wait here.")
            )
        }
        guard tab == .sets, hasTemplate, let first = matrix.failedCells.first else { return nil }
        let count = matrix.failedCells.count
        let title = count == 1 ? String(localized: "1 render fails its check.") : String(localized: "\(count) renders fail their checks.")
        let name = locale(code: first.key.locale)?.name ?? first.key.locale
        let reason = first.firstFailure?.shortReason ?? first.state.title
        let message = String(localized: "First: \(name), slot \(first.key.slot + 1) · \(reason). They stay out of Review & Push until they pass.")
        return .failedChecks(title: title, message: message, first: first.key)
    }

    /// "1.3" → "1.4".
    static func nextVersionString(after version: String) -> String {
        var parts = version.split(separator: ".").map(String.init)
        guard let last = parts.last, let number = Int(last) else { return version }
        parts[parts.count - 1] = String(number + 1)
        if parts.count == 1 { parts.append("0") }
        return parts.joined(separator: ".")
    }

    func locale(code: String) -> StoreLocale? {
        locales.first { $0.code == code } ?? StoreLocaleCatalog.locale(code: code)
    }
}
