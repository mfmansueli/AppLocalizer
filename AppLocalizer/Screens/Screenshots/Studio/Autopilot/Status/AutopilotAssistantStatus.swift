//
//  AutopilotAssistantStatus.swift
//  AppLocalizer
//

import SwiftUI

/// Who's working on the run, at Capture and Design: the Claude Code
/// AppLocalizer started, what it's doing now and for how long (with Show
/// Output and Stop), or, when nobody works on it, why, with Continue.
struct AutopilotAssistantStatus: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    /// What Claude Code may do at this stage, under its status.
    var launchNote: String?

    var body: some View {
        if let launched = studio.launchedRun, launched.isActive || launched.failure != nil || !launched.denials.isEmpty {
            if let launchNote {
                AutopilotLaunchStatus(studio: studio, run: launched, note: launchNote)
            } else {
                AutopilotLaunchStatus(studio: studio, run: launched)
            }
        }
        // Looked at again each minute: a pasted run goes quiet with time.
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            if let stall = studio.stall {
                AutopilotStallNotice(studio: studio, run: run, stall: stall)
            }
        }
    }
}
