//
//  RetentionImageRule.swift
//  AppLocalizer
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Apple's rules for a retention message's image, as AppLocalizer enforces
/// them: a PNG 3840 pixels wide and 160 to 2160 tall, with no transparency.
/// (App Store Connect Help shows 3840 × 2160 or 5244 × 2950 as examples;
/// the 3840-wide range is the server API's rule, which AppLocalizer uses.)
/// It should also read in light and dark, since Apple shows it in both;
/// that's for the person to judge.
enum RetentionImageRule {
    /// What's wrong with an image of this size and format; unknown format
    /// or transparency (nil) isn't held against it.
    static func problems(width: Int, height: Int, isPNG: Bool?, hasAlpha: Bool?) -> [RetentionImageProblem] {
        var problems: [RetentionImageProblem] = []
        if isPNG == false { problems.append(.notPNG) }
        if width != RetentionLimits.imageWidth { problems.append(.wrongWidth(width)) }
        if !RetentionLimits.imageHeights.contains(height) { problems.append(.wrongHeight(height)) }
        if hasAlpha == true { problems.append(.transparency) }
        return problems
    }

    /// Reads a file's format, size and alpha channel, e.g. a PNG Claude
    /// Design made. Nil when it isn't an image at all.
    static func image(at url: URL, name: String? = nil) -> RetentionImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else { return nil }
        let type = CGImageSourceGetType(source) as String?
        let hasAlpha = properties[kCGImagePropertyHasAlpha] as? Bool ?? false
        return RetentionImage(
            name: name ?? url.deletingPathExtension().lastPathComponent,
            fileName: url.lastPathComponent,
            pixelWidth: width,
            pixelHeight: height,
            note: String(localized: "made by Claude Design"),
            localPath: url.path,
            hasAlpha: hasAlpha,
            isPNG: type == UTType.png.identifier
        )
    }
}
