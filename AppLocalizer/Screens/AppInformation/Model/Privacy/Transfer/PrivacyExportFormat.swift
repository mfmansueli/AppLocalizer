//
//  PrivacyExportFormat.swift
//  AppLocalizer
//

import UniformTypeIdentifiers

/// What Export… saves: fastlane's JSON, or a summary to share with the
/// team as Markdown or PDF. Every format has reviewed answers only.
enum PrivacyExportFormat: String, CaseIterable, Identifiable, Hashable, Sendable {
    case fastlane
    case markdown
    case pdf

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fastlane: String(localized: "fastlane JSON")
        case .markdown: String(localized: "Summary · Markdown")
        case .pdf: String(localized: "Summary · PDF")
        }
    }

    var detail: String {
        switch self {
        case .fastlane: String(localized: "app_privacy_details.json for upload_app_privacy_details_to_app_store.")
        case .markdown: String(localized: "Every answer with its reason, and the open questions, for a pull request or a wiki.")
        case .pdf: String(localized: "The same summary, to send to legal or keep with a release.")
        }
    }

    var contentType: UTType {
        switch self {
        case .fastlane: .json
        case .markdown: UTType(filenameExtension: "md", conformingTo: .plainText) ?? .plainText
        case .pdf: .pdf
        }
    }

    /// e.g. "app_privacy_details.json" or "Lumen Journal App Privacy.md".
    func fileName(appName: String) -> String {
        switch self {
        case .fastlane: "app_privacy_details.json"
        case .markdown: String(localized: "\(appName) App Privacy.md")
        case .pdf: String(localized: "\(appName) App Privacy.pdf")
        }
    }
}
