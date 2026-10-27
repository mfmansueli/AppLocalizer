//
//  ScreenshotRenderCache.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Renders by render key and pixel width: in memory (the most recent few
/// hundred) and, when there's a directory, as PNGs in Caches so the grid
/// fills instantly next launch. Equal keys mean identical renders, so an
/// entry never goes stale; a changed template or caption makes new keys.
@MainActor
final class ScreenshotRenderCache {
    let directory: URL?
    private let limit: Int
    private var memory: [String: CGImage] = [:]
    private var recent: [String] = []

    init(directory: URL?, limit: Int = 600) {
        self.directory = directory
        self.limit = limit
    }

    /// The render if it's in memory.
    func cached(_ key: RenderKey, width: Int) -> CGImage? {
        memory[Self.name(key, width: width)]
    }

    /// The render from memory, else from disk.
    func load(_ key: RenderKey, width: Int) async -> CGImage? {
        let name = Self.name(key, width: width)
        if let image = memory[name] { return image }
        guard let url = directory?.appending(path: "\(name).png") else { return nil }
        let image = await Task.detached { () -> CGImage? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return ScreenshotPNG.image(data)
        }.value
        if let image { remember(image, name: name) }
        return image
    }

    func store(_ image: CGImage, key: RenderKey, width: Int) {
        let name = Self.name(key, width: width)
        remember(image, name: name)
        guard let directory else { return }
        let url = directory.appending(path: "\(name).png")
        Task.detached(priority: .utility) {
            guard let data = ScreenshotPNG.data(image) else { return }
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try? data.write(to: url, options: .atomic)
        }
    }

    private func remember(_ image: CGImage, name: String) {
        if memory.updateValue(image, forKey: name) == nil { recent.append(name) }
        while recent.count > limit {
            memory[recent.removeFirst()] = nil
        }
    }

    private static func name(_ key: RenderKey, width: Int) -> String {
        "\(key.rawValue)-\(width)"
    }
}
