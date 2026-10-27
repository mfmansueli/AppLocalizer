//
//  ScreenshotsSampleData+Captures.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

// fastlane snapshot's output for `capt-match`: ten locales on iPhone and
// two iPad captures that match, and three rows that need you: a "pt"
// folder, an iPhone 16e capture and a sixth slot.
extension ScreenshotsSampleData {
    static let fastlaneRoot = "/Users/sam/Developer/Lumen/fastlane/screenshots"
    static let matchedLocales = ["en-US", "de-DE", "fr-FR", "es-ES", "it", "ja", "ko", "zh-Hans", "ar-SA", "nl-NL"]

    static var fastlaneScan: CaptureScan {
        let iPhone = "iPhone 17 Pro Max"
        let iPad = "iPad Pro 13-inch (M5)"
        let phoneSize = ScreenshotDisplayType.iPhone.portraitPixelSize
        let padSize = ScreenshotDisplayType.iPad.portraitPixelSize.rotated
        var candidates = matchedLocales.flatMap { locale in
            slotNames.indices.map { slot in fastlaneFile(locale, device: iPhone, number: slot + 1, size: phoneSize) }
        }
        candidates += ["en-US", "ja"].map { fastlaneFile($0, device: iPad, number: 4, size: padSize) }
        candidates += slotNames.indices.map { fastlaneFile("pt", device: iPhone, number: $0 + 1, size: phoneSize) }
        candidates.append(fastlaneFile("en-US", device: "iPhone 16e", number: 3, size: PixelSize(width: 1170, height: 2532)))
        candidates.append(fastlaneFile("de-DE", device: iPhone, number: 6, name: "Settings", size: phoneSize))
        return CaptureScan(source: .fastlane, location: "~/Developer/Lumen/fastlane/screenshots", candidates: candidates)
    }

    private static func fastlaneFile(_ locale: String, device: String, number: Int, name: String? = nil, size: PixelSize) -> CaptureCandidate {
        let slotName = name ?? slotNames[number - 1]
        let path = String(format: "%@/%@-%02d_%@.png", locale, device, number, slotName)
        return CaptureCandidate(
            path: path, origin: .file(URL(filePath: "\(fastlaneRoot)/\(path)")), source: .fastlane, pixelSize: size,
            localeCode: locale, deviceName: device, slotNumber: number, slotName: slotName
        )
    }
}
#endif
