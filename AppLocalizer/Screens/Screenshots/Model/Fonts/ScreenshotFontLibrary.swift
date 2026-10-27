//
//  ScreenshotFontLibrary.swift
//  AppLocalizer
//

import CoreText
import Foundation

/// Fonts uploaded in the template inspector (design README §4): copied into
/// one folder and registered for this process, so a template can name
/// them like any installed font. Uploading a font that's already there,
/// or already registered, is fine.
struct ScreenshotFontLibrary: Sendable {
    var directory: URL

    /// `~/Library/Application Support/AppLocalizer/Fonts`.
    static let defaultDirectory = URL.applicationSupportDirectory.appending(path: "AppLocalizer/Fonts", directoryHint: .isDirectory)

    static let fileExtensions: Set = ["ttf", "otf", "ttc", "otc"]

    init(directory: URL = Self.defaultDirectory) {
        self.directory = directory
    }

    /// Registers every font in the folder. Returns their families, sorted.
    func registerAll() -> [String] {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        let families = files.filter { Self.fileExtensions.contains($0.pathExtension.lowercased()) }.flatMap(register)
        return Array(Set(families)).sorted()
    }

    /// Copies the font file into the folder and registers it. Returns the
    /// family a template names it by.
    func upload(_ url: URL) throws -> String {
        guard let family = Self.families(in: url).first else { throw UploadError.notAFont(url.lastPathComponent) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appending(path: url.lastPathComponent)
        if !FileManager.default.fileExists(atPath: destination.path(percentEncoded: false)) {
            try FileManager.default.copyItem(at: url, to: destination)
        }
        guard !register(destination).isEmpty else { throw UploadError.notRegistered(family) }
        return family
    }

    /// The families in a font file; none when it isn't one.
    static func families(in url: URL) -> [String] {
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor] else { return [] }
        var families: [String] = []
        for descriptor in descriptors {
            if let family = CTFontDescriptorCopyAttribute(descriptor, kCTFontFamilyNameAttribute) as? String, !families.contains(family) {
                families.append(family)
            }
        }
        return families
    }

    /// Registers one file for this process; its families, or none when it
    /// can't be registered.
    private func register(_ url: URL) -> [String] {
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            let code = error.map { CFErrorGetCode($0.takeRetainedValue()) }
            let harmless = [CTFontManagerError.alreadyRegistered.rawValue, CTFontManagerError.duplicatedName.rawValue]
            guard let code, harmless.contains(code) else { return [] }
        }
        return Self.families(in: url)
    }

    /// Why a font couldn't be uploaded.
    enum UploadError: LocalizedError {
        case notAFont(String)
        case notRegistered(String)

        var errorDescription: String? {
            switch self {
            case let .notAFont(file): String(localized: "“\(file)” isn’t a font file AppLocalizer can read.")
            case let .notRegistered(family): String(localized: "\(family) couldn’t be registered on this Mac.")
            }
        }
    }
}
