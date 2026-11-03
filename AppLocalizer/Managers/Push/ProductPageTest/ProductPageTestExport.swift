//
//  ProductPageTestExport.swift
//  AppLocalizer
//

import Foundation

/// Writes a test's two variants per language to a folder, named so they
/// can be dropped into App Store Connect by hand
/// (`Header – Interface – en-US.png`, `Header – Outcome – en-US.png`), with
/// the steps to make the test there. Used when the API can't make it.
struct ProductPageTestExport {
    var request: ProductPageTestRequest

    /// "Header – Outcome – de-DE.png".
    static func fileName(placement: ProductPageTestPlacement, variant: String, locale: String, fileExtension: String) -> String {
        let ext = fileExtension.isEmpty ? "png" : fileExtension
        return "\(placement.title) – \(variant) – \(locale).\(ext)"
    }

    /// What to do in App Store Connect with the exported files.
    static func steps(for request: ProductPageTestRequest) -> String {
        let placement = request.placement.title
        return String(localized: """
        In App Store Connect, open \(request.appName)’s Product Page Optimization and create a test with one treatment named \
        “\(request.treatmentName)”. On the treatment’s \(request.placement.tabTitle) tab, add “\(placement) – \(request.treatmentName) – …” \
        in each language. The “\(request.controlName)” images are what the page shows now, the control: leave them on the page.
        """)
    }

    /// Copies each language's control and treatment into the request's
    /// folder, replacing files of the same name.
    func write(fileManager: FileManager = .default) throws -> ProductPageTestExportResult {
        let folder = request.exportFolder
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        var files: [URL] = []
        var withoutControl: [String] = []
        for locale in request.locales {
            if let control = locale.controlFile {
                try files.append(copy(control, variant: request.controlName, locale: locale.locale, into: folder, fileManager: fileManager))
            } else {
                withoutControl.append(locale.locale)
            }
            try files.append(copy(locale.treatmentFile, variant: request.treatmentName, locale: locale.locale, into: folder, fileManager: fileManager))
        }
        return ProductPageTestExportResult(folder: folder, files: files, languagesWithoutControl: withoutControl, steps: Self.steps(for: request))
    }

    private func copy(_ source: URL, variant: String, locale: String, into folder: URL, fileManager: FileManager) throws -> URL {
        let name = Self.fileName(placement: request.placement, variant: variant, locale: locale, fileExtension: source.pathExtension)
        let destination = folder.appending(path: name)
        if fileManager.fileExists(atPath: destination.path(percentEncoded: false)) { try fileManager.removeItem(at: destination) }
        try fileManager.copyItem(at: source, to: destination)
        return destination
    }
}
