//
//  AutopilotNextStep+MCPPreview.swift
//  AppLocalizer
//

import Foundation

/// `revise_app_preview`'s step: what the person asked, how the App Preview
/// is cut now, and what can change.
extension AutopilotNextStep {
    static func revisePreviewJSON(note: String, review: AutopilotPreviewReview, run: AutopilotRun?) -> JSONValue {
        let plan = run?.plan
        let ids = plan?.screens.map(\.id) ?? []
        let screens: [JSONValue] = (plan?.screens ?? []).map { screen in
            ["id": .string(screen.id), "name": .string(screen.name), "caption": .string(screen.caption)]
        }
        let cut = review.cut
        var current: [String: JSONValue] = [
            "version": .int(review.version),
            "screens": .array(cut.order(ids).map(JSONValue.string)),
            "seconds": .double(cut.targetSeconds),
            "captionScale": .double(cut.captionScaleValue),
            "endCard": [
                "caption": .bool(cut.showsEndCardCaption),
                "screen": .string(cut.endCardScreenID ?? cut.order(ids).first ?? ""),
            ],
        ]
        if let music = plan?.alsoMakes.previewMusic {
            current["music"] = .string(music.track.rawValue)
        }
        let library: [JSONValue] = AppPreviewTrack.library.map { track in
            ["id": .string(track.rawValue), "title": .string(track.title), "sounds": .string(track.mood)]
        }
        return [
            "action": "revise_app_preview",
            "note": .string(note),
            "current": .object(current),
            "planScreens": .array(screens),
            "musicLibrary": .array(library),
            "how": """
            The person watched the App Preview and asked for this change. Make it with revise_app_preview: the \
            screens that play and their order (plan screen IDs), its length (15–30 s), captionScale (0.8–1.4 for \
            bigger or smaller captions), the end card (which screen's caption it shows, or none), optionally the \
            preview's look as template fields or ops in appPreviewTemplate, and a library track in music for \
            calmer or brighter music. Say what changed in changes, in a short sentence the person reads. The \
            recordings stay as they are: to show something they don't have, tell the person to record again from \
            the plan. AppLocalizer makes every App Preview again with it and shows the new version.
            """,
        ]
    }
}
