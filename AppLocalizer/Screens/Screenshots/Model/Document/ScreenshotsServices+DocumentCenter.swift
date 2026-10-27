//
//  ScreenshotsServices+DocumentCenter.swift
//  AppLocalizer
//

import Foundation

// Loading and saving through the services while telling the document
// center, so every view and tool showing the app's document stays in step.
// Services without a center (most tests) just load and save.
extension ScreenshotsServices {
    var documentCenter: ScreenshotsDocumentCenter? { nil }

    /// `document(for:primaryLocale:)`, reported to the center.
    func loadDocument(for app: StoreApp, primaryLocale: StoreLocale) async throws -> ScreenshotsDocument {
        let document = try await document(for: app, primaryLocale: primaryLocale)
        documentCenter?.register(app, services: self, primaryLocale: primaryLocale)
        documentCenter?.didLoad(document, appID: app.id)
        return document
    }

    /// `save(_:for:)`, reported to the center, which hands the document to
    /// everyone else watching the app.
    func saveDocument(_ document: ScreenshotsDocument, for app: StoreApp) async throws {
        try await save(document, for: app)
        documentCenter?.didSave(document, appID: app.id)
    }
}
