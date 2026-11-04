//
//  ArtworkChecker.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Checks a rendered header or search image in one language before Review
/// & Push, like the screenshot checks.
///
/// Errors are what Apple doesn't allow in these placements: prices and
/// currency symbols, discounts and percentages, website addresses, ©,
/// claims that can't be verified, Apple's recognitions, other platforms or
/// stores (read in the text layers and, with Vision, in the render), and
/// any alpha or transparency. Text Vision reads inside a phone's screen is
/// the app's real interface, so there it's a warning.
///
/// Warnings: a search headline over 5 words or about 32 characters, a
/// header line over about 3 words, the phones or text outside the center
/// safe area, text that's hard to read on its background, edges that melt
/// into the App Store page in Light or Dark Mode, and a header that shares
/// neither the first screenshot's colors nor its typeface.
struct ArtworkChecker {
    /// Reads the text in a render; nil when Vision can't, and the checks
    /// go on without it.
    var reader: @Sendable (CGImage, String) async -> [ArtworkReadText]? = { image, language in
        await ArtworkTextReader.read(image, language: language)
    }

    /// Every check, errors first.
    func checks(_ input: ArtworkCheckInput) async -> [ArtworkCheck] {
        let read: [ArtworkReadText]? = if let image = input.image { await reader(image, input.locale.code) } else { nil }
        return checks(input, read: read)
    }

    /// The checks with the text already read from the render (nil: not
    /// read).
    func checks(_ input: ArtworkCheckInput, read: [ArtworkReadText]?) -> [ArtworkCheck] {
        let pixels = input.image.flatMap(ArtworkPixels.init)
        var checks = contentChecks(input, read: read)
        checks += transparencyChecks(input, pixels: pixels)
        checks += lengthChecks(input)
        checks += safeAreaChecks(input)
        checks += contrastChecks(input, pixels: pixels)
        checks += lookChecks(input)
        checks += pageChecks(input)
        return checks.filter(\.isError) + checks.filter { !$0.isError }
    }

    /// Whether the image can be pushed: no errors.
    static func canPush(_ checks: [ArtworkCheck]) -> Bool {
        !checks.contains(where: \.isError)
    }
}
