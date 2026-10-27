//
//  AppPrivacyViewModel.swift
//  AppLocalizer
//

import AppKit
import Foundation
import Observation

/// The App Privacy page's state: the worksheet (kept on this Mac, since App
/// Store Connect has no API for the questionnaire), the checklist, the
/// privacy URLs, and what's open on the page.
///
/// The worksheet is read from `services.privacy` every time, never copied,
/// so an assistant's suggestions arriving over MCP show up while the page is
/// open. Edits go back through the store. The privacy URLs are the one part
/// that syncs: their edits are Review & Push changes, the Privacy Policy URL
/// as the very change Store Page makes. The worksheet's edits are in
/// `AppPrivacyViewModel+Worksheet.swift`, the checklist's in `+Checklist`,
/// import and export in `+Transfer`, the URLs in `+URLs`.
@MainActor
@Observable
final class AppPrivacyViewModel {
    let app: StoreApp
    let services: any AppInformationServices
    let queue: ChangeQueue
    /// The section's view model, for the toast and `apply(_:id:)`.
    @ObservationIgnored weak var owner: AppInformationViewModel?
    @ObservationIgnored var now: () -> Date = { Date() }
    /// Puts text on the pasteboard; tests replace it.
    @ObservationIgnored var copy: (String) -> Void = { text in
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: - Page state

    var tab: AppPrivacyTab = .worksheet
    var filter: PrivacyWorksheetFilter = .all
    /// "Show All 35 Data Types": every type, not only the answered ones.
    var showsAllTypes = false
    /// The type whose evidence popover is open.
    var evidenceType: PrivacyDataType?
    var showsScanSummary = false
    /// The type "Not Collected, Explain…" is asking about.
    var explainingType: PrivacyDataType?
    var isExportSheetPresented = false
    var exportFormat: PrivacyExportFormat = .fastlane
    var isExporterPresented = false
    var isImporterPresented = false
    /// The file Import from fastlane read, waiting to be confirmed.
    var importPreview: PrivacyFastlaneImport?
    var importFileName: String?
    /// e.g. "~/Developer/Lumen/fastlane/app_privacy_details.json".
    var importFilePath: String?
    var importError: String?
    var isImportSheetPresented = false
    /// The step whose Copy button says "Copied".
    var copiedStepID: String?
    /// Copy Prompt was pressed: the scan card waits for the assistant.
    var isPromptCopied = false
    var isCommandCopied = false
    /// Each locale's privacy URLs from App Store Connect.
    var urls: LoadState<PrivacyURLsContent> = .idle

    init(app: StoreApp, services: any AppInformationServices, queue: ChangeQueue) {
        self.app = app
        self.services = services
        self.queue = queue
    }

    // MARK: - Worksheet

    /// This app's worksheet, always the store's current one.
    var worksheet: PrivacyWorksheet {
        services.privacy.worksheet(for: app.id)
    }

    var status: PrivacyWorksheetStatus { worksheet.status }

    /// Changes the worksheet in the store.
    func update(_ change: (inout PrivacyWorksheet) -> Void) {
        services.privacy.update(app.id, change)
    }

    /// The scan running now, unless it went quiet.
    var runningScan: PrivacyRunningScan? {
        worksheet.activeScan(at: now())
    }

    func say(_ message: String) {
        owner?.toast = message
    }
}
