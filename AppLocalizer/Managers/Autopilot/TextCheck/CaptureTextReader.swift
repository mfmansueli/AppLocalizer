//
//  CaptureTextReader.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import Vision

/// Reads the text in a capture with Vision, in the capture's language and
/// in the ones an app falls back to when a screen isn't localized: the
/// primary language and English.
enum CaptureTextReader {
    static func reading(of image: CGImage, language: String, primary: String) async -> CaptureTextReading? {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let supported = request.supportedRecognitionLanguages
        let expected = match(language, in: supported)
        var languages: [Locale.Language] = []
        for candidate in [expected, match(primary, in: supported), match("en", in: supported)] {
            if let candidate, !languages.contains(candidate) { languages.append(candidate) }
        }
        request.recognitionLanguages = languages
        guard let observations = try? await request.perform(on: image) else { return nil }
        let lines = observations.compactMap { observation -> RecognizedTextLine? in
            guard let best = observation.topCandidates(1).first else { return nil }
            // Vision's boxes start at the bottom left.
            let box = observation.boundingBox.cgRect
            return RecognizedTextLine(text: best.string, confidence: Double(best.confidence), top: 1 - box.maxY)
        }
        return CaptureTextReading(lines: lines, readsLanguage: expected != nil)
    }

    /// Vision's language for a locale's: `de` → de-DE, `nb` → nb-NO, and
    /// `zh-Hant` → zh-Hant, never zh-Hans.
    static func match(_ identifier: String, in supported: [Locale.Language]) -> Locale.Language? {
        supported.first { CaptureTextLanguage.isSame($0.minimalIdentifier, identifier) }
    }
}
