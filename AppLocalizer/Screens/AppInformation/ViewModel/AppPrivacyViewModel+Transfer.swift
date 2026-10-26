//
//  AppPrivacyViewModel+Transfer.swift
//  AppLocalizer
//

import Foundation

// Export… (fastlane JSON, a summary as Markdown or PDF) and Import from
// fastlane. Both use reviewed answers only.
extension AppPrivacyViewModel {
    /// The file Export… saves, in `format`.
    func exportData(as format: PrivacyExportFormat) throws -> Data {
        let worksheet = worksheet
        switch format {
        case .fastlane:
            return try PrivacyFastlaneCoder.encode(worksheet.reviewedAnswers)
        case .markdown:
            return Data(summaryWriter(worksheet).markdown().utf8)
        case .pdf:
            return PrivacySummaryPDFWriter.pdf(from: summaryWriter(worksheet).markdown())
        }
    }

    /// The export sheet's preview: the file's text, or a note for the PDF.
    var exportPreview: String {
        switch exportFormat {
        case .fastlane, .markdown:
            (try? exportData(as: exportFormat)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        case .pdf:
            summaryWriter(worksheet).markdown()
        }
    }

    var exportDocument: PrivacyExportDocument? {
        (try? exportData(as: exportFormat)).map(PrivacyExportDocument.init(data:))
    }

    var exportFileName: String {
        exportFormat.fileName(appName: app.name)
    }

    /// Save… in the export sheet.
    func saveExport() {
        isExportSheetPresented = false
        isExporterPresented = true
    }

    func exportDidFinish(_ result: Result<URL, any Error>) {
        isExporterPresented = false
        switch result {
        case let .success(url): say(String(localized: "Saved \(url.lastPathComponent)."))
        case let .failure(error): say(error.localizedDescription)
        }
    }

    // MARK: - Import

    /// "Import from fastlane": the open panel.
    func chooseImportFile() {
        isImporterPresented = true
    }

    func importFile(at url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            let shown = MCPClientSession.displayPath(forRootURI: url.absoluteString, homeDirectory: MCPServerController.userHomeDirectory)
            try showImport(Data(contentsOf: url), fileName: url.lastPathComponent, path: shown)
        } catch {
            showImportError(error)
        }
    }

    /// Reads a file's contents into the preview, or says why it can't.
    /// `path` is where it is, as the sheet shows it.
    func showImport(_ data: Data, fileName: String, path: String? = nil) {
        importFileName = fileName
        importFilePath = path
        do {
            importPreview = try PrivacyFastlaneCoder.decode(data)
            importError = nil
        } catch {
            showImportError(error)
            return
        }
        isImportSheetPresented = true
    }

    /// "Import 5 Data Types": the answers become the person's.
    func confirmImport() {
        guard let preview = importPreview else { return }
        update { $0.importAnswers(preview) }
        isImportSheetPresented = false
        importPreview = nil
        let name = importFileName ?? "app_privacy_details.json"
        say(String(localized: "Imported \(preview.types.count) data types from \(name). They’re yours now; a scan can still check them."))
    }

    func cancelImport() {
        isImportSheetPresented = false
        importPreview = nil
        importError = nil
    }

    private func showImportError(_ error: any Error) {
        importPreview = nil
        importError = error.localizedDescription
        isImportSheetPresented = true
    }

    private func summaryWriter(_ worksheet: PrivacyWorksheet) -> PrivacySummaryWriter {
        PrivacySummaryWriter(appName: app.name, worksheet: worksheet, date: now())
    }
}
