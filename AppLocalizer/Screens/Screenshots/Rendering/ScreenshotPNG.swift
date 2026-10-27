//
//  ScreenshotPNG.swift
//  AppLocalizer
//

import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// PNG encoding and decoding for renders, and the MD5 App Store Connect
/// reports as `sourceFileChecksum`.
enum ScreenshotPNG {
    static func data(_ image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination) ? data as Data : nil
    }

    static func image(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private static let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

    /// Whether the PNG has transparency: an alpha channel in its header's
    /// color type (4 grey + alpha, 6 RGBA) or a `tRNS` chunk. ImageIO
    /// leaves `kCGImagePropertyHasAlpha` out for PNGs, so the header is read
    /// directly. Anything that isn't a PNG counts as having alpha.
    static func hasAlpha(_ data: Data) -> Bool {
        let bytes = [UInt8](data)
        guard bytes.count > 33, Array(bytes[0..<8]) == signature else { return true }
        let colorType = bytes[25]
        if colorType == 4 || colorType == 6 { return true }
        var offset = 8
        while offset + 8 <= bytes.count {
            let length = bytes[offset..<offset + 4].reduce(0) { $0 << 8 | Int($1) }
            let type = String(bytes: bytes[offset + 4..<offset + 8], encoding: .ascii)
            if type == "tRNS" { return true }
            if type == "IDAT" || type == "IEND" { return false }
            offset += 12 + length
        }
        return false
    }

    /// The MD5 of the file, lowercase hex.
    static func checksum(_ data: Data) -> String {
        Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
