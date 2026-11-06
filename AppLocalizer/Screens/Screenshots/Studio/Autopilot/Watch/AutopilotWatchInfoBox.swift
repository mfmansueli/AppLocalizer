//
//  AutopilotWatchInfoBox.swift
//  AppLocalizer
//

import SwiftUI

/// What the App Preview is: its length and scenes, sizes, poster frame,
/// Apple's checks, and its music, which is always on and changes without a
/// design step.
struct AutopilotWatchInfoBox: View {
    @Bindable var studio: ScreenshotStudioModel
    let file: ExtrasPreviewFile
    let isEditable: Bool

    var body: some View {
        VStack(spacing: 0) {
            row(String(localized: "Length"), studio.previewLengthLine(file), identifier: "length")
            Divider()
            row(String(localized: "Size"), studio.previewSizesLine, identifier: "size")
            Divider()
            row(String(localized: "Poster frame"), studio.previewPosterLine(file), identifier: "poster")
            Divider()
            row(String(localized: "Checks"), studio.previewChecksLine(file), identifier: "checks", isProblem: !file.problems.isEmpty)
            Divider()
            // The note goes under the menu: beside it, in Review's narrow
            // column, it wrapped a syllable a line (MB Admin's run).
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                label(String(localized: "Music"))
                VStack(alignment: .leading, spacing: 2) {
                    music
                    Text("Required · always on")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.xSmall)
        }
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.watch.info")
    }

    private func row(_ title: String, _ value: String, identifier: String, isProblem: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            label(title)
            Text(value)
                .foregroundStyle(isProblem ? Palette.warning : Palette.label)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("autopilot.watch.info.\(identifier)")
        }
        .font(.callout)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, 7)
    }

    private func label(_ title: String) -> some View {
        Text(title)
            .font(.callout)
            .foregroundStyle(Palette.label2)
            .frame(width: 92, alignment: .leading)
    }

    /// The library's tracks, the own file once there's one, and Your File…
    /// to choose another.
    private var music: some View {
        let current = studio.previewMusic
        return Menu(current.title) {
            ForEach(AppPreviewTrack.library, id: \.self) { track in
                choice(track.title, isOn: current.track == track) { studio.pickMusic(track) }
            }
            if current.track == .ownFile {
                choice(current.title, isOn: true) {}
            }
            Divider()
            Button("Your File…") { studio.chooseMusicFile() }
        }
        .menuStyle(.button)
        .controlSize(.small)
        .fixedSize()
        .disabled(!isEditable)
        .accessibilityLabel(Text("Music"))
        .accessibilityValue(Text(current.title))
        .accessibilityIdentifier("autopilot.watch.music")
    }

    private func choice(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if isOn { Label(title, systemImage: "checkmark") } else { Text(title) }
        }
    }
}
