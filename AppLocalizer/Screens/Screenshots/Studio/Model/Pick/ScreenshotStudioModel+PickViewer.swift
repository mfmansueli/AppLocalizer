//
//  ScreenshotStudioModel+PickViewer.swift
//  AppLocalizer
//

import Foundation

/// Pick in the full-size viewer: a screen's attempts (with Use This
/// Capture), iPhone Duo's displays, Apple Watch's picks and the raw
/// recording.
extension ScreenshotStudioModel {
    /// A screen's attempts, best first, at `index`.
    func openAttempts(_ run: AutopilotRun, screenID: String, at index: Int) {
        show(attemptItems(run, screenID: screenID), at: index)
    }

    /// "1 · Today · attempt 2 of 3", "Ranked lower: keyboard covers the
    /// list", with Use This Capture.
    func attemptItems(_ run: AutopilotRun, screenID: String) -> [StudioViewerItem] {
        let attempts = pickAttempts(run, screenID: screenID)
        let name = run.plan.screen(id: screenID)?.name ?? screenID
        let slot = run.plan.slot(of: screenID) ?? 0
        let client = run.clientName(assistant: nil)
        return attempts.map { attempt in
            let notes = attempt.capture.notes
            return StudioViewerItem(
                id: "attempt.\(attempt.capture.id)",
                title: String(localized: "\(slot + 1) · \(name) · attempt \(attempt.rank + 1) of \(attempts.count)"),
                subtitle: attempt.isBest ? String(localized: "\(client)’s pick: \(notes)") : String(localized: "Ranked lower: \(notes)"),
                content: .capture(attempt.capture),
                action: .useCapture(captureID: attempt.capture.id, screenID: screenID, screenName: name, isUsed: attempt.isUsed)
            )
        }
    }

    /// iPhone Duo's displays of each screen, at the screen `index`.
    func openDuoPicks(_ run: AutopilotRun, at index: Int) {
        var items: [StudioViewerItem] = []
        var shown = 0
        for (offset, screen) in run.plan.screens.enumerated() {
            let captures = duoCaptures(run, screenID: screen.id)
            let title = String(localized: "\(offset + 1) · \(screen.name) · iPhone Duo")
            if offset == index { shown = items.count }
            if let inner = captures.inner, let cover = captures.cover {
                items.append(StudioViewerItem(
                    id: "duo.\(screen.id)", title: title, subtitle: String(localized: "Inner and cover display"),
                    content: .duoPair(inner: inner, cover: cover)
                ))
            } else if let capture = captures.inner ?? captures.cover {
                items.append(StudioViewerItem(
                    id: "duo.\(screen.id)", title: title,
                    subtitle: captures.inner != nil ? String(localized: "Inner display") : String(localized: "Cover display"),
                    content: .capture(capture)
                ))
            }
        }
        show(items, at: shown)
    }

    /// Apple Watch's picks, at `index`.
    func openWatchPicks(_ run: AutopilotRun, at index: Int) {
        let client = run.clientName(assistant: nil)
        var items: [StudioViewerItem] = []
        var shown = 0
        for (offset, screen) in run.plan.screens(on: .watch).enumerated() {
            guard let picked = run.pickedCapture(for: screen.id) else { continue }
            if offset == index { shown = items.count }
            let count = run.candidates(for: screen.id).count
            items.append(StudioViewerItem(
                id: "watch.\(screen.id)", title: String(localized: "\(offset + 1) · \(screen.name) · Apple Watch"),
                subtitle: count > 1 ? String(localized: "Best of \(count), ranked by \(client)") : String(localized: "Ranked by \(client)"),
                content: .capture(picked)
            ))
        }
        show(items, at: shown)
    }

    /// The raw recording Pick shows, playing in the viewer.
    func openRecording(_ run: AutopilotRun) {
        guard let target = currentPickRecording(run), let recording = run.recording(for: target) else { return }
        let client = run.clientName(assistant: nil)
        recordingPlayer.pause()
        viewer = StudioViewer(items: [StudioViewerItem(
            id: "recording.\(recording.id)", title: recordingTitle(run),
            subtitle: String(localized: "Raw, as \(client) recorded it: no captions or music yet · click to play or pause"),
            content: .recording(recording)
        )])
    }
}
