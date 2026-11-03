//
//  AppPreviewTestRecording.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
@testable import AppLocalizer

/// A stand-in for a Simulator recording: solid colors, each from its start
/// second until the next one's, at a low frame rate so the App Preview has
/// to hold each image for several of its frames.
enum AppPreviewTestRecording {
    /// One color and the second it starts at.
    struct Scene {
        var start: Double
        var color: TemplateColor
    }

    static func write(to url: URL, size: PixelSize, seconds: Double, framesPerSecond: Int, scenes: [Scene]) async throws {
        var spec = AppPreviewSpec(displayType: .iPhone, pixelSize: size)
        spec.framesPerSecond = framesPerSecond
        let writer = try AppPreviewWriter(output: url, spec: spec, bitRate: 2_000_000)
        let count = Int((seconds * Double(framesPerSecond)).rounded())
        for index in 0..<count {
            let time = Double(index) / Double(framesPerSecond)
            let color = scenes.last { $0.start <= time + 0.000_1 }?.color ?? .black
            try await writer.appendFrame { context in
                context.setFillColor(AppPreviewTextSetter.cgColor(color))
                context.fill(CGRect(x: 0, y: 0, width: context.width, height: context.height))
            }
        }
        try await writer.finish()
    }

    /// A fresh file in the temporary folder.
    static func temporaryURL(_ name: String) -> URL {
        FileManager.default.temporaryDirectory.appending(path: "AppPreviewTests-\(UUID().uuidString)-\(name)")
    }
}
