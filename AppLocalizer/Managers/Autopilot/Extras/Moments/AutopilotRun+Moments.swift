//
//  AutopilotRun+Moments.swift
//  AppLocalizer
//

import Foundation

/// Pick's App Preview recording: the moments Claude Code marked in each
/// recording, which the person chose (the same screens in every device
/// and language), and how long that makes the App Preview: 6 seconds a
/// moment plus a 6-second end card, within Apple's 15–30.
extension AutopilotRun {
    /// A device's recording in a language, or the primary language's, with
    /// its moments in the plan's order.
    func moments(for target: AutopilotRecordingTarget) -> [AutopilotRecordingMoment] {
        previewRecording(for: target)?.moments(screenIDs: plan.screens.map(\.id)) ?? []
    }

    /// The recordings Pick plays: each device and language that has one.
    var pickRecordingTargets: [AutopilotRecordingTarget] {
        plan.recordingTargets.filter { recording(for: $0) != nil }
    }

    /// The moments to choose from: the first recording's (every recording
    /// shows the same screens).
    var pickableMoments: [AutopilotRecordingMoment] {
        pickRecordingTargets.first.map(moments(for:)) ?? []
    }

    /// Pick has a recording to choose moments from.
    var hasRecordingMoments: Bool { !pickableMoments.isEmpty }

    /// Claude Code's suggestion: the moments it marked to use, else the
    /// first three it didn't advise against.
    var suggestedMomentIDs: [String] {
        let moments = pickableMoments
        let flagged = moments.filter { $0.suggested == true }.map(\.screenID)
        guard flagged.isEmpty else { return flagged }
        return moments.filter { $0.suggested != false }.prefix(AutopilotRecordingMoment.suggestedCount).map(\.screenID)
    }

    /// The chosen moments' screens, in the plan's order.
    var chosenMomentIDs: [String] {
        let chosen = Set(previewMomentIDs ?? suggestedMomentIDs)
        return pickableMoments.map(\.screenID).filter(chosen.contains)
    }

    func isChosen(_ moment: AutopilotRecordingMoment) -> Bool {
        chosenMomentIDs.contains(moment.screenID)
    }

    /// Checks or unchecks a moment for the App Preview.
    mutating func setMoment(_ screenID: String, chosen: Bool) {
        var ids = Set(chosenMomentIDs)
        if chosen { ids.insert(screenID) } else { ids.remove(screenID) }
        previewMomentIDs = pickableMoments.map(\.screenID).filter(ids.contains)
    }

    /// The person changed which moments go in.
    var changedMoments: Bool {
        previewMomentIDs.map { Set($0) != Set(suggestedMomentIDs) } ?? false
    }

    /// The App Preview's length from the chosen moments: 6 seconds each
    /// and the end card.
    var pickedPreviewSeconds: Int {
        Int(AutopilotRecordingMoment.previewSeconds) * (chosenMomentIDs.count + 1)
    }

    /// Apple's 15–30 seconds: outside it, Use These Picks waits.
    var pickedPreviewFits: Bool {
        AppPreviewCut.secondsRange.contains(Double(pickedPreviewSeconds))
    }

    /// "0:24".
    var pickedPreviewLengthTitle: String {
        Self.timeTitle(Double(pickedPreviewSeconds))
    }

    /// "0:05", "1:02".
    static func timeTitle(_ seconds: Double) -> String {
        let whole = max(0, Int(seconds.rounded(.down)))
        return "\(whole / 60):" + String(format: "%02d", whole % 60)
    }

    /// The chosen moments of a recording, as the App Preview plays them;
    /// a moment recorded again plays from its take. Nil when the recording
    /// has no moments (the marks cut the App Preview then).
    func previewClips(for recording: AutopilotRecording, url: (String) -> URL) -> [AppPreviewClip]? {
        let moments = recording.moments(screenIDs: plan.screens.map(\.id))
        guard !moments.isEmpty else { return nil }
        let chosen = Set(chosenMomentIDs)
        return moments.filter { chosen.contains($0.screenID) }.map { moment in
            if let take = retake(of: moment.screenID, for: recording.target), let marked = take.markedMoments?.first {
                return AppPreviewClip(screenID: moment.screenID, start: marked.start, end: marked.end, source: url(take.fileID))
            }
            return AppPreviewClip(screenID: moment.screenID, start: moment.start, end: moment.end)
        }
    }

    // MARK: - Record again

    /// Asks Claude Code to record a moment again before Design; the rest of
    /// the recording stays.
    mutating func askToRecordAgain(_ screenID: String) {
        var ids = momentRetakes ?? []
        if !ids.contains(screenID) { ids.append(screenID) }
        momentRetakes = ids
        // An earlier take gives way to the new one.
        retakes = retakes?.filter { $0.retakeOf != screenID }
        if retakes?.isEmpty == true { retakes = nil }
    }

    /// The moments to record again on each recording that has them.
    var retakeTargets: [(target: AutopilotRecordingTarget, screenID: String)] {
        let ids = momentRetakes ?? []
        return pickRecordingTargets.flatMap { target in
            ids.filter { isWaitingForRetake($0, on: target) }.map { (target, $0) }
        }
    }

    /// Keeps a new take of a moment; once every recording has it, the
    /// moment is no longer waiting.
    mutating func addRetake(_ recording: AutopilotRecording) {
        guard let id = recording.retakeOf else { return }
        var all = (retakes ?? []).filter { !($0.retakeOf == id && $0.target == recording.target) }
        all.append(recording)
        retakes = all
        let missing = pickRecordingTargets.contains { target in !all.contains { $0.retakeOf == id && $0.target == target } }
        if !missing {
            momentRetakes = momentRetakes?.filter { $0 != id }
            if momentRetakes?.isEmpty == true { momentRetakes = nil }
        }
    }

    /// The newest take of a moment on a recording, if one came.
    func retake(of screenID: String, for target: AutopilotRecordingTarget) -> AutopilotRecording? {
        retakes?.last { $0.retakeOf == screenID && $0.target == target }
    }

    /// The person asked for this moment again and its take on `target`
    /// hasn't come since.
    func isWaitingForRetake(_ screenID: String, on target: AutopilotRecordingTarget) -> Bool {
        guard momentRetakes?.contains(screenID) == true else { return false }
        return retake(of: screenID, for: target) == nil
    }

    /// Some moment waits to be recorded again.
    var waitsForRetakes: Bool { !(momentRetakes ?? []).isEmpty }

    /// The upload link is open: while capturing, and past that while a
    /// moment waits for its new take.
    var takesUploads: Bool {
        switch stage {
        case .waiting, .capture: true
        case .pick, .design, .choose: !retakeTargets.isEmpty
        case .plan, .localize, .watchPreview, .ready: false
        }
    }

    /// The person went on without the takes still waiting: the earlier
    /// recording plays.
    mutating func giveUpWaitingRetakes(at date: Date) {
        let names = Array(Set(retakeTargets.map(\.screenID))).sorted().map { plan.screen(id: $0)?.name ?? $0 }
        momentRetakes = nil
        guard !names.isEmpty else { return }
        let list = names.formatted(.list(type: .and))
        appendLog(String(localized: "Went on without recording \(list) again; the earlier recording plays"), kind: .event, at: date)
    }
}
