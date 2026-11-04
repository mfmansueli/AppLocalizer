//
//  AutopilotCenter+Previews.swift
//  AppLocalizer
//

import Foundation

/// The App Previews: each device in each language with one of its own, cut
/// from that language's recording (or the primary language's when only it
/// was recorded) the way the checkpoint's cut says, captioned and closed
/// with an end card in the chosen direction, with the plan's music under
/// it, then checked against Apple's rules.
extension AutopilotCenter {
    func makePreviews(
        _ appID: StoreApp.ID, run: AutopilotRun, direction: AutopilotDirection, captions: CaptionBook, context: AutopilotContext
    ) async -> [ExtrasPreviewFile] {
        let plan = run.plan
        let services = context.services
        let cut = run.previewReview?.cut ?? AppPreviewCut()
        let music = musicSource(plan.alsoMakes.previewMusic, context: context)
        var files: [ExtrasPreviewFile] = []
        var done = 0
        for display in plan.previewDisplays {
            for code in plan.previewLocales {
                // Cancel Run: the rest isn't made.
                guard !Task.isCancelled else { return files }
                defer {
                    done += 1
                    update(appID) { run in
                        run.extrasProgress?.previewsDone = done
                        run.previewReview?.remake?.done = done
                    }
                }
                let target = AutopilotRecordingTarget(displayType: display, locale: code)
                guard let recording = run.previewRecording(for: target), let locale = StoreLocaleCatalog.locale(code: code) else {
                    note(String(localized: "No recording on \(display.title) for \(code): no App Preview there"), appID: appID)
                    continue
                }
                let screens = plan.screens.enumerated().map { slot, screen in
                    AppPreviewScreen(id: screen.id, headline: AutopilotArtworkMaker.headline(slot: slot, locale: code, plan: plan, captions: captions))
                }
                let temporary = FileManager.default.temporaryDirectory.appending(path: "AppPreview-\(makeID()).mov")
                let request = AppPreviewRequest(
                    recording: services.recordingURL(recording.fileID, for: context.app), recordingSize: recording.pixelSize,
                    recordingSeconds: recording.seconds, marks: recording.marks, screens: screens, template: direction.previewLook,
                    locale: locale, appName: run.appName(in: code, fallback: context.app.name), displayType: display, fonts: services.fonts,
                    output: temporary, cut: cut, music: music,
                    clips: run.previewClips(for: recording) { services.recordingURL($0, for: context.app) }
                )
                do {
                    let result = try await AppPreviewMaker.make(request)
                    var file = try keep(result, display: display, locale: code, recordedLocale: recording.target.locale, context: context)
                    file.scenes = Self.scenes(of: result, plan: plan)
                    files.append(file)
                    if code == plan.primaryLocale, display == plan.previewDisplays.first {
                        update(appID) { $0.extrasProgress?.previewSeconds = file.seconds }
                    }
                    if code == plan.primaryLocale {
                        update(appID) { $0.extrasProgress?.previewSizes.append(file.pixelSize) }
                    }
                    for issue in file.problems {
                        update(appID) { $0.extrasProgress?.previewProblems.append("\(display.title) · \(locale.name): \(issue)") }
                    }
                } catch {
                    update(appID) { run in
                        run.extrasProgress?.previewProblems.append("\(display.title) · \(locale.name): \(error.localizedDescription)")
                        run.appendLog(String(localized: "Couldn’t make the App Preview on \(display.title) in \(locale.name): \(error.localizedDescription)"), kind: .problem, at: now())
                    }
                }
            }
        }
        if !files.isEmpty {
            let seconds = files.first.map { ExtrasPreviewFile.lengthTitle($0.seconds) } ?? ""
            let sizes = Array(Set(files.map(\.pixelSize.title))).sorted().joined(separator: String(localized: " and "))
            note(String(localized: "App Preview assembled · \(files.count) videos · \(seconds) · \(sizes) · 30 fps"), appID: appID)
        }
        return files
    }

    /// The plan's music as the maker plays it: a library track, or the
    /// person's file in the Extras folder.
    func musicSource(_ music: AutopilotPreviewMusic, context: AutopilotContext) -> AppPreviewMusicSource {
        guard music.track == .ownFile else { return .track(music.track) }
        guard let fileID = music.fileID, let fileExtension = music.fileExtension else { return .track(.ownFile) }
        return .file(context.services.extrasFileURL(fileID, pathExtension: fileExtension, for: context.app))
    }

    /// What plays when: each screen's moment by its name, then the end
    /// card.
    static func scenes(of result: AppPreviewResult, plan: AutopilotPlan) -> [ExtrasPreviewScene] {
        var start = 0.0
        var scenes: [ExtrasPreviewScene] = result.segments.map { segment in
            defer { start += segment.duration }
            let name = plan.screen(id: segment.screenID)?.name ?? segment.screenID
            return ExtrasPreviewScene(screenID: segment.screenID, title: name, start: start, duration: segment.duration)
        }
        scenes.append(ExtrasPreviewScene(screenID: nil, title: String(localized: "End card"), start: start, duration: result.endCardSeconds))
        return scenes
    }

    /// Moves the made file into the app's Extras folder, named by its
    /// checksum.
    private func keep(
        _ result: AppPreviewResult, display: ScreenshotDisplayType, locale: String, recordedLocale: String, context: AutopilotContext
    ) throws -> ExtrasPreviewFile {
        let data = try Data(contentsOf: result.output.url, options: .mappedIfSafe)
        let id = ScreenshotPNG.checksum(data)
        let url = context.services.extrasFileURL(id, pathExtension: "mov", for: context.app)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
        try FileManager.default.moveItem(at: result.output.url, to: url)
        return ExtrasPreviewFile(
            displayType: display, locale: locale, recordedLocale: recordedLocale, fileID: id, seconds: result.output.seconds,
            pixelSize: result.output.pixelSize, byteCount: Int(result.output.byteCount), posterSeconds: result.spec.posterSeconds,
            problems: result.issues
        )
    }

    private func note(_ text: String, appID: StoreApp.ID) {
        update(appID) { $0.appendLog(text, kind: .event, at: now()) }
    }
}
