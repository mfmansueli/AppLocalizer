//
//  RetentionRemoteLocalization.swift
//  AppLocalizer
//

import Foundation

/// One `retentionMessageLocalizations` resource as App Store Connect has it.
/// Its locale can't change; its header and body can.
struct RetentionRemoteLocalization: Hashable, Codable, Sendable {
    var id: String
    var locale: String
    var header: String
    var body: String

    var text: RetentionText {
        RetentionText(header: header, body: body, origin: .written)
    }
}
