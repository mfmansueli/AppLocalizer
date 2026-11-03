//
//  ArtworkHeaderGuide.swift
//  AppLocalizer
//

import SwiftUI

/// Show iPhone Area over the 21:9 header in the viewer: on iPhone only
/// the middle shows (the sides go), and the status bar, Back and Share sit
/// over the top, so the name and line belong inside the dashed box.
struct ArtworkHeaderGuide: View {
    /// The top that sits under the status bar, Back and Share.
    static let topFraction = CGFloat(ArtworkSafeArea.iPhoneHeaderTop)
    /// Each side iPhone leaves out.
    static let sideFraction = CGFloat(ArtworkSafeArea.iPhoneHeaderSide)

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let top = size.height * Self.topFraction
            let side = size.width * Self.sideFraction
            let shade = Color.black.opacity(0.38)
            ZStack(alignment: .topLeading) {
                shade.frame(width: size.width, height: top)
                shade.frame(width: side, height: size.height - top).offset(y: top)
                shade.frame(width: side, height: size.height - top).offset(x: size.width - side, y: top)
                Rectangle()
                    .strokeBorder(.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .frame(width: size.width - side * 2, height: size.height - top)
                    .offset(x: side, y: top)
                Text("Shown on iPhone · keep the name and line inside")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
                    .offset(x: side + 8, y: size.height * 0.24)
                Text("Status bar, Back and Share sit here")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: size.width)
                    .offset(y: size.height * 0.04)
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("studio.viewer.headerGuide")
    }
}
