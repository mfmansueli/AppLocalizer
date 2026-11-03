//
//  AppPreviewPlayer.swift
//  AppLocalizer
//

import SwiftUI

/// An App Preview playing in place: the video (click it to play or pause;
/// its poster while there's no file), Play or Pause, where it is, Sound On
/// or Off, a bar per scene to jump to, and the music under it.
struct AppPreviewPlayer: View {
    let model: AppPreviewPlayerModel
    let file: ExtrasPreviewFile
    let url: URL
    /// "Warm acoustic".
    let musicTitle: String
    let poster: AppPreviewPosterView?
    let width: CGFloat

    var body: some View {
        VStack(spacing: Spacing.small) {
            Button {
                model.toggle()
            } label: {
                video
            }
            .buttonStyle(.plain)
            .help(Text(model.isPlaying ? "Pause" : "Play"))
            .accessibilityLabel(Text(model.isPlaying ? "Pause the App Preview" : "Play the App Preview"))
            .accessibilityIdentifier("appPreview.video")
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                HStack(spacing: Spacing.small) {
                    Button(model.isPlaying ? "Pause" : "Play") { model.toggle() }
                        .controlSize(.small)
                        .frame(minWidth: 64)
                        .disabled(!model.canPlay)
                        .accessibilityIdentifier("appPreview.play")
                    Text(model.timeTitle)
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(Palette.label2)
                        .accessibilityIdentifier("appPreview.time")
                    Spacer(minLength: 0)
                    Button(model.isMuted ? "Sound Off" : "Sound On") { model.isMuted.toggle() }
                        .controlSize(.small)
                        .accessibilityValue(Text(model.isMuted ? "Off" : "On"))
                        .accessibilityIdentifier("appPreview.sound")
                }
                if let scenes = file.scenes, !scenes.isEmpty {
                    AppPreviewTimeline(scenes: scenes, seconds: model.seconds) { model.seek(to: $0) }
                }
                Text(musicLine)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("appPreview.music")
            }
            .frame(width: max(width, 260))
        }
        .task(id: url) { model.load(url, seconds: file.seconds) }
    }

    private var height: CGFloat {
        let size = file.pixelSize
        return (width * CGFloat(size.height) / CGFloat(max(size.width, 1))).rounded()
    }

    private var video: some View {
        Group {
            if model.canPlay {
                AppPreviewVideoSurface(player: model.player)
                    .allowsHitTesting(false)
            } else if let poster {
                poster
            } else {
                Palette.fill2
            }
        }
        .frame(width: width, height: height)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: max(6, width * 0.06), style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 12, y: 6)
        .contentShape(Rectangle())
    }

    /// "♫ Warm acoustic · muted here · under the captions, fades out from 0:22".
    private var musicLine: String {
        let fade = ExtrasPreviewFile.lengthTitle(max(0, file.seconds - AppPreviewSoundtrack.fadeOutSeconds))
        var parts = ["♫ " + musicTitle]
        if model.isMuted { parts.append(String(localized: "muted here")) }
        parts.append(String(localized: "under the captions, fades out from \(fade)"))
        if !model.canPlay { parts.append(String(localized: "the file isn’t on this Mac")) }
        return parts.joined(separator: " · ")
    }
}
