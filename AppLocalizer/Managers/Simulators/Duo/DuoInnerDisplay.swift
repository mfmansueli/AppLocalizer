//
//  DuoInnerDisplay.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import ImageIO

/// What iPhone Duo's inner display shows, from a small screenshot (the
/// helper's `simulator-screenshot`): black while the Duo is closed, only a
/// spinner in the middle while it starts or when its SpringBoard is stuck,
/// or the Home Screen or an app once it's open.
enum DuoInnerDisplay: String, Hashable, Sendable {
    case black
    case spinner
    case showing

    /// A pixel brighter than this (of 255) is lit. The spinner's frames are
    /// faint: some only reach 26.
    static let litLevel: UInt8 = 6

    /// A spinner lights a few pixels in the middle; anything more, or
    /// anywhere else, is the screen showing something.
    static let spinnerShare = 0.01

    /// The middle a spinner stays in, as a share of each side.
    static let middle = 0.35...0.65

    init(_ image: CGImage) {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else {
            self = .black
            return
        }
        var pixels = [UInt8](repeating: 0, count: width * height)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else {
            self = .showing
            return
        }
        var lit = 0
        var outsideMiddle = false
        for y in 0..<height {
            for x in 0..<width where pixels[y * width + x] > Self.litLevel {
                lit += 1
                let across = Double(x) / Double(width)
                let down = Double(y) / Double(height)
                if !Self.middle.contains(across) || !Self.middle.contains(down) { outsideMiddle = true }
            }
        }
        if lit == 0 {
            self = .black
        } else if !outsideMiddle, Double(lit) / Double(width * height) < Self.spinnerShare {
            self = .spinner
        } else {
            self = .showing
        }
    }

    /// The helper's base64 PNG; nil when it isn't one.
    init?(base64 text: String) {
        guard let data = Data(base64Encoded: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return nil }
        self.init(image)
    }
}
