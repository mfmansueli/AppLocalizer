//
//  ReviewCreation.swift
//  AppLocalizer
//

import Foundation

/// Something a push creates, as one row of the review sheet: "Create the
/// Polish page", made of the changes that create it (a new language takes
/// up to two writes) and every field they create it with. The fields go
/// with it: checking or unchecking it does all of them.
struct ReviewCreation: Identifiable, Hashable, Sendable {
    var id: String
    /// "Create the Polish page".
    var title: String
    /// "A new App Store language for Lumen Journal, with the text below".
    var detail: String
    var source: ChangeSource
    var flagRegion: String?
    /// The changes that create it, in the order made.
    var changes: [PendingChange]

    var changeIDs: [PendingChange.ID] { changes.map(\.id) }

    /// Every field it's created with, in the editor's order.
    var fields: [PendingChangePart] {
        let order = ListingField.allCases.map(\.rawValue)
        return changes.flatMap { $0.creation?.fields ?? [] }.sorted { lhs, rhs in
            (order.firstIndex(of: lhs.id) ?? .max) < (order.firstIndex(of: rhs.id) ?? .max)
        }
    }

    /// A push would skip it: a field over the limit or an invalid URL.
    var isBlocked: Bool { changes.contains(where: \.isBlocked) }

    var blockingMessage: String? { changes.lazy.compactMap(\.blockingMessage).first }

    /// The changes that create something, one per thing, in the order the
    /// first of each was made.
    static func group(_ changes: [PendingChange]) -> [ReviewCreation] {
        var creations: [ReviewCreation] = []
        for change in changes {
            guard let creation = change.creation else { continue }
            if let index = creations.firstIndex(where: { $0.id == creation.id }) {
                creations[index].changes.append(change)
                // Any of them may say the page gets text.
                if creation.detail.count > creations[index].detail.count { creations[index].detail = creation.detail }
            } else {
                creations.append(ReviewCreation(
                    id: creation.id,
                    title: creation.title,
                    detail: creation.detail,
                    source: creation.source,
                    flagRegion: change.flagRegion,
                    changes: [change]
                ))
            }
        }
        return creations
    }
}
