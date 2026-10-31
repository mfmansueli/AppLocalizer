//
//  AutopilotPickColumn.swift
//  AppLocalizer
//

import SwiftUI

/// One screen's captures: the pick, large, with the assistant's reason,
/// then the others, small, with why they lost. Clicking one picks it.
struct AutopilotPickColumn: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let screen: AutopilotScreen
    let index: Int
    /// The column's width; the pick fills it.
    let width: CGFloat
    let isEditable: Bool

    var body: some View {
        let candidates = run.candidates(for: screen.id)
        let picked = run.pickedCapture(for: screen.id)
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("\(index + 1) · \(screen.name)").font(.headline)
            if let picked {
                ZStack(alignment: .topLeading) {
                    StudioShotImage(image: studio.image(for: picked, width: 360), width: width - 6, aspect: aspect(picked))
                    if picked.id == candidates.first?.id, candidates.count > 1 {
                        Text("Best of \(candidates.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.accentText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.background, in: Capsule())
                            .padding(6)
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.accentColor, lineWidth: 2).padding(-3))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(screen.name), picked: \(picked.notes)"))
                .accessibilityIdentifier("autopilot.pick.picked.\(index)")
                Text(picked.notes)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No capture").foregroundStyle(Palette.label2).frame(width: width - 6, height: 200)
            }
            let others = candidates.filter { $0.id != picked?.id }
            if !others.isEmpty {
                let otherWidth = ((width - 6 - Spacing.xSmall * CGFloat(others.count - 1)) / CGFloat(others.count)).rounded(.down)
                HStack(alignment: .top, spacing: Spacing.xSmall) {
                    ForEach(others) { capture in
                        Button {
                            studio.pick(capture, for: screen.id)
                        } label: {
                            StudioShotImage(image: studio.image(for: capture, width: 160), width: otherWidth, aspect: aspect(capture))
                        }
                        .buttonStyle(.plain)
                        .disabled(!isEditable)
                        .help(Text(capture.notes))
                        .accessibilityLabel(Text("Pick attempt \(capture.attempt): \(capture.notes)"))
                        .accessibilityIdentifier("autopilot.pick.other.\(index).\(capture.attempt)")
                    }
                }
                ForEach(others) { capture in
                    Text(capture.notes)
                        .font(.caption)
                        .foregroundStyle(Palette.label3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.leading, 3)
        .frame(width: width, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private func aspect(_ capture: AutopilotCapture) -> Double {
        Double(capture.pixelSize.height) / Double(max(capture.pixelSize.width, 1))
    }
}
