//
//  ExtrasPushEvent.swift
//  AppLocalizer
//

import Foundation

/// One item the push finished, done or not, with what it did and how long
/// it took, newest last in `ExtrasPushRun.events`.
struct ExtrasPushEvent: Hashable, Sendable, Identifiable {
    var id: Int
    var itemID: ExtrasPushItem.ID
    /// "German · Header 21:9".
    var title: String
    var status: ExtrasPushStatus
    var date: Date
    /// From its turn to its end.
    var seconds: TimeInterval
    /// "Placed on the product page header", "Placed first in App
    /// Previews", why it failed, or "Cancelled".
    var text: String

    init(id: Int, item: ExtrasPushItem, status: ExtrasPushStatus, date: Date, seconds: TimeInterval) {
        self.id = id
        itemID = item.id
        title = item.title
        self.status = status
        self.date = date
        self.seconds = seconds
        text = Self.text(for: item, status: status)
    }

    private static func text(for item: ExtrasPushItem, status: ExtrasPushStatus) -> String {
        switch status {
        case .done:
            if case .appPreview = item.kind { return String(localized: "Placed first in App Previews") }
            let names = item.kind.placementTypes.map(ExtrasPushKind.name(ofPlacementType:))
            return String(localized: "Placed on \(names.formatted(.list(type: .and)))")
        case let .failed(reason):
            return reason
        case .cancelled:
            return String(localized: "Cancelled")
        case .waiting, .preparing, .uploading, .processing, .placing:
            return status.title
        }
    }
}
