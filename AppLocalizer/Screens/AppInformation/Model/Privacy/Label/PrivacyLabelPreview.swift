//
//  PrivacyLabelPreview.swift
//  AppLocalizer
//

import Foundation

/// The App Privacy label the reviewed answers make, as the App Store shows
/// it: Data Used to Track You, Data Linked to You and Data Not Linked to
/// You, each listing categories and their types; or Data Not Collected.
struct PrivacyLabelPreview: Hashable, Sendable {
    /// The label's three groups, in the App Store's order.
    enum Kind: String, CaseIterable, Identifiable, Hashable, Sendable {
        case tracking
        case linked
        case notLinked

        var id: String { rawValue }

        var title: String {
            switch self {
            case .tracking: String(localized: "Data Used to Track You")
            case .linked: String(localized: "Data Linked to You")
            case .notLinked: String(localized: "Data Not Linked to You")
            }
        }

        var subtitle: String {
            switch self {
            case .tracking: String(localized: "May be used to track you across apps and websites owned by other companies.")
            case .linked: String(localized: "May be collected and linked to your identity.")
            case .notLinked: String(localized: "May be collected but isn’t linked to your identity.")
            }
        }

        var systemImage: String {
            switch self {
            case .tracking: "arrow.up.right.circle"
            case .linked: "person.crop.circle"
            case .notLinked: "person.crop.circle.badge.xmark"
            }
        }
    }

    /// One category in a group, e.g. "Identifiers: User ID, Device ID".
    struct Line: Identifiable, Hashable, Sendable {
        var category: PrivacyDataCategory
        var types: [PrivacyDataType]

        var id: String { category.rawValue }

        var typeNames: String {
            types.map(\.name).joined(separator: ", ")
        }
    }

    struct Group: Identifiable, Hashable, Sendable {
        var kind: Kind
        var lines: [Line]

        var id: String { kind.rawValue }
    }

    /// False until the first question is answered and reviewed.
    var isAnswered: Bool
    var groups: [Group]

    /// "Data Not Collected": answered No, or nothing collected.
    var isDataNotCollected: Bool { isAnswered && groups.isEmpty }

    init(answers: PrivacyReviewedAnswers) {
        isAnswered = answers.collects != nil
        var byKind: [Kind: [PrivacyDataType]] = [:]
        for type in answers.collectedTypes {
            guard let answer = answers.collected[type] else { continue }
            let kind: Kind = answer.tracking ? .tracking : answer.linked ? .linked : .notLinked
            byKind[kind, default: []].append(type)
        }
        groups = Kind.allCases.compactMap { kind in
            guard let types = byKind[kind], !types.isEmpty else { return nil }
            let lines = PrivacyDataCategory.allCases.compactMap { category in
                let inCategory = types.filter { $0.category == category }
                return inCategory.isEmpty ? nil : Line(category: category, types: inCategory)
            }
            return Group(kind: kind, lines: lines)
        }
    }
}
