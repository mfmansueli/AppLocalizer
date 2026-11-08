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
        let options: [StudioSegmentedControl<AppPreviewTrack>.Option] = (AppPreviewTrack.featured + [.ownFile]).map { track in
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
            more(current)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                if plan.alsoMakes.music == nil, let pick = plan.alsoMakes.suggestedMusic, !pick.reason.isEmpty {
                    Text("Picked for this app: \(pick.reason)")
                        .font(.caption.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("autopilot.guided.look.musicPick")
                }
                Text(Self.note)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { studio.useKnownMusicPick() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.look.musicRow")
    }

    /// The library's other moods; its title is the track when it's one of
    /// them.
    private func more(_ current: AutopilotPreviewMusic) -> some View {
        Menu(AppPreviewTrack.more.contains(current.track) ? current.title : String(localized: "More Moods")) {
            ForEach(AppPreviewTrack.more, id: \.self) { track in
                Button(track.title) { studio.pickMusic(track) }
            }
        }
        .menuStyle(.button)
        .controlSize(.small)
        .fixedSize()
        .accessibilityIdentifier("autopilot.guided.look.musicMore")
    }

    /// "Required for every App Preview. Tracks from AppLocalizer’s
    /// library are licensed…".
    static var note: AttributedString {
        var required = AttributedString(localized: "Required")
        required.font = .caption.weight(.semibold)
        let rest = AttributedString(localized: """
         for every App Preview. Tracks from AppLocalizer’s library are licensed for the App Store; with your own file, \
        you confirm you hold the rights. Mixed under the captions, faded out at the end.
        """)
        return required + rest
    }
}
