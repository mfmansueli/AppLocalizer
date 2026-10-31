//
//  StudioShotImage.swift
//  AppLocalizer
//

import SwiftUI

/// A screenshot's image at `width` points, or a placeholder while it
/// renders or loads.
struct StudioShotImage: View {
    let image: CGImage?
    let width: CGFloat
    /// Height ÷ width.
    let aspect: Double
    /// The corner radius as a fraction of the width: Apple Watch's screen
    /// is much rounder.
    var cornerFraction: CGFloat = 0.05

    var body: some View {
        let height = (width * aspect).rounded()
        ZStack {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
            } else {
                Rectangle().fill(.quaternary)
                ProgressView().controlSize(.small)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: max(4, width * cornerFraction), style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: max(4, width * cornerFraction), style: .continuous).strokeBorder(.separator, lineWidth: 0.5)
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}
