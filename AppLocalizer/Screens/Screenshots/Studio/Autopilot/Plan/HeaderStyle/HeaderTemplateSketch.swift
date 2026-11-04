//
//  HeaderTemplateSketch.swift
//  AppLocalizer
//

import SwiftUI

/// A scene template's preview on the plan, in the app's icon colors: its
/// sky, layers, frame or shapes behind a bar where the name goes. With
/// Motion loop it plays its loop (20 s), unless Reduce Motion is on.
struct HeaderTemplateSketch: View {
    let template: AutopilotHeaderTemplate
    let light: Color
    let dark: Color
    var isMoving = false
    var width: CGFloat = 200

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let size = AutopilotArtworkKind.header.pixelSize
        let height = (width * CGFloat(size.height) / CGFloat(size.width)).rounded()
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !isMoving || reduceMotion)) { timeline in
            let loop = Double(AutopilotArtworkMotion.loopSeconds)
            let phase = isMoving && !reduceMotion
                ? timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: loop) / loop
                : 0.3
            Canvas { context, canvas in
                HeaderTemplatePainter(template: template, light: light, dark: dark, phase: phase).draw(in: &context, size: canvas)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityHidden(true)
    }
}
