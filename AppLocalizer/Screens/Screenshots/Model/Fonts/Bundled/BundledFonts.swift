//
//  BundledFonts.swift
//  AppLocalizer
//

import CoreText
import Foundation

/// The fonts in `Resources/Fonts`, registered for this process the first
/// time one is asked for, so they work without being installed and never
/// depend on what this Mac has. Weights a family lacks snap to the nearest
/// face; italics a family lacks are slanted by the font catalog.
enum BundledFonts {
    static let families: [BundledFontFamily] = [
        BundledFontFamily(name: "Anton", faces: [BundledFontFace("Anton-Regular", weight: 400)]),
        BundledFontFamily(name: "Archivo", faces: [
            BundledFontFace("Archivo-Regular", weight: 400), BundledFontFace("Archivo-Medium", weight: 500),
            BundledFontFace("Archivo-SemiBold", weight: 600),
        ]),
        BundledFontFamily(name: "Archivo Black", faces: [BundledFontFace("ArchivoBlack-Regular", weight: 400)]),
        BundledFontFamily(name: "Boldonse", faces: [BundledFontFace("Boldonse-Regular", weight: 400)], fallbackWeight: 800),
        BundledFontFamily(name: "Fredoka", faces: [
            BundledFontFace("Fredoka-Medium", weight: 500), BundledFontFace("Fredoka-SemiBold", weight: 600),
            BundledFontFace("Fredoka-Bold", weight: 700),
        ]),
        BundledFontFamily(name: "Lobster", faces: [BundledFontFace("Lobster-Regular", weight: 400)]),
        BundledFontFamily(name: "Playfair Display", faces: [
            BundledFontFace("PlayfairDisplay-SemiBold", weight: 600), BundledFontFace("PlayfairDisplay-Bold", weight: 700),
            BundledFontFace("PlayfairDisplay-ExtraBold", weight: 800), BundledFontFace("PlayfairDisplay-Black", weight: 900),
            BundledFontFace("PlayfairDisplay-BoldItalic", weight: 700, italic: true),
            BundledFontFace("PlayfairDisplay-ExtraBoldItalic", weight: 800, italic: true),
            BundledFontFace("PlayfairDisplay-BlackItalic", weight: 900, italic: true),
        ]),
        BundledFontFamily(name: "Poppins", faces: [
            BundledFontFace("Poppins-Regular", weight: 400), BundledFontFace("Poppins-Medium", weight: 500),
            BundledFontFace("Poppins-SemiBold", weight: 600), BundledFontFace("Poppins-Bold", weight: 700),
            BundledFontFace("Poppins-ExtraBold", weight: 800),
            BundledFontFace("Poppins-MediumItalic", weight: 500, italic: true),
            BundledFontFace("Poppins-ExtraBoldItalic", weight: 800, italic: true),
        ]),
    ]

    static let names = families.map(\.name)

    static func family(named name: String) -> BundledFontFamily? {
        families.first { $0.name == name }
    }

    static func isBundled(_ name: String) -> Bool {
        family(named: name) != nil
    }

    /// The bundled face for `name` at `weight` and `size`, and whether it's
    /// a true italic; nil when `name` isn't bundled or its file is missing.
    static func font(named name: String, weight: Int, italic: Bool, size: CGFloat) -> (font: CTFont, isItalic: Bool)? {
        guard let face = family(named: name)?.face(weight: weight, italic: italic), registered.contains(face.postScriptName) else { return nil }
        let font = CTFontCreateWithName(face.postScriptName as CFString, size, nil)
        guard (CTFontCopyPostScriptName(font) as String) == face.postScriptName else { return nil }
        return (font, face.isItalic)
    }

    /// The faces registered for this process, once; a face whose file is
    /// missing is left out. Registering again after a relaunch is fine:
    /// process scope ends with the process.
    private static let registered: Set<String> = {
        var names: Set<String> = []
        for face in families.flatMap(\.faces) {
            guard let url = url(for: face.postScriptName) else { continue }
            var error: Unmanaged<CFError>?
            let isRegistered = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            let alreadyThere = (CTFontCopyPostScriptName(CTFontCreateWithName(face.postScriptName as CFString, 12, nil)) as String) == face.postScriptName
            if isRegistered || alreadyThere { names.insert(face.postScriptName) }
        }
        return names
    }()

    /// Synchronized folders copy resources flat, so the file is usually at
    /// the bundle's top level; a folder reference would keep `Fonts/`.
    static func url(for name: String) -> URL? {
        let bundle = Bundle(for: BundleToken.self)
        return bundle.url(forResource: name, withExtension: "ttf") ?? bundle.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
    }

    private final class BundleToken {}
}
