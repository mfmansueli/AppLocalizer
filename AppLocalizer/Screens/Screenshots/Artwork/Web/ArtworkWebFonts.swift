//
//  ArtworkWebFonts.swift
//  AppLocalizer
//

import Foundation

/// The fonts a Claude Design page can name besides the Mac's own: the
/// gallery's bundled families and the ones uploaded in the template
/// inspector, as `@font-face` rules over `al-asset://font/` files. The web
/// view draws in another process, which doesn't see the fonts
/// AppLocalizer registers for itself.
enum ArtworkWebFonts {
    /// The `@font-face` rules for every bundled face and uploaded file.
    static var css: String {
        var rules: [String] = []
        for family in BundledFonts.families {
            for face in family.faces where BundledFonts.url(for: face.postScriptName) != nil {
                rules.append("""
                @font-face { font-family: "\(family.name)"; src: url("al-asset://font/\(face.postScriptName).ttf"); \
                font-weight: \(face.weight); font-style: \(face.isItalic ? "italic" : "normal"); }
                """)
            }
        }
        for (family, file) in uploadedFiles() {
            rules.append("@font-face { font-family: \"\(family)\"; src: url(\"al-asset://font/\(file.lastPathComponent)\"); }")
        }
        return rules.joined(separator: "\n")
    }

    /// What a page should write to reach the system's own fonts, which
    /// pages can't name: SF Pro and New York.
    static let systemFamilies: [String: String] = [
        "SF Pro": "system-ui",
        "SF Pro Display": "system-ui",
        "SF Pro Text": "system-ui",
        "SF Pro Rounded": "ui-rounded",
        "New York": "ui-serif",
        "SF Mono": "ui-monospace",
    ]

    /// The font family a template would call `family`: the CSS keywords
    /// back to the system font's name.
    static func templateName(of family: String) -> String {
        let lowered = family.lowercased()
        switch lowered {
        case "system-ui", "-apple-system", "ui-sans-serif", "blinkmacsystemfont", "sans-serif": return "SF Pro Display"
        case "ui-serif", "serif": return "New York"
        case "ui-rounded": return "SF Pro Rounded"
        case "ui-monospace", "monospace": return "SF Mono"
        default: return family
        }
    }

    /// The bytes of a bundled face ("Anton-Regular.ttf") or uploaded file.
    static func data(named name: String) -> Data? {
        let base = (name as NSString).deletingPathExtension
        if let url = BundledFonts.url(for: base) { return try? Data(contentsOf: url) }
        guard let file = uploadedFiles().first(where: { $0.file.lastPathComponent == name })?.file else { return nil }
        return try? Data(contentsOf: file)
    }

    static func mimeType(of name: String) -> String {
        switch (name as NSString).pathExtension.lowercased() {
        case "otf": "font/otf"
        case "ttc", "otc": "font/collection"
        default: "font/ttf"
        }
    }

    /// Each uploaded font file with the family a template names it by.
    private static func uploadedFiles() -> [(family: String, file: URL)] {
        let directory = ScreenshotFontLibrary.defaultDirectory
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files.filter { ScreenshotFontLibrary.fileExtensions.contains($0.pathExtension.lowercased()) }.compactMap { file in
            ScreenshotFontLibrary.families(in: file).first.map { ($0, file) }
        }
    }
}
