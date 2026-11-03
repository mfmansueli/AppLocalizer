//
//  ProductPageTestOutcome.swift
//  AppLocalizer
//

import Foundation

/// How a test ended. Only `.created` means App Store Connect has it.
enum ProductPageTestOutcome: Hashable, Sendable {
    case created(ProductPageTestCreated)
    /// Another test is in the way (App Store Connect runs one at a time);
    /// nothing was created.
    case testInProgress(name: String?, state: String)
    /// The API couldn't make the test, so both variants were exported
    /// with the steps to make it by hand. `reason` says why.
    case exported(ProductPageTestExportResult, reason: String)
    /// Nothing was made or exported.
    case failed(String)

    var isCreated: Bool {
        if case .created = self { return true }
        return false
    }

    /// The sheet's headline.
    var title: String {
        switch self {
        case let .created(created) where created.isStarted: String(localized: "Test sent to App Review")
        case .created: String(localized: "Test created as a draft")
        case .testInProgress: String(localized: "Another test is in progress")
        case .exported: String(localized: "Exported for App Store Connect")
        case .failed: String(localized: "The test wasn’t created")
        }
    }

    /// The line under it.
    var detail: String {
        switch self {
        case let .created(created):
            created.summary
        case let .testInProgress(name, state):
            if let name {
                String(localized: "“\(name)” is \(state). App Store Connect runs one test at a time: finish or delete it there first. Nothing was created.")
            } else {
                String(localized: "App Store Connect has a test \(state). It runs one at a time: finish or delete it there first. Nothing was created.")
            }
        case let .exported(result, reason):
            String(localized: "\(reason) The test wasn’t created. \(result.steps)")
        case let .failed(reason):
            reason
        }
    }
}
