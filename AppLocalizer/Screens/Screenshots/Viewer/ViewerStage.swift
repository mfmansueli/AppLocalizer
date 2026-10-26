//
//  ViewerStage.swift
//  AppLocalizer
//

import SwiftUI

/// The viewer's left side: the cell at full size on the stage color,
/// rendered at twice its displayed width (or the live screenshot).
struct ViewerStage: View {
    let viewModel: ScreenshotsViewModel
    let cell: ScreenshotCell?
    @State private var image: CGImage?

    var body: some View {
        ZStack {
            Palette.stage
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: width, height: height)
                    .accessibilityLabel(Text(accessibilityText))
            } else {
                Palette.fill2
                    .frame(width: width, height: height)
                    .overlay {
                        if cell?.image != CellImageSource.none { ProgressView().controlSize(.small) }
                    }
                    .accessibilityHidden(true)
            }
        }
        .task(id: cell?.id) {
            image = nil
            image = await load()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.viewer.image")
    }

    private var width: CGFloat { viewModel.viewerImageWidth }

    private var height: CGFloat {
        let size = viewModel.pixelSize(for: viewModel.displayType)
        return (width * CGFloat(size.height) / CGFloat(max(1, size.width))).rounded()
    }

    private func load() async -> CGImage? {
        guard let cell else { return nil }
        switch cell.image {
        case let .render(job):
            return await viewModel.renderQueue.largeImage(for: job, pixelWidth: viewModel.viewerPixelWidth)
        case let .live(shot):
            return await viewModel.services.liveImage(shot, pixelWidth: viewModel.viewerPixelWidth)
        case .none:
            return nil
        }
    }

    private var accessibilityText: String {
        guard let cell else { return "" }
        let name = viewModel.locale(code: cell.key.locale)?.name ?? cell.key.locale
        return String(localized: "Screenshot, \(name), slot \(cell.key.slot + 1)")
    }
}
