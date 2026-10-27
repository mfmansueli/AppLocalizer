//
//  CaptureCoverageRowView.swift
//  AppLocalizer
//

import SwiftUI

/// One locale's captures: its name, where they came from, and each slot's
/// capture labelled Localized, English UI or Wrong size.
struct CaptureCoverageRowView: View {
    let row: CaptureCoverage.Row
    let thumbnailWidth: CGFloat
    let images: CaptureImageStore

    /// Captures load at twice the thumbnail's width.
    private var imageWidth: Int { Int(thumbnailWidth * 2) }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: Spacing.xSmall) {
                FlagTile(regionCode: row.locale.regionCode)
                    .frame(width: 20)
                Text(row.locale.name)
                    .font(.callout)
                    .lineLimit(1)
            }
            .frame(width: CaptureCoverageView.localeWidth, alignment: .leading)
            Text(row.sourceText)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
                .frame(width: CaptureCoverageView.sourceWidth, alignment: .leading)
            ForEach(row.cells) { cell in
                cellView(cell)
                    .frame(width: thumbnailWidth + 24, alignment: .leading)
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .onAppear {
            images.request(row.cells.compactMap(\.capture), width: imageWidth)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("captures.coverage.\(row.locale.code)")
    }

    private func cellView(_ cell: CaptureCoverage.Cell) -> some View {
        VStack(spacing: Spacing.xxSmall) {
            ZStack(alignment: .topLeading) {
                thumbnail(cell)
                if case .primaryInterface = cell.label {
                    InterfaceChip()
                        .offset(x: 3, y: 3)
                }
            }
            Text(cell.label.title)
                .font(.caption)
                .foregroundStyle(labelColor(cell.label))
                .lineLimit(1)
                .fixedSize()
        }
        .frame(width: thumbnailWidth + 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(row.locale.name) capture \(cell.slot + 1), \(cell.label.title)"))
    }

    @ViewBuilder
    private func thumbnail(_ cell: CaptureCoverage.Cell) -> some View {
        let height = thumbnailWidth * aspect(of: cell.capture)
        if let image = images.image(for: cell.capture, width: imageWidth) {
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFill()
                .frame(width: thumbnailWidth, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(cell.label == .wrongSize ? Palette.dangerMark : Palette.separator, lineWidth: cell.label == .wrongSize ? 1.5 : 0.5)
                }
        } else {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Palette.fill1)
                .frame(width: thumbnailWidth, height: height)
                .overlay {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(Palette.separator, style: StrokeStyle(lineWidth: 0.5, dash: cell.capture == nil ? [3, 2] : []))
                }
        }
    }

    private func aspect(of capture: ScreenshotCapture?) -> CGFloat {
        guard let size = capture?.pixelSize, size.width > 0 else { return thumbnailWidth > 50 ? 0.75 : 2.17 }
        return CGFloat(size.height) / CGFloat(size.width)
    }

    private func labelColor(_ label: CaptureCoverage.Label) -> Color {
        switch label {
        case .localized: Palette.label2
        case .primaryInterface, .missing: Palette.label3
        case .wrongSize: Palette.danger
        }
    }
}
