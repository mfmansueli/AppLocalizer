//
//  AppPreviewPosterView.swift
//  AppLocalizer
//

import SwiftUI

/// The App Preview's poster drawn small in the direction's look: the
/// first screen's caption over the app, full screen (no device frame, as
/// Apple wants), a play button and the length.
struct AppPreviewPosterView: View {
    let template: ScreenshotTemplate
    let headline: String
    let capture: CGImage?
    /// "0:24".
    let length: String
    let width: CGFloat

    var body: some View {
        let height = (width * 1920 / 886).rounded()
        ZStack(alignment: .top) {
            background
            VStack(spacing: width * 0.06) {
                Text(headline)
                    .font(.system(size: max(5, width * 0.085), weight: .bold))
                    .foregroundStyle((TemplateColor(template.caption.ink) ?? .white).color)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, width * 0.08)
                    .padding(.top, width * 0.09)
                Group {
                    if let capture {
                        Image(decorative: capture, scale: 1).resizable().scaledToFill()
                    } else {
                        Color(white: 0.11)
                    }
                }
                .frame(width: width * 0.72, height: height * 0.66, alignment: .top)
                .clipShape(RoundedRectangle(cornerRadius: width * 0.07, style: .continuous))
            }
            Image(systemName: "play.fill")
                .font(.system(size: width * 0.13))
                .foregroundStyle(.white)
                .frame(width: width * 0.3, height: width * 0.3)
                .background(.black.opacity(0.45), in: Circle())
                .frame(maxHeight: .infinity)
            Text(length)
                .font(.system(size: max(7, width * 0.075), weight: .semibold).monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, max(3, width * 0.05))
                .frame(height: max(9, width * 0.12))
                .background(.black.opacity(0.55), in: Capsule())
                .padding(max(3, width * 0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: max(3, width * 0.07), style: .continuous))
        .accessibilityElement()
        .accessibilityLabel(Text("App Preview, \(length)"))
    }

    @ViewBuilder
    private var background: some View {
        let stops = template.background.stops.compactMap(TemplateColor.init).map(\.color)
        if stops.count > 1 {
            LinearGradient(colors: stops, startPoint: .top, endPoint: .bottom)
        } else {
            stops.first ?? Color.black
        }
    }
}
