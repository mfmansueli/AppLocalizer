//
//  ScreenshotStudioModel+Pick.swift
//  AppLocalizer
//

import Foundation

/// Pick captures: the Screenshots tab (each screen's pick with the
/// attempts it was ranked against, per device) and the App Preview
/// recording tab (the raw take, its moments, how long they make it).
extension ScreenshotStudioModel {
    // MARK: - Tabs and devices

    /// Screenshots when there are new captures to pick from, the recording
    /// when one arrived.
    func pickTabs(_ run: AutopilotRun) -> [AutopilotPickTab] {
        [run.picksScreens ? .screenshots : nil, run.hasRecordingMoments ? .recording : nil].compactMap(\.self)
    }

    func currentPickTab(_ run: AutopilotRun) -> AutopilotPickTab {
        let tabs = pickTabs(run)
        return pickTab.flatMap { tabs.contains($0) ? $0 : nil } ?? tabs.first ?? .screenshots
    }

    /// iPhone and iPad, iPhone Duo and Apple Watch, as the plan has them.
    func pickDevices(_ run: AutopilotRun) -> [AutopilotPickDevice] {
        let plan = run.plan
        var devices: [AutopilotPickDevice] = [.phones]
        if plan.makesScreenshots, plan.plansDuo { devices.append(.duo) }
        if plan.makesScreenshots, plan.displayTypes.contains(.watch), !plan.screens(on: .watch).isEmpty { devices.append(.watch) }
        return devices
    }

    func currentPickDevice(_ run: AutopilotRun) -> AutopilotPickDevice {
        let devices = pickDevices(run)
        return pickDevice.flatMap { devices.contains($0) ? $0 : nil } ?? .phones
    }

    /// What the device's picks are, under the switch.
    func pickNote(_ run: AutopilotRun, device: AutopilotPickDevice) -> String {
        let client = run.clientName(assistant: nil)
        switch device {
        case .phones:
            let followers = run.plan.displayTypes.filter { $0 == .iPad || $0 == .mac || $0 == .visionPro }.map(\.shortTitle)
            let most = run.plan.screens.map { run.candidates(for: $0.id).count }.max() ?? 1
            var text = most > 1
                ? String(localized: "Best of \(most) per screen, ranked by \(client). Click any capture to see it full size and use another.")
                : String(localized: "Ranked by \(client). Click any capture to see it full size.")
            text += " " + (followers.isEmpty
                ? String(localized: "Picks apply to every language.")
                : String(localized: "Picks apply to every language; \(followers.formatted(.list(type: .and))) use the same moments."))
            return text
        case .duo:
            let displays = switch run.plan.duoScreens {
            case .inner: String(localized: "on the inner display")
            case .cover: String(localized: "on the cover display")
            case .both: String(localized: "on the inner and cover displays")
            }
            return String(localized: "Same moments as iPhone, \(displays). Click to see them full size.")
        case .watch:
            return String(localized: "Best of 3 each, ranked the same way. No captions on the watch.")
        }
    }

    // MARK: - Screenshots

    /// The screens picked on iPhone (or the artwork's, without
    /// screenshots); Apple Watch's have their own.
    func pickPhoneScreens(_ run: AutopilotRun) -> [AutopilotScreen] {
        run.plan.pickedScreens.filter { run.plan.display(of: $0.id) != .watch }
    }

    /// A screen's captures, best first, with the one used marked.
    func pickAttempts(_ run: AutopilotRun, screenID: String) -> [AutopilotPickAttempt] {
        let picked = run.pickedCapture(for: screenID)
        return run.candidates(for: screenID).enumerated().map { rank, capture in
            AutopilotPickAttempt(capture: capture, rank: rank, isUsed: capture.id == picked?.id)
        }
    }

    /// The person chose another attempt than the assistant's best.
    func isYourPick(_ run: AutopilotRun, screenID: String) -> Bool {
        guard let picked = run.pickedCapture(for: screenID), let best = run.candidates(for: screenID).first else { return false }
        return picked.id != best.id
    }

    /// "Claude Code’s pick" or "Your pick".
    func pickBadge(_ run: AutopilotRun, screenID: String) -> String {
        isYourPick(run, screenID: screenID)
            ? String(localized: "Your pick")
            : String(localized: "\(run.clientName(assistant: nil))’s pick")
    }

    /// The pick's reason, or why it was ranked lower when it's the
    /// person's.
    func pickReason(_ run: AutopilotRun, screenID: String) -> String {
        guard let picked = run.pickedCapture(for: screenID) else { return "" }
        let notes = picked.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isYourPick(run, screenID: screenID) else { return notes }
        return String(localized: "⚠︎ Ranked lower: \(notes.prefix(1).lowercased() + notes.dropFirst())")
    }

    /// How many screens the person picked differently.
    func changedPickCount(_ run: AutopilotRun) -> Int {
        run.plan.pickedScreens.count { isYourPick(run, screenID: $0.id) }
    }

    /// iPhone Duo's captures of a screen, in the primary language: the
    /// inner display's and the cover display's, as the plan shows them.
    func duoCaptures(_ run: AutopilotRun, screenID: String) -> (inner: AutopilotCapture?, cover: AutopilotCapture?) {
        let locale = run.plan.primaryLocale
        func capture(_ pose: AutopilotDuoPose) -> AutopilotCapture? {
            let target = AutopilotCaptureTarget(screenID: screenID, displayType: .iPhoneDuo, locale: locale, duoPose: pose)
            return run.finalCapture(for: target)
        }
        let poses = run.plan.slot(of: screenID).map(run.plan.duoPoses(forSlot:)) ?? []
        return (poses.contains(.open) ? capture(.open) : nil, poses.contains(.closed) ? capture(.closed) : nil)
    }

    // MARK: - Footer

    /// "1 pick changed by you; the rest are Claude Code’s · App Preview: 3
    /// moments + end card, 0:24."
    func pickFooterText(_ run: AutopilotRun) -> String {
        let client = run.clientName(assistant: nil)
        var parts: [String] = []
        if run.picksScreens {
            let changed = changedPickCount(run)
            let text = switch changed {
            case 0: String(localized: "\(client)’s picks are selected")
            case 1: String(localized: "1 pick changed by you; the rest are \(client)’s")
            default: String(localized: "\(changed) picks changed by you; the rest are \(client)’s")
            }
            parts.append(text)
        }
        if run.hasRecordingMoments {
            let count = run.chosenMomentIDs.count
            parts.append(count == 1
                ? String(localized: "App Preview: 1 moment + end card, \(run.pickedPreviewLengthTitle)")
                : String(localized: "App Preview: \(count) moments + end card, \(run.pickedPreviewLengthTitle)"))
        }
        return parts.isEmpty ? String(localized: "\(client)’s picks are selected.") : parts.joined(separator: " · ") + "."
    }

    /// Use These Picks waits while the App Preview is outside Apple's 15–30
    /// seconds.
    func canUsePicks(_ run: AutopilotRun) -> Bool {
        !run.hasRecordingMoments || run.pickedPreviewFits
    }

    // MARK: - Recording

    /// The recording Pick plays: the one chosen, else the first.
    func currentPickRecording(_ run: AutopilotRun) -> AutopilotRecordingTarget? {
        let targets = run.pickRecordingTargets
        return pickRecording.flatMap { targets.contains($0) ? $0 : nil } ?? targets.first
    }

    /// Devices with a recording, then that device's languages.
    func pickRecordingDevices(_ run: AutopilotRun) -> [ScreenshotDisplayType] {
        var seen: Set<ScreenshotDisplayType> = []
        return run.pickRecordingTargets.map(\.displayType).filter { seen.insert($0).inserted }
    }

    func pickRecordingLocales(_ run: AutopilotRun, display: ScreenshotDisplayType) -> [String] {
        run.pickRecordingTargets.filter { $0.displayType == display }.map(\.locale)
    }

    /// Shows another device or language's recording, from its start.
    func showRecording(_ target: AutopilotRecordingTarget) {
        recordingPlayer.pause()
        pickRecording = target
    }

    /// Loads the recording into the player, paused.
    func loadPickRecording(_ run: AutopilotRun) {
        guard let target = currentPickRecording(run), let recording = run.recording(for: target) else {
            recordingPlayer.load(nil, seconds: 0)
            return
        }
        recordingPlayer.load(screenshots.services.recordingURL(recording.fileID, for: app), seconds: recording.seconds)
    }

    /// "Raw recording · iPhone 17 Pro Max · English · 0:38".
    func recordingTitle(_ run: AutopilotRun) -> String {
        guard let target = currentPickRecording(run), let recording = run.recording(for: target) else { return "" }
        let language = StoreLocaleCatalog.locale(code: target.locale)?.shortName ?? target.locale
        return String(localized: "Raw recording · \(target.displayType.deviceName) · \(language) · \(AutopilotRun.timeTitle(recording.seconds))")
    }

    /// What the take is and what happens next.
    func recordingIntro(_ run: AutopilotRun) -> String {
        let client = run.clientName(assistant: nil)
        let perLanguage = Set(run.pickRecordingTargets.map(\.locale)).count > 1
        let designer = run.designKind == .claudeDesign ? DesignProjectKind.claudeDesign.title : String(localized: "AppLocalizer")
        return perLanguage
            ? String(localized: "\(client) recorded the plan’s screens in one take per device and language, then marked the moments that work in an App Preview. Choose which go in; \(designer) adds captions, music and the end card next.")
            : String(localized: "\(client) recorded the plan’s screens in one take per device, then marked the moments that work in an App Preview. Choose which go in; \(designer) adds captions, music and the end card next.")
    }

    /// "App Preview: Today, Week, Search and the end card · 0:24 · within
    /// Apple’s 15–30 s".
    func momentsSummary(_ run: AutopilotRun) -> String {
        let names = run.chosenMomentIDs.map { run.plan.screen(id: $0)?.name ?? $0 }
        let what = names.isEmpty
            ? String(localized: "only the end card")
            : String(localized: "\(names.joined(separator: ", ")) and the end card")
        let seconds = run.pickedPreviewSeconds
        let fit = run.pickedPreviewFits
            ? String(localized: "within Apple’s 15–30 s")
            : seconds > 30 ? String(localized: "over Apple’s 30 s: remove a moment") : String(localized: "under Apple’s 15 s: add a moment")
        return String(localized: "App Preview: \(what)") + " · " + run.pickedPreviewLengthTitle + " · " + fit
    }

    func setMoment(_ moment: AutopilotRecordingMoment, chosen: Bool) {
        autopilot?.setMoment(appID: app.id, screenID: moment.screenID, chosen: chosen)
    }

    /// Record Again: Claude Code records the moment again before Design.
    func recordAgain(_ moment: AutopilotRecordingMoment) {
        autopilot?.askToRecordAgain(appID: app.id, screenID: moment.screenID)
    }

    /// "Claude Code will record “Week” again before the design step. The
    /// rest of the recording stays."; nil unless it was asked for.
    func recordAgainNote(_ run: AutopilotRun, moment: AutopilotRecordingMoment) -> String? {
        guard run.momentRetakes?.contains(moment.screenID) == true else { return nil }
        let name = run.plan.screen(id: moment.screenID)?.name ?? moment.screenID
        return String(localized: "\(run.clientName(assistant: nil, startsSentence: true)) will record “\(name)” again before the design step. The rest of the recording stays.")
    }

    /// The current recording's moments.
    func pickMoments(_ run: AutopilotRun) -> [AutopilotRecordingMoment] {
        currentPickRecording(run).map(run.moments(for:)) ?? []
    }

    /// The bar under the recording: between screens, each moment, the end.
    func recordingPieces(_ run: AutopilotRun) -> [AutopilotRecordingPiece] {
        guard let target = currentPickRecording(run), let recording = run.recording(for: target) else { return [] }
        var pieces: [AutopilotRecordingPiece] = []
        var position = 0.0
        for moment in run.moments(for: target) {
            if moment.start > position {
                pieces.append(AutopilotRecordingPiece(
                    id: "between.\(pieces.count)", start: position, end: moment.start, kind: .between, title: String(localized: "Between screens")
                ))
            }
            let chosen = run.isChosen(moment)
            let name = run.plan.screen(id: moment.screenID)?.name ?? moment.screenID
            let range = AutopilotRun.timeTitle(moment.start) + "–" + AutopilotRun.timeTitle(moment.end)
            pieces.append(AutopilotRecordingPiece(
                id: "moment.\(moment.screenID)", start: moment.start, end: moment.end, kind: .moment(chosen: chosen),
                title: "\(name) · \(range)" + (chosen ? " · " + String(localized: "in the App Preview") : "")
            ))
            position = max(position, moment.end)
        }
        pieces.append(AutopilotRecordingPiece(
            id: "end", start: position, end: max(recording.seconds, position), kind: .end, title: String(localized: "End of the recording")
        ))
        return pieces
    }

    /// The moment the playhead is in (from a second before it), while it
    /// plays or once it moved.
    func currentMomentID(_ run: AutopilotRun) -> String? {
        let time = recordingPlayer.seconds
        guard recordingPlayer.isPlaying || time > 0 else { return nil }
        return pickMoments(run).last { time >= $0.start - 1 }?.screenID
    }

    /// "0:17 / 0:38".
    func recordingTimeTitle(_ run: AutopilotRun) -> String {
        let length = currentPickRecording(run).flatMap(run.recording(for:))?.seconds ?? recordingPlayer.duration
        return AutopilotRun.timeTitle(recordingPlayer.seconds) + " / " + AutopilotRun.timeTitle(length)
    }

    /// Plays one moment from its start.
    func playMoment(_ moment: AutopilotRecordingMoment) {
        recordingPlayer.seek(to: moment.start)
        recordingPlayer.play()
    }
}
