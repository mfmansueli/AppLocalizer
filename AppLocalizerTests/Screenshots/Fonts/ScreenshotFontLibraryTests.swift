//
//  ScreenshotFontLibraryTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Uploading a brand font: it's copied into the library's folder,
/// registered for the process, offered in the pickers marked uploaded, and
/// a script it can't draw still needs a fallback.
@MainActor
@Suite("ScreenshotFontLibrary")
struct ScreenshotFontLibraryTests {
    private static let systemFont = URL(filePath: "/System/Library/Fonts/Supplemental/Futura.ttc")

    /// A copy of a system font in its own temporary folder, as if picked
    /// in the file importer, and an empty library folder.
    private func fixture() throws -> (font: URL, library: ScreenshotFontLibrary) {
        let root = URL.temporaryDirectory.appending(path: "AppLocalizerTests-FontLibrary-\(UUID().uuidString)")
        let picked = root.appending(path: "Picked")
        try FileManager.default.createDirectory(at: picked, withIntermediateDirectories: true)
        let font = picked.appending(path: "Northpier.ttc")
        try FileManager.default.copyItem(at: Self.systemFont, to: font)
        return (font, ScreenshotFontLibrary(directory: root.appending(path: "Fonts")))
    }

    @Test func anUploadIsCopiedAndRegistered() throws {
        let (font, library) = try fixture()
        let family = try library.upload(font)
        #expect(family == "Futura")
        #expect(FileManager.default.fileExists(atPath: library.directory.appending(path: "Northpier.ttc").path(percentEncoded: false)))
        #expect(library.registerAll() == ["Futura"])
        #expect(try library.upload(font) == "Futura")
    }

    @Test func aFileThatIsntAFontIsRefused() throws {
        let (font, library) = try fixture()
        let text = font.deletingLastPathComponent().appending(path: "notes.ttf")
        try Data("not a font".utf8).write(to: text)
        #expect(throws: ScreenshotFontLibrary.UploadError.self) { try library.upload(text) }
        #expect(ScreenshotFontLibrary.families(in: text).isEmpty)
        #expect(library.registerAll().isEmpty)
    }

    @Test func uploadedFontsAreOfferedAndMarked() {
        let catalog = ScreenshotFontCatalog(uploaded: ["Futura"])
        #expect(catalog.displayFonts == ["SF Pro Display", "SF Pro Text", "New York", "Futura"])
        #expect(catalog.isUploaded("Futura"))
        #expect(!catalog.isUploaded("New York"))
        #expect(catalog.fonts(drawing: .latin).contains("Futura"))
        #expect(!catalog.fonts(drawing: .thai).contains("Futura"))
        #expect(catalog.fonts(drawing: .thai).contains("Thonburi"))
    }

    @Test func uploadingFromTheInspectorUsesTheFontForHeadlines() async throws {
        let (font, library) = try fixture()
        let (model, services) = await ScreenshotsTestFixtures.viewModel()
        services.fontLibrary = library
        await model.templateEditor.uploadFont(from: font)
        #expect(model.templateEditor.uploadError == nil)
        #expect(model.fonts.isUploaded("Futura"))
        #expect(model.templateEditor.template?.fonts.display == "Futura")
        #expect(model.templateEditor.template?.caption.headline.font == "Futura")
        #expect(model.templateEditor.fontTitle("Futura") == "Futura · uploaded")
        #expect(model.templateEditor.displayFontOptions.last == "Futura")
        #expect(model.templateEditor.hasUnsavedEdits)
    }

    @Test func aFailedUploadSaysWhy() async throws {
        let (font, library) = try fixture()
        let (model, services) = await ScreenshotsTestFixtures.viewModel()
        services.fontLibrary = library
        let text = font.deletingLastPathComponent().appending(path: "readme.otf")
        try Data("plain text".utf8).write(to: text)
        await model.templateEditor.uploadFont(from: text)
        #expect(model.templateEditor.uploadError == "“readme.otf” isn’t a font file AppLocalizer can read.")
        #expect(!model.templateEditor.hasUnsavedEdits)
    }
}
#endif
