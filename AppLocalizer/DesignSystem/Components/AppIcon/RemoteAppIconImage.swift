//
//  RemoteAppIconImage.swift
//  AppLocalizer
//

import SwiftUI

/// An icon App Store Connect serves, filling its frame without the margin
/// a Mac icon comes with; `placeholder` until it has downloaded, or if it
/// can't be.
struct RemoteAppIconImage<Placeholder: View>: View {
    let url: URL
    var images: AppIconImages = .shared
    @ViewBuilder var placeholder: Placeholder

    @State private var image: CGImage?

    var body: some View {
        Group {
            if let image = image ?? images.cached(url) {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.high)
            } else {
                placeholder
            }
        }
        .task(id: url) { image = await images.image(for: url) }
    }
}
