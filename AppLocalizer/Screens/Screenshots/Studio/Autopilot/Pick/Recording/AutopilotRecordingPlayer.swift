//
//  AutopilotRecordingPlayer.swift
//  AppLocalizer
//

import SwiftUI

/// The raw recording playing in a phone or iPad frame (click it to play or
/// pause), back and forward 5 seconds, Play or Pause, where it is, "RAW",
/// the bar to click or drag through it, and the bar of its moments to jump
/// to. At Pick and in the viewer.
struct AutopilotRecordingPlayer: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    /// The video's width.
    let width: CGFloat

    var body: some View {
        let player = studio.recordingPlayer
        let target = studio.currentPickRecording(run)
        let recording = target.flatMap(run.recording(for:))
        let isPad = target?.displayType == .iPad
        VStack(spacing: Spacing.small) {
            Button {
                player.toggle()
            } label: {
                video(recording: recording, isPad: isPad)
            }
            .buttonStyle(.plain)
            .help(Text(player.isPlaying ? "Pause" : "Play"))
            .accessibilityLabel(Text(player.isPlaying ? "Pause the recording" : "Play the recording"))
            .accessibilityIdentifier("autopilot.recording.video")
            VStack(alignment: .leading, spacing: 7) {
                PlayerControls(
                    identifier: "autopilot.recording", isPlaying: player.isPlaying, canPlay: player.canPlay, seconds: player.seconds,
                    duration: recording?.seconds ?? player.duration, timeTitle: studio.recordingTimeTitle(run),
                    playLabel: Text("Play the recording"), pauseLabel: Text("Pause the recording"), toggle: player.toggle,
                    seek: player.seek(to:), scrubbing: player.scrub
                ) {
                    Text("RAW")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .frame(height: 18)
                        .background(Color(red: 0xE5 / 255, green: 0x48 / 255, blue: 0x4D / 255), in: Capsule())
                }
                AutopilotRecordingBar(
                    pieces: studio.recordingPieces(run), seconds: player.seconds,
                    length: recording?.seconds ?? player.duration
                ) { player.seek(to: $0) }
                Text("No captions or music yet. Blue: moments in the App Preview. Click the bar to jump.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: max(width + 14, 300))
        }
        .task(id: target) { studio.loadPickRecording(run) }
    }

    private func video(recording: AutopilotRecording?, isPad: Bool) -> some View {
        let size = recording?.pixelSize ?? PixelSize(width: 1320, height: 2868)
        let height = (width * CGFloat(size.height) / CGFloat(max(size.width, 1))).rounded()
        let outer: CGFloat = isPad ? 18 : 30
        let inner: CGFloat = isPad ? 11 : 23
        let player = studio.recordingPlayer
        return ZStack {
            Group {
                if player.canPlay {
                    AppPreviewVideoSurface(player: player.player).allowsHitTesting(false)
                } else {
                    Palette.fill2.overlay(Text("The file isn’t on this Mac").font(.caption).foregroundStyle(Palette.label2))
                }
            }
            .frame(width: width, height: height)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: inner, style: .continuous))
            if !player.isPlaying {
                Circle()
                    .fill(.black.opacity(0.45))
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: "play.fill").font(.system(size: 22)).foregroundStyle(.white).offset(x: 2))
                    .accessibilityHidden(true)
            }
        }
        .padding(7)
        .background(Color(white: 0.11), in: RoundedRectangle(cornerRadius: outer, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 15, y: 10)
        .contentShape(Rectangle())
    }
}
