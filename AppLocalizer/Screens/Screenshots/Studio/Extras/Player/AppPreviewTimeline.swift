//
//  AppPreviewTimeline.swift
//  AppLocalizer
//

import SwiftUI

/// A bar per scene, as wide as it plays, filling as it plays, with its
/// name under it; clicking one jumps to its start.
struct AppPreviewTimeline: View {
    let scenes: [ExtrasPreviewScene]
    let seconds: Double
    let seek: (Double) -> Void

    var body: some View {
        let total = max(scenes.map(\.end).max() ?? 1, 0.1)
        GeometryReader { proxy in
            let gaps = CGFloat(max(scenes.count - 1, 0)) * 3
            HStack(spacing: 3) {
                ForEach(Array(scenes.enumerated()), id: \.offset) { _, scene in
                    let isCurrent = seconds >= scene.start && seconds < scene.end
                    Button {
                        seek(scene.start)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Capsule()
                                .fill(Palette.fill3)
                                .overlay(alignment: .leading) {
                                    GeometryReader { bar in
                                        Capsule().fill(Palette.accent).frame(width: bar.size.width * fill(of: scene))
                                    }
                                }
                                .frame(height: 5)
                            Text(scene.title)
                                .font(.caption2.weight(isCurrent ? .semibold : .regular))
                                .foregroundStyle(isCurrent ? Palette.label : Palette.label2)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: max(8, (proxy.size.width - gaps) * CGFloat(scene.duration / total)))
                    .accessibilityLabel(Text("Go to \(scene.title)"))
                    .accessibilityValue(Text(isCurrent ? "Playing" : ""))
                    .accessibilityIdentifier("appPreview.scene.\(scene.screenID ?? "endCard")")
                }
            }
        }
        .frame(height: 24)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appPreview.timeline")
    }

    private func fill(of scene: ExtrasPreviewScene) -> CGFloat {
        guard scene.duration > 0 else { return 0 }
        return CGFloat(min(max((seconds - scene.start) / scene.duration, 0), 1))
    }
}
