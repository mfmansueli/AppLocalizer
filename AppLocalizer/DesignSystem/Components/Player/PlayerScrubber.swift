//
//  PlayerScrubber.swift
//  AppLocalizer
//

import SwiftUI

/// A video's position as a bar: filled up to where it is, with a knob.
/// Click anywhere to jump there, drag to scrub; VoiceOver steps it 5
/// seconds at a time.
struct PlayerScrubber: View {
    /// `"appPreview.scrubber"`.
    let identifier: String
    let seconds: Double
    let duration: Double
    var isEnabled = true
    let seek: (Double) -> Void
    /// A drag starts (true) or ends (false), so playback can wait for it.
    var scrubbing: (Bool) -> Void = { _ in }
    @State private var isDragging = false

    private static let knob: CGFloat = 12
    /// How far back and forward step, by button or VoiceOver.
    static let step: Double = 5

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let fraction = Self.fraction(seconds, of: duration)
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.fill3).frame(height: 4)
                Capsule()
                    .fill(isEnabled ? Palette.accent : Palette.fill3)
                    .frame(width: width * fraction, height: 4)
                Circle()
                    .fill(Color.white)
                    .frame(width: Self.knob, height: Self.knob)
                    .shadow(color: .black.opacity(0.35), radius: 1.5, y: 0.5)
                    .offset(x: min(max(width * fraction - Self.knob / 2, 0), width - Self.knob))
                    .opacity(isEnabled ? 1 : 0)
            }
            .frame(width: width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isEnabled, duration > 0 else { return }
                        if !isDragging {
                            isDragging = true
                            scrubbing(true)
                        }
                        seek(Self.seconds(at: value.location.x, width: width, duration: duration))
                    }
                    .onEnded { _ in
                        guard isDragging else { return }
                        isDragging = false
                        scrubbing(false)
                    }
            )
        }
        .frame(height: 16)
        .help(Text("Click or drag to move through the video"))
        .accessibilityElement()
        .accessibilityLabel(Text("Position"))
        .accessibilityValue(Text("\(Self.title(seconds)) of \(Self.title(duration))"))
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            switch direction {
            case .increment: seek(min(seconds + Self.step, duration))
            case .decrement: seek(max(seconds - Self.step, 0))
            @unknown default: break
            }
        }
        .accessibilityIdentifier(identifier)
    }

    /// How far along `seconds` is, from 0 to 1.
    static func fraction(_ seconds: Double, of duration: Double) -> CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(min(max(seconds / duration, 0), 1))
    }

    /// The moment under `x` on a bar `width` wide.
    static func seconds(at x: CGFloat, width: CGFloat, duration: Double) -> Double {
        Double(min(max(x / max(width, 1), 0), 1)) * duration
    }

    /// "0:07".
    static func title(_ seconds: Double) -> String {
        Duration.seconds(max(0, seconds.rounded(.down))).formatted(.time(pattern: .minuteSecond))
    }
}
