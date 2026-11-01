//
//  AutopilotSimulatorFrame.swift
//  AppLocalizer
//

import SwiftUI

/// The latest capture in its device's shape: a phone, an iPad on its side,
/// an Apple Watch with its round screen, or an Apple Vision Pro window
/// floating in a room.
struct AutopilotSimulatorFrame: View {
    let display: ScreenshotDisplayType
    let image: CGImage?
    let pixelSize: PixelSize

    var body: some View {
        Group {
            switch display {
            case .visionPro: vision
            default: device
            }
        }
        .frame(width: outerSize.width, height: outerSize.height)
        .accessibilityHidden(true)
    }

    private var outerSize: CGSize { Self.frameSize(for: display, pixelSize: pixelSize) }

    private var device: some View {
        let shape = Self.shape(for: display, pixelSize: pixelSize)
        return ZStack {
            RoundedRectangle(cornerRadius: shape.outerRadius, style: .continuous).fill(Color.black)
            if display == .watch {
                RoundedRectangle(cornerRadius: shape.outerRadius, style: .continuous)
                    .strokeBorder(Color(white: 0.25), lineWidth: 3)
            }
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: shape.innerRadius, style: .continuous))
                    .padding(shape.bezel)
            } else {
                Image(systemName: symbol).font(.largeTitle).foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    /// A softly lit room with the capture as a window and its bar under it.
    private var vision: some View {
        let windowWidth = outerSize.width * 0.6
        let aspect = Double(pixelSize.height) / Double(max(pixelSize.width, 1))
        return ZStack {
            LinearGradient(
                colors: [Color(red: 0.62, green: 0.68, blue: 0.75), Color(red: 0.42, green: 0.48, blue: 0.56)],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 5) {
                Group {
                    if let image {
                        Image(decorative: image, scale: 1).resizable().scaledToFill()
                    } else {
                        Color.white.opacity(0.7).overlay(Image(systemName: symbol).font(.title).foregroundStyle(.secondary))
                    }
                }
                .frame(width: windowWidth, height: windowWidth * aspect)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(.white.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                Capsule().fill(.white.opacity(0.75)).frame(width: windowWidth * 0.2, height: 3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var symbol: String {
        switch display {
        case .iPad: "ipad.landscape"
        case .iPhoneDuo: display.symbolName
        case .watch: "applewatch"
        case .visionPro: "visionpro"
        default: "iphone"
        }
    }

    // MARK: - Geometry

    struct Shape: Equatable {
        var inner: CGFloat
        var bezel: CGFloat
        var outerRadius: CGFloat
        var innerRadius: CGFloat
    }

    /// The screen's width, the bezel around it and the corner radii: a
    /// phone 152 pt wide, iPhone Duo unfolded 200 pt, an iPad on its side
    /// 246 pt, a watch 134 pt with a thick bezel and round corners.
    static func shape(for display: ScreenshotDisplayType, pixelSize: PixelSize) -> Shape {
        switch display {
        case .watch:
            Shape(inner: 134, bezel: 9, outerRadius: 40, innerRadius: 30)
        case .iPad where pixelSize.width > pixelSize.height:
            Shape(inner: 246, bezel: 7, outerRadius: 18, innerRadius: 12)
        case .iPad:
            Shape(inner: 152, bezel: 7, outerRadius: 18, innerRadius: 12)
        case .iPhoneDuo:
            Shape(inner: 200, bezel: 7, outerRadius: 20, innerRadius: 14)
        default:
            Shape(inner: 152, bezel: 7, outerRadius: 26, innerRadius: 20)
        }
    }

    /// The frame's outer size; Apple Vision Pro's room is 300 × 156 pt.
    static func frameSize(for display: ScreenshotDisplayType, pixelSize: PixelSize) -> CGSize {
        if display == .visionPro { return CGSize(width: 300, height: 156) }
        let shape = shape(for: display, pixelSize: pixelSize)
        let height = shape.inner * CGFloat(pixelSize.height) / CGFloat(max(pixelSize.width, 1))
        return CGSize(width: shape.inner + shape.bezel * 2, height: height + shape.bezel * 2)
    }
}
