//
//  GuidedMusicRow.swift
//  AppLocalizer
//

import SwiftUI

/// App Preview music: a track from AppLocalizer's library, or Your File…
/// (chosen again when it's already chosen). Every App Preview has music.
struct GuidedMusicRow: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan

    var body: some View {
        let current = plan.alsoMakes.previewMusic
        let options: [StudioSegmentedControl<AppPreviewTrack>.Option] = AppPreviewTrack.allCases.map { track in
            let title = track == .ownFile
                ? (current.track == .ownFile ? current.title : String(localized: "Your File…"))
                : track.title
            return .init(value: track, title: title, key: track.rawValue)
        }
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("App Preview music")
                .font(.headline)
                .frame(width: 150, alignment: .leading)
            StudioSegmentedControl(
                label: String(localized: "App Preview music"), options: options,
                selection: Binding { current.track } set: { studio.pickMusic($0) },
                identifier: "autopilot.guided.look.music"
            )
            Text(AutopilotRunChoiceCard.musicNote)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.look.musicRow")
    }
}
