//
//  ScreenshotStudioModel+PreviewReview.swift
//  AppLocalizer
//

import AppKit
import UniformTypeIdentifiers

/// Watch the App Preview from the sheet: the App Preview shown (language
/// and device), the quick asks, Ask for changes, the music (the person's
/// own file confirmed by choosing it) and Approve App Preview.
extension ScreenshotStudioModel {
    /// The quick asks under Ask for changes.
    static let previewQuickAsks = [
        String(localized: "Slower pace"), String(localized: "Start with Search"),
        String(localized: "Bigger captions"), String(localized: "Calmer music"),
    ]

    /// The App Preview files the run made, from the saved set.
    var runPreviews: [ExtrasPreviewFile] {
        screenshots.document?.extras?.previews ?? []
    }

    /// The languages with an App Preview of their own, primary first.
    var watchLocales: [String] {
        guard let plan = run?.plan else { return [] }
        return plan.previewLocales.filter { code in runPreviews.contains { $0.locale == code } }
    }

    var watchDevices: [ScreenshotDisplayType] {
        guard let plan = run?.plan else { return [] }
        return plan.previewDisplays.filter { display in runPreviews.contains { $0.displayType == display } }
    }

    /// The App Preview shown: the chosen language and device, else the
    /// primary language on the first device.
    var watchedPreview: ExtrasPreviewFile? {
        guard let extras = screenshots.document?.extras else { return nil }
        let display = watchedDevice.flatMap { watchDevices.contains($0) ? $0 : nil } ?? watchDevices.first ?? .iPhone
        let primary = run?.plan.primaryLocale ?? primaryLocale.code
        return extras.preview(on: display, locale: watchedLocale ?? primary, primary: primary)
    }

    func previewURL(_ file: ExtrasPreviewFile) -> URL {
        screenshots.services.extrasFileURL(file.fileID, pathExtension: "mov", for: app)
    }

    /// The music the App Previews were made with: the saved set's, else
    /// the plan's.
    var previewMusic: AutopilotPreviewMusic {
        run?.plan.alsoMakes.previewMusic ?? screenshots.document?.extras?.previewMusic ?? .standard
    }

    /// A quick ask, added to what's typed.
    func addPreviewAsk(_ ask: String) {
        let current = previewNote.trimmingCharacters(in: .whitespacesAndNewlines)
        previewNote = current.isEmpty ? ask : current + ", " + ask.lowercased()
    }

    /// Ask for changes: the note goes to the design source; Claude Code
    /// picks it up.
    func askForPreviewChanges() {
        autopilot?.requestPreviewChanges(previewNote, appID: app.id)
        previewNote = ""
        previewPlayer.pause()
        let goOn = goingOn()
        Task { await goOn() }
    }

    /// Approve App Preview: on to Review & Push.
    func approvePreview() {
        previewPlayer.pause()
        viewedStep = nil
        autopilot?.approvePreview(appID: app.id)
    }

    /// Another music: the plan's at Plan; at Watch the App Preview it's
    /// mixed in again, and the new files are read back.
    func setPreviewMusic(_ music: AutopilotPreviewMusic) {
        guard let autopilot else { return }
        let (appID, context) = (app.id, context)
        if run?.stage == .plan {
            Task { await autopilot.setPreviewMusic(music, appID: appID, context: context) }
            return
        }
        previewPlayer.pause()
        Task { [screenshots] in
            await autopilot.setPreviewMusic(music, appID: appID, context: context)
            await screenshots.reloadDocument()
        }
    }

    /// Your File…: an audio file, confirmed as the person's to use by
    /// choosing it.
    func chooseMusicFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = String(localized: "Music for the App Preview")
        panel.message = String(localized: """
        Choose music you hold the rights to: it plays under your App Preview on the App Store, in every language. \
        By choosing it, you confirm you may use it there.
        """)
        panel.prompt = String(localized: "Use This Music")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task { await useMusicFile(url) }
    }

    /// Copies the file into the app's Extras folder, once it reads as
    /// sound, and uses it.
    func useMusicFile(_ url: URL) async {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
        do {
            _ = try await AppPreviewMusicFile.samples(of: url)
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let id = ScreenshotPNG.checksum(data)
            let pathExtension = url.pathExtension.isEmpty ? "m4a" : url.pathExtension.lowercased()
            let copy = screenshots.services.extrasFileURL(id, pathExtension: pathExtension, for: app)
            try FileManager.default.createDirectory(at: copy.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: copy.path) { try data.write(to: copy, options: .atomic) }
            setPreviewMusic(AutopilotPreviewMusic(fileID: id, fileExtension: pathExtension, fileName: url.lastPathComponent))
        } catch {
            musicError = error.localizedDescription
        }
    }

    /// Picks a music choice: a library track, or Your File… to choose one.
    func pickMusic(_ track: AppPreviewTrack) {
        guard track == .ownFile else {
            setPreviewMusic(AutopilotPreviewMusic(track: track))
            return
        }
        chooseMusicFile()
    }

    /// Info rows: "0:24 · Today, Week, Search, end card".
    func previewLengthLine(_ file: ExtrasPreviewFile) -> String {
        let scenes = (file.scenes ?? []).map { $0.isEndCard ? String(localized: "end card") : $0.title }
        guard !scenes.isEmpty else { return file.lengthTitle }
        return file.lengthTitle + " · " + scenes.joined(separator: ", ")
    }

    /// "iPhone 886 × 1920 · iPad 1200 × 1600 · 30 fps".
    var previewSizesLine: String {
        let sizes = watchDevices.compactMap { display in
            runPreviews.first { $0.displayType == display }.map { "\(display.shortTitle) \($0.pixelSize.title)" }
        }
        return (sizes + [String(localized: "30 fps")]).joined(separator: " · ")
    }

    /// "0:05 · the Today screen".
    func previewPosterLine(_ file: ExtrasPreviewFile) -> String {
        let time = ExtrasPreviewFile.lengthTitle(file.posterSeconds)
        guard let scene = file.scenes?.first(where: { file.posterSeconds >= $0.start && file.posterSeconds < $0.end }) else { return time }
        return scene.isEndCard ? String(localized: "\(time) · the end card") : String(localized: "\(time) · the \(scene.title) screen")
    }

    /// "Fits Apple’s rules: 15–30 s, 30 fps, stereo, under 500 MB", or what
    /// doesn't.
    func previewChecksLine(_ file: ExtrasPreviewFile) -> String {
        guard !file.problems.isEmpty else { return String(localized: "Fits Apple’s rules: 15–30 s, 30 fps, stereo, under 500 MB") }
        return file.problems.joined(separator: " ")
    }
}
