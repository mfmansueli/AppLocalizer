//
//  ExtrasPushDebugMovies.swift
//  AppLocalizer
//

#if DEBUG
import CoreGraphics
import Foundation

/// Short real movies in place of Review & Push's stand-in App Previews,
/// so the viewer plays them: three seconds at a quarter of each one's
/// size, a colour sweep with a bar moving across. Written off the main
/// actor once the scene is up; the simulated push uploads them as they are.
enum ExtrasPushDebugMovies {
    static let seconds = 3
    private static let framesPerSecond = 10

    /// Replaces each App Preview's file in `folder` with a real movie.
    static func write(_ previews: [ExtrasPreviewFile], in folder: URL) {
        let jobs = previews.map { (url: folder.appending(path: "\($0.fileID).mov"), size: $0.pixelSize, display: $0.displayType) }
        Task.detached(priority: .utility) {
            for job in jobs {
                do {
                    try await movie(at: job.url, size: job.size, display: job.display)
                } catch {
                    print("ExtrasPushDebugMovies: \(job.url.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
    }

    private nonisolated static func movie(at url: URL, size: PixelSize, display: ScreenshotDisplayType) async throws {
        let small = PixelSize(width: even(size.width / 4), height: even(size.height / 4))
        var spec = AppPreviewSpec(displayType: display, pixelSize: small)
        spec.framesPerSecond = framesPerSecond
        let temporary = url.deletingLastPathComponent().appending(path: "\(UUID().uuidString).mov")
        let writer = try AppPreviewWriter(output: temporary, spec: spec, bitRate: 1_000_000)
        let count = seconds * framesPerSecond
        for index in 0..<count {
            let progress = CGFloat(index) / CGFloat(count - 1)
            _ = try await writer.appendFrame { context in
                let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
                context.setFillColor(CGColor(red: 0.2 + 0.6 * progress, green: 0.35, blue: 0.85 - 0.5 * progress, alpha: 1))
                context.fill(rect)
                context.setFillColor(CGColor(gray: 1, alpha: 0.9))
                context.fill(CGRect(x: progress * (rect.width - 24), y: rect.midY - 12, width: 24, height: 24))
            }
        }
        try await writer.finish()
        _ = try FileManager.default.replaceItemAt(url, withItemAt: temporary)
    }

    private nonisolated static func even(_ value: Int) -> Int {
        max(2, value - value % 2)
    }
}
#endif
