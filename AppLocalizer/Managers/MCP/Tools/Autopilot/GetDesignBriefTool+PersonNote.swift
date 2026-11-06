//
//  GetDesignBriefTool+PersonNote.swift
//  AppLocalizer
//

import Foundation

/// What the person told the designer at Look. The guided Autopilot has one
/// note for the screenshot looks and the header alike; the header's part
/// is artworkDesign's askedByThePerson, and this is the screenshots'.
extension GetDesignBriefTool {
    /// `personNote` (the words and the references' names) when the run
    /// designs screenshots and the person wrote something.
    static func addPersonNote(_ result: inout [String: JSONValue], run: AutopilotRun, referenceURL: ((AutopilotArtworkReference) -> URL?)? = nil) {
        let plan = run.plan
        let note = plan.alsoMakes.artworkDirection
        guard plan.makesScreenshots, plan.screenshotStyle != .keep, !note.isEmpty else { return }
        var json: [String: JSONValue] = [
            "says": """
            What the person told the designer when they set the run up. Every screenshot direction follows it: say how \
            in its rationale. References give the feel, not the content.
            """,
        ]
        if !note.trimmedText.isEmpty { json["text"] = .string(note.trimmedText) }
        if !note.references.isEmpty {
            json["references"] = .array(note.references.map { reference in
                var item: [String: JSONValue] = ["name": .string(reference.name), "kind": .string(reference.isVideo ? "video" : "image")]
                if let url = referenceURL?(reference) { item["path"] = .string(url.path) }
                return .object(item)
            })
        }
        result["personNote"] = .object(json)
    }
}
