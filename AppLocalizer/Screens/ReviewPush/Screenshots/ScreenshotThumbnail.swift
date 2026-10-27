//
//  ScreenshotThumbnail.swift
//  AppLocalizer
//

import SwiftUI

/// A small screenshot in review and push lists: the image, a placeholder
/// that says what's there instead ("Uses English (U.S.)", "None"), or a
/// spinner while it renders.
struct ScreenshotThumbnail: View {
    let image: CGImage?
    let width: CGFloat
    /// Height ÷ width.
    let aspect: CGFloat
    var placeholder: String?
    var isLoading = false

    var body: some View {
        ZStack {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
            } else if let placeholder {
                Text(placeholder)
                    .font(.system(size: placeholderSize))
                    .foregroundStyle(Palette.label3)
                    .multilineTextAlignment(.center)
                    .allowsTightening(true)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 1)
            } else {
                Palette.fill2
                if isLoading {
                    ProgressView()
                        .controlSize(.mini)
                }
            }
        }
        .frame(width: width, height: (width * aspect).rounded())
        .clipShape(RoundedRectangle(cornerRadius: Radius.flag, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.flag, style: .continuous)
                .strokeBorder(showsPlaceholder ? Palette.separator2 : Palette.separator, lineWidth: showsPlaceholder ? 1 : 0.5)
        }
    }

    private var showsPlaceholder: Bool { placeholder != nil && image == nil }

    /// Small enough that "English" fits a 34 pt iPhone thumbnail's width.
    private var placeholderSize: CGFloat {
        switch width {
        case ..<30: 6
        case ..<50: 8
        default: 10
        }
    }

    /// Height ÷ width of what an item shows.
    static func aspect(of item: ScreenshotPlanItem) -> CGFloat {
        let known = item.content.renderJob?.layout.canvas.pixelSize ?? item.content.backupImage?.pixelSize ?? item.old?.pixelSize
        let size = known.flatMap { $0.width > 0 ? $0 : nil } ?? item.cell.displayType.portraitPixelSize
        return CGFloat(size.height) / CGFloat(size.width)
    }
}
