//
//  PrivacyWorksheetStore.swift
//  AppLocalizer
//

import Foundation

/// Where App Privacy worksheets are kept: a file per app in Application
/// Support (`FilePrivacyWorksheetStore`), or memory in tests and DEBUG
/// scenes. Implementations are `@Observable`, so a page showing a worksheet
/// updates while an assistant writes to it over MCP.
@MainActor
protocol PrivacyWorksheetStore: AnyObject {
    func worksheet(for appID: StoreApp.ID) -> PrivacyWorksheet
    func setWorksheet(_ worksheet: PrivacyWorksheet, for appID: StoreApp.ID)
}

extension PrivacyWorksheetStore {
    /// Reads, changes and writes back one app's worksheet.
    func update(_ appID: StoreApp.ID, _ change: (inout PrivacyWorksheet) -> Void) {
        var worksheet = worksheet(for: appID)
        change(&worksheet)
        setWorksheet(worksheet, for: appID)
    }
}
