//
//  PlayerControls.swift
//  AppLocalizer
//

import SwiftUI

/// A video's controls under it: back 5 seconds, Play or Pause, forward 5
/// seconds, where it is, anything else the player shows (`trailing`), and
/// the bar to click or drag through it. Identifiers hang off `identifier`:
/// `.play`, `.back`, `.forward`, `.time`, `.scrubber`.
struct PlayerControls<Trailing: View>: View {
    /// `"appPreview"`.
    let identifier: String
    let isPlaying: Bool
    var canPlay = true
    let seconds: Double
    let duration: Double
    /// "0:08 / 0:24", as the player says it.
    let timeTitle: String
    /// What Play and Pause are called for VoiceOver ("Play the loop").
    var playLabel = Text("Play")
    var pauseLabel = Text("Pause")
    let toggle: () -> Void
    let seek: (Double) -> Void
    var scrubbing: (Bool) -> Void = { _ in }
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: Spacing.small) {
                Button {
                    seek(max(seconds - PlayerScrubber.step, 0))
                } label: {
                    Image(systemName: "gobackward.5")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Palette.label)
                        .frame(width: 26, height: 24)
                        .contentShape(Rectangle())
                }
                .disabled(!canPlay)
                .help(Text("Back 5 seconds"))
                .accessibilityLabel(Text("Back 5 seconds"))
                .accessibilityIdentifier("\(identifier).back")
                Button(isPlaying ? "Pause" : "Play", action: toggle)
                    .buttonStyle(.bordered)
                    .frame(minWidth: 64)
                    .disabled(!canPlay)
                    .accessibilityLabel(isPlaying ? pauseLabel : playLabel)
                    .accessibilityIdentifier("\(identifier).play")
                Button {
                    seek(min(seconds + PlayerScrubber.step, duration))
                } label: {
                    Image(systemName: "goforward.5")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Palette.label)
                        .frame(width: 26, height: 24)
                        .contentShape(Rectangle())
                }
                .disabled(!canPlay)
                .help(Text("Forward 5 seconds"))
                .accessibilityLabel(Text("Forward 5 seconds"))
                .accessibilityIdentifier("\(identifier).forward")
                Text(timeTitle)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
                    .accessibilityIdentifier("\(identifier).time")
                Spacer(minLength: 0)
                trailing()
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            PlayerScrubber(
                identifier: "\(identifier).scrubber", seconds: seconds, duration: duration, isEnabled: canPlay,
                seek: seek, scrubbing: scrubbing
            )
        }
    }
}

extension PlayerControls where Trailing == EmptyView {
    init(
        identifier: String, isPlaying: Bool, canPlay: Bool = true, seconds: Double, duration: Double, timeTitle: String,
        playLabel: Text = Text("Play"), pauseLabel: Text = Text("Pause"), toggle: @escaping () -> Void,
        seek: @escaping (Double) -> Void, scrubbing: @escaping (Bool) -> Void = { _ in }
    ) {
        self.init(
            identifier: identifier, isPlaying: isPlaying, canPlay: canPlay, seconds: seconds, duration: duration, timeTitle: timeTitle,
            playLabel: playLabel, pauseLabel: pauseLabel, toggle: toggle, seek: seek, scrubbing: scrubbing
        ) { EmptyView() }
    }
}
