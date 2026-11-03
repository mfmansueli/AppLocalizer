//
//  AutopilotRecordingBar.swift
//  AppLocalizer
//

import SwiftUI

/// The raw recording as a bar: grey between screens and after them, a
/// piece per moment (blue when it's in the App Preview), and the
/// playhead. A click on a piece jumps to its start.
struct AutopilotRecordingBar: View {
    let pieces: [AutopilotRecordingPiece]
    let seconds: Double
    let length: Double
    let seek: (Double) -> Void

    private static let gap: CGFloat = 2

    var body: some View {
        GeometryReader { proxy in
            let total = max(pieces.reduce(0) { $0 + $1.length }, 0.001)
            let room = max(proxy.size.width - Self.gap * CGFloat(max(pieces.count - 1, 0)), 0)
            ZStack(alignment: .leading) {
                HStack(spacing: Self.gap) {
                    ForEach(pieces) { piece in
                        Button {
                            seek(piece.start)
                        } label: {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color(piece.kind))
                                .frame(width: max(room * CGFloat(piece.length / total), 1), height: 8)
                                .contentShape(Rectangle().inset(by: -3))
                        }
                        .buttonStyle(.plain)
                        .help(Text(piece.title))
                        .accessibilityLabel(Text(piece.title))
                        .accessibilityIdentifier("autopilot.recording.piece.\(piece.id)")
                    }
                }
                RoundedRectangle(cornerRadius: 1)
                    .fill(Palette.label)
                    .frame(width: 2, height: 14)
                    .offset(x: proxy.size.width * CGFloat(min(max(seconds / max(length, 0.001), 0), 1)) - 1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .frame(height: 14)
        }
        .frame(height: 14)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.recording.bar")
    }

    private func color(_ kind: AutopilotRecordingPiece.Kind) -> Color {
        switch kind {
        case .between, .end: Palette.fill2
        case let .moment(chosen): chosen ? Color.accentColor : Palette.fill3
        }
    }
}
