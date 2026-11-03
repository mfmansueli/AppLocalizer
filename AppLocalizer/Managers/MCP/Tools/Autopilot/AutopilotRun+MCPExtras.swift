//
//  AutopilotRun+MCPExtras.swift
//  AppLocalizer
//

import Foundation

/// `get_capture_plan`'s "Also make": the header and search artwork
/// AppLocalizer renders in the chosen direction (nothing to capture), and
/// the App Preview's recordings to make during the capture run.
extension AutopilotRun {
    func mcpAlsoMake(upload: String) -> JSONValue? {
        guard !plan.alsoMakes.isEmpty else { return nil }
        var json: [String: JSONValue] = [:]
        if !plan.artworkKinds.isEmpty {
            json["artwork"] = [
                "images": .array(plan.artworkKinds.map { kind in
                    [
                        "kind": .string(kind.rawValue),
                        "pixelSize": .string(kind.pixelSize.title),
                        "ratio": .string(kind.ratioTitle),
                        "text": .string(ArtworkTextRole.role(for: kind).rawValue),
                    ]
                }),
                "note": """
                Nothing to capture: AppLocalizer renders them in each language from the chosen direction and the \
                screenshots' picked captures. Each placement has its own text (not a screenshot's caption), written in \
                Localize when next_step says write_artwork_texts.
                """,
            ]
        }
        if !plan.previewDisplays.isEmpty {
            json["appPreview"] = [
                "languages": .string(plan.alsoMakes.previewLanguages == .all ? "all" : "primary"),
                "lengthSeconds": .int(hasRecordingMoments ? pickedPreviewSeconds : AutopilotExtras.previewSeconds),
                "record": .array(plan.recordingTargets.map(AutopilotNextStep.recordingJSON)),
                "upload": .string("curl -s --data-binary @preview.mov -H 'Content-Type: video/quicktime' \(upload)"),
                "how": .string(Self.recordingHow),
            ]
        }
        return .object(json)
    }

    /// How to record an App Preview's walkthrough.
    static let recordingHow = """
    Record each one in this capture run, after its device's captures in that language, with the same simulator \
    setup and launch arguments. Launch the app on the plan's first screen, start xcrun simctl io <udid> recordVideo \
    --codec h264 --force preview.mov in the background, then go through the plan's screens in order the way you \
    reach them for the captures, holding each about 4 s with a gentle real interaction (a scroll, a tap), and note \
    the second each screen appears. Stop with kill -INT <pid> (Control-C) so the file is finished. Only the app may \
    be on screen when a screen appears: no Home screen, alert or keyboard; what's between screens (a relaunch) is \
    cut out. Upload it to the plan's upload URL with curl --data-binary and -H 'Content-Type: video/quicktime', then \
    call report_recording with the upload ID, displayType, locale and marks [{screen, seconds}], and moments \
    [{screen, start_s, end_s, reason, use}]: the stretch of each screen that works in an App Preview (about 6 s, \
    settled, something gentle happening) and why; use: false for one you'd leave out. The person picks which go \
    in. When it can't be recorded, call report_recording with problem instead: the run goes on without it.
    """

    /// `get_design_brief`'s extras: the artwork canvases each direction
    /// asks for, and the App Preview's languages and length.
    func mcpBriefExtras(referenceURL: ((AutopilotArtworkReference) -> URL)? = nil) -> JSONValue? {
        guard !plan.alsoMakes.isEmpty else { return nil }
        var json: [String: JSONValue] = [:]
        if plan.alsoMakes.makesArtwork { json.merge(mcpArtworkBrief(referenceURL: referenceURL)) { $1 } }
        if !plan.previewDisplays.isEmpty {
            json["appPreview"] = [
                "languages": .string(plan.alsoMakes.previewLanguages == .all ? "all" : "primary"),
                "lengthSeconds": .int(hasRecordingMoments ? pickedPreviewSeconds : AutopilotExtras.previewSeconds),
                "devices": .array(plan.previewDisplays.map { .string($0.mcpValue) }),
                "posterFrameAt": "0:05",
            ]
        }
        json["how"] = """
        Nothing more to send unless you want it: AppLocalizer renders the artwork in each language with the direction's \
        background, headline style and device frames, the real picked captures in the phones, and each placement's own \
        text (it shrinks to fit and mirrors for right-to-left); and it styles the App Preview's captions and end card \
        with the direction's headline and colors. For a look of their own, pass extrasTemplates {artwork, appPreview} \
        with propose_direction, designed for the roles above. No alpha: AppLocalizer flattens every image.
        """
        return .object(json)
    }
}
