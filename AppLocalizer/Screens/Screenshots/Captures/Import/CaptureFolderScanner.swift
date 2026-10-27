//
//  CaptureFolderScanner.swift
//  AppLocalizer
//

import Foundation
import ImageIO

/// Finds the screenshots in what was dropped or chosen (design README §2
/// "Captures"): fastlane snapshot's `<locale>/<device>-NN_Name.png`, any
/// folder of PNGs under locale folders, Xcode result bundles (exported
/// with `xcresulttool`) or a folder they were already exported to. Reads
/// only names and image headers; nothing is copied until Import.
struct CaptureFolderScanner: Sendable {
    var reader: any XcresultAttachmentReader = XcrunAttachmentReader()
    /// Paths under it show as "~/…".
    var homeDirectory = Self.userHomeDirectory
    /// Where result bundles' attachments are exported to.
    var exportDirectory = URL.temporaryDirectory.appending(path: "AppLocalizer-Attachments", directoryHint: .isDirectory)

    func scan(_ urls: [URL]) async throws -> CaptureScan {
        var candidates: [CaptureCandidate] = []
        var sources: Set<CaptureSource> = []
        for url in urls {
            if url.pathExtension == "xcresult" {
                let folder = exportDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                try await reader.exportAttachments(of: url, to: folder)
                candidates += Self.attachments(in: folder, bundleName: url.lastPathComponent)
                sources.insert(.xcodeResults)
            } else if Self.isDirectory(url), FileManager.default.fileExists(atPath: url.appending(path: "manifest.json").path) {
                candidates += Self.attachments(in: url, bundleName: url.lastPathComponent)
                sources.insert(.xcodeResults)
            } else if Self.isDirectory(url) {
                let files = Self.files(in: url)
                candidates += files
                sources.insert(files.contains { $0.deviceName != nil } ? .fastlane : .folder)
            } else if url.pathExtension.lowercased() == "png" {
                let parent = url.deletingLastPathComponent()
                candidates.append(Self.candidate(file: url, relativePath: "\(parent.lastPathComponent)/\(url.lastPathComponent)", folders: [parent.lastPathComponent]))
                sources.insert(.folder)
            }
        }
        guard !candidates.isEmpty else { throw CaptureImportError.noScreenshots }
        let source: CaptureSource = sources.contains(.xcodeResults) ? .xcodeResults : sources.contains(.fastlane) ? .fastlane : .folder
        return CaptureScan(source: source, location: location(of: urls), candidates: Self.unique(candidates))
    }

    // MARK: - Folders

    /// Every PNG under `root`, its locale from the nearest folder that
    /// names one (the root's own name included).
    static func files(in root: URL) -> [CaptureCandidate] {
        guard let enumerator = FileManager.default.enumerator(
            at: root, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }
        let rootComponents = root.standardizedFileURL.pathComponents
        var found: [CaptureCandidate] = []
        for case let url as URL in enumerator where url.pathExtension.lowercased() == "png" {
            let name = url.deletingPathExtension().lastPathComponent
            // fastlane frameit's framed copies aren't captures.
            guard !name.hasSuffix("_framed") else { continue }
            let folders = Array(url.standardizedFileURL.deletingLastPathComponent().pathComponents.dropFirst(rootComponents.count))
            let relative = (folders + [url.lastPathComponent]).joined(separator: "/")
            let localeInFolders = folders.contains { CaptureLocaleHint.code(in: $0) != nil }
            let path = localeInFolders || CaptureLocaleHint.code(in: root.lastPathComponent) == nil ? relative : "\(root.lastPathComponent)/\(relative)"
            found.append(candidate(file: url, relativePath: path, folders: [root.lastPathComponent] + folders))
        }
        return found
    }

    static func candidate(file: URL, relativePath: String, folders: [String]) -> CaptureCandidate {
        let name = CaptureFileName(file.lastPathComponent)
        let locale = folders.reversed().lazy.compactMap { CaptureLocaleHint.code(in: $0) }.first
        return CaptureCandidate(
            path: relativePath, origin: .file(file), source: name.deviceName == nil ? .folder : .fastlane, pixelSize: pixelSize(of: file),
            localeCode: locale, deviceName: name.deviceName, slotNumber: name.slotNumber, slotName: name.slotName
        )
    }

    // MARK: - Xcode test results

    /// The screenshots an export folder's manifest lists: locale from the
    /// test configuration, else the bundle's name; slot from the
    /// attachment's name.
    static func attachments(in folder: URL, bundleName: String) -> [CaptureCandidate] {
        guard let data = try? Data(contentsOf: folder.appending(path: "manifest.json")) else { return [] }
        let bundleLocale = CaptureLocaleHint.code(in: bundleName)
        return XcresultManifestEntry.entries(in: data).flatMap(\.attachments).compactMap { attachment in
            let file = folder.appending(path: attachment.exportedFileName)
            guard file.pathExtension.lowercased() == "png" else { return nil }
            let shown = attachment.suggestedHumanReadableName ?? attachment.exportedFileName
            let name = CaptureFileName(shown)
            let locale = attachment.configurationName.flatMap(CaptureLocaleHint.code(in:)) ?? bundleLocale
            return CaptureCandidate(
                path: "\(bundleName)/\(shown)", origin: .file(file), source: .xcodeResults, pixelSize: pixelSize(of: file),
                localeCode: locale, deviceName: attachment.deviceName ?? name.deviceName, slotNumber: name.slotNumber, slotName: name.slotName
            )
        }
    }

    // MARK: - Reading

    static func pixelSize(of file: URL) -> PixelSize? {
        guard let source = CGImageSourceCreateWithURL(file as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else { return nil }
        return PixelSize(width: width, height: height)
    }

    private static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }

    /// Paths stay unique: a second file with a path already used gets a
    /// number.
    private static func unique(_ candidates: [CaptureCandidate]) -> [CaptureCandidate] {
        var seen: Set<String> = []
        return candidates.map { candidate in
            var candidate = candidate
            var number = 2
            let path = candidate.path
            while seen.contains(candidate.path) {
                candidate.path = "\(path) (\(number))"
                number += 1
            }
            seen.insert(candidate.path)
            return candidate
        }
    }

    /// "~/Developer/Lumen/fastlane/screenshots", or "3 items".
    private func location(of urls: [URL]) -> String {
        guard urls.count == 1, let url = urls.first else { return String(localized: "\(urls.count) items") }
        let path = url.path(percentEncoded: false)
        let trimmed = path.hasSuffix("/") && path.count > 1 ? String(path.dropLast()) : path
        guard trimmed.hasPrefix(homeDirectory + "/") else { return trimmed }
        return "~" + trimmed.dropFirst(homeDirectory.count)
    }

    /// The person's home folder, not the sandbox container's.
    static var userHomeDirectory: String {
        guard let entry = getpwuid(getuid()), let directory = entry.pointee.pw_dir else { return NSHomeDirectory() }
        return String(cString: directory)
    }
}
