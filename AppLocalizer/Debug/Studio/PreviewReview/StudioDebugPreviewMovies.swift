//
//  StudioDebugPreviewMovies.swift
//  AppLocalizer
//

#if DEBUG
import CoreGraphics
import Foundation

/// Real App Previews for board 29's scenes, so the player plays: a
/// recording drawn from Lumen's mock captures (each screen from its mark
/// on), then the App Preview made from it the way Localize makes it, with
/// the run's cut and music, saved with the set in place of the fixture's
/// file. Made once per cut and music, then kept in the Extras folder.
@MainActor
enum StudioDebugPreviewMovies {
    /// The mock recording: where it's written, its size, length and
    /// screen marks.
    struct Recording: Sendable {
        var url: URL
        var size: PixelSize
        var seconds: Double
        var marks: [AutopilotRecordingMark]
    }

    /// Bump when the maker draws differently, to make them again.
    private static let version = 1
    /// The debug recording's frame rate: the App Preview holds each frame.
    private nonisolated static let recordingFPS = 10

    /// Makes the App Previews on `targets` (device and language), saves
    /// them with the set, then jumps the player to `seconds`.
    static func make(
        _ targets: [(ScreenshotDisplayType, String)], run: AutopilotRun, model: ScreenshotsViewModel, seconds: Double? = nil
    ) async {
        guard let document = await loadedDocument(model), let direction = run.chosenDirection ?? run.directions.first else { return }
        var made: [ExtrasPreviewFile] = []
        for (display, code) in targets {
            do {
                try await made.append(movie(on: display, locale: code, run: run, direction: direction, captions: document.captions, model: model))
            } catch {
                print("StudioDebugPreviewMovies: \(display.title) \(code): \(error.localizedDescription)")
            }
        }
        guard var current = model.document, var extras = current.extras else { return }
        for file in made {
            extras.previews.removeAll { $0.displayType == file.displayType && $0.locale == file.locale }
            extras.previews.append(file)
        }
        extras.previewMusic = run.plan.alsoMakes.previewMusic
        current.extras = extras
        await model.commit(current)
        if let seconds { await seek(model, to: seconds) }
    }

    /// The App Preview on `display` in `code`: the one made before for this
    /// cut and music, else made now.
    private static func movie(
        on display: ScreenshotDisplayType, locale code: String, run: AutopilotRun, direction: AutopilotDirection,
        captions: CaptionBook, model: ScreenshotsViewModel
    ) async throws -> ExtrasPreviewFile {
        let review = run.previewReview ?? AutopilotPreviewReview()
        let music = run.plan.alsoMakes.previewMusic.track
        let key = "debug-ap\(version)-\(display.mcpValue)-\(code)-\(music.rawValue)-\(review.cut.isStandard ? "standard" : "v\(review.version)")"
        let services = model.services
        let movieURL = services.extrasFileURL(key, pathExtension: "mov", for: model.app)
        let infoURL = services.extrasFileURL(key, pathExtension: "json", for: model.app)
        if FileManager.default.fileExists(atPath: movieURL.path), let data = try? Data(contentsOf: infoURL),
           let file = try? JSONDecoder().decode(ExtrasPreviewFile.self, from: data)
        {
            return file
        }
        guard let locale = StoreLocaleCatalog.locale(code: code) else { throw AppPreviewError.noUsableMark }
        let recording = Recording(
            url: FileManager.default.temporaryDirectory.appending(path: "\(key)-recording.mov"),
            size: PixelSize(width: display.portraitPixelSize.width / 2, height: display.portraitPixelSize.height / 2),
            seconds: Double(run.plan.screens.count) * 6 + 2,
            marks: run.plan.screens.enumerated().map { AutopilotRecordingMark(screenID: $1.id, seconds: Double($0) * 6 + 1) }
        )
        try await writeRecording(recording, display: display, locale: code, run: run, model: model)
        defer { try? FileManager.default.removeItem(at: recording.url) }
        let screens = run.plan.screens.enumerated().map { slot, screen in
            AppPreviewScreen(id: screen.id, headline: AutopilotArtworkMaker.headline(slot: slot, locale: code, plan: run.plan, captions: captions))
        }
        let output = FileManager.default.temporaryDirectory.appending(path: "\(key)-made.mov")
        let result = try await AppPreviewMaker.make(AppPreviewRequest(
            recording: recording.url, recordingSize: recording.size, recordingSeconds: recording.seconds, marks: recording.marks, screens: screens,
            template: direction.previewLook, locale: locale, appName: model.app.name, displayType: display, fonts: services.fonts,
            output: output, cut: review.cut, music: .track(music == .ownFile ? .warmAcoustic : music)
        ))
        try FileManager.default.createDirectory(at: movieURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: movieURL.path) { try FileManager.default.removeItem(at: movieURL) }
        try FileManager.default.moveItem(at: result.output.url, to: movieURL)
        var file = ExtrasPreviewFile(
            displayType: display, locale: code, recordedLocale: code, fileID: key, seconds: result.output.seconds,
            pixelSize: result.output.pixelSize, byteCount: Int(result.output.byteCount), posterSeconds: result.spec.posterSeconds,
            problems: result.issues
        )
        file.scenes = AutopilotCenter.scenes(of: result, plan: run.plan)
        try JSONEncoder().encode(file).write(to: infoURL)
        return file
    }

    /// Each screen's mock capture in `locale`, from its mark until the next.
    static func writeRecording(
        _ recording: Recording, display: ScreenshotDisplayType, locale: String, run: AutopilotRun, model: ScreenshotsViewModel
    ) async throws {
        var images: [CGImage?] = []
        for (slot, screen) in run.plan.screens.enumerated() {
            let target = AutopilotCaptureTarget(screenID: screen.id, displayType: display, locale: locale)
            let capture = run.finalCapture(for: target) ?? run.pickedCapture(for: screen.id)
            var image: CGImage?
            if let capture {
                image = await model.services.captureImage(capture.screenshotCapture(slot: slot), for: model.app, pixelWidth: recording.size.width)
            }
            images.append(image)
        }
        try await encode(images, recording: recording, display: display)
    }

    /// Off the main actor: the frames hold each image from its mark on.
    private nonisolated static func encode(
        _ images: [CGImage?], recording: Recording, display: ScreenshotDisplayType
    ) async throws {
        var spec = AppPreviewSpec(displayType: display, pixelSize: recording.size)
        spec.framesPerSecond = recordingFPS
        let writer = try AppPreviewWriter(output: recording.url, spec: spec, bitRate: 4_000_000)
        let count = Int(recording.seconds * Double(recordingFPS))
        let marks = recording.marks
        for index in 0..<count {
            let time = Double(index) / Double(recordingFPS)
            let slot = max(0, (marks.lastIndex { $0.seconds <= time + 0.000_1 }) ?? 0)
            _ = try await writer.appendFrame { context in
                let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
                context.setFillColor(CGColor(gray: 0.95, alpha: 1))
                context.fill(rect)
                if let image = images.indices.contains(slot) ? images[slot] : nil { context.draw(image, in: rect) }
            }
        }
        try await writer.finish()
    }

    private static func loadedDocument(_ model: ScreenshotsViewModel) async -> ScreenshotsDocument? {
        for _ in 0..<200 {
            if let document = model.document, document.extras != nil { return document }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return nil
    }

    /// Waits for the player to load the new file, then jumps.
    private static func seek(_ model: ScreenshotsViewModel, to seconds: Double) async {
        let player = model.studio.previewPlayer
        for _ in 0..<100 {
            if player.canPlay, player.url?.lastPathComponent.hasPrefix("debug-ap") == true {
                player.seek(to: seconds)
                return
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}
#endif
