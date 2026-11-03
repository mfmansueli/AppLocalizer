//
//  ArtworkTextReader.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import Vision

/// Reads the text in a rendered header or search image with Vision, in the
/// image's language and English. Nil when Vision can't read it, so the
/// checks go on with the text layers alone.
enum ArtworkTextReader {
    /// Lines read with less confidence than this are left out, so a
    /// misread never blocks a push.
    static let minimumConfidence = 0.4

    static func read(_ image: CGImage, language: String) async -> [ArtworkReadText]? {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let supported = request.supportedRecognitionLanguages
        var languages: [Locale.Language] = []
        for candidate in [CaptureTextReader.match(language, in: supported), CaptureTextReader.match("en", in: supported)] {
            if let candidate, !languages.contains(candidate) { languages.append(candidate) }
        }
        request.recognitionLanguages = languages
        guard let observations = try? await request.perform(on: image) else { return nil }
        let size = CGSize(width: image.width, height: image.height)
        return observations.compactMap { observation -> ArtworkReadText? in
            guard let best = observation.topCandidates(1).first, Double(best.confidence) >= minimumConfidence else { return nil }
            // Vision's boxes are 0–1 from the bottom left.
            let box = observation.boundingBox.cgRect
            let frame = CGRect(
                x: box.minX * size.width, y: (1 - box.maxY) * size.height, width: box.width * size.width, height: box.height * size.height
            )
            return ArtworkReadText(text: best.string, frame: frame, confidence: Double(best.confidence))
        }
    }
}
