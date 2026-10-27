//
//  PrivacyFastlaneCoder.swift
//  AppLocalizer
//

import Foundation

/// fastlane's `app_privacy_details.json` (`upload_app_privacy_details_to_app_store`):
/// one object per collected type with its category, purposes and data
/// protections, or a single `DATA_NOT_COLLECTED`.
enum PrivacyFastlaneCoder {
    /// Why a file can't be imported.
    enum Failure: LocalizedError, Equatable {
        case notFastlane
        case empty

        var errorDescription: String? {
            switch self {
            case .notFastlane: String(localized: "This isn’t a fastlane app_privacy_details.json file.")
            case .empty: String(localized: "The file doesn’t contain any App Privacy answers.")
            }
        }
    }

    static let notCollected = "DATA_NOT_COLLECTED"
    static let tracking = "DATA_USED_TO_TRACK_YOU"
    static let linked = "DATA_LINKED_TO_YOU"
    static let notLinked = "DATA_NOT_LINKED_TO_YOU"

    /// One entry of the file.
    private struct Entry: Codable {
        var category: String?
        var purposes: [String]?
        /// `data_protections` in the file.
        var dataProtections: [String]
    }

    /// The reviewed answers as fastlane's JSON, pretty-printed.
    static func encode(_ answers: PrivacyReviewedAnswers) throws -> Data {
        let entries: [Entry] = if answers.collects == true, !answers.collectedTypes.isEmpty {
            answers.collectedTypes.compactMap { type in
                answers.collected[type].map { answer in
                    var protections = answer.tracking ? [tracking] : []
                    protections.append(answer.linked ? linked : notLinked)
                    return Entry(category: type.fastlaneKey, purposes: answer.sortedPurposes.map(\.rawValue), dataProtections: protections)
                }
            }
        } else {
            [Entry(category: nil, purposes: nil, dataProtections: [notCollected])]
        }
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(entries)
    }

    static func decode(_ data: Data) throws -> PrivacyFastlaneImport {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let entries = try? decoder.decode([Entry].self, from: data) else { throw Failure.notFastlane }
        guard !entries.isEmpty else { throw Failure.empty }
        if entries.contains(where: { $0.dataProtections.contains(notCollected) }) {
            return PrivacyFastlaneImport(collects: false, answers: [:])
        }
        var result = PrivacyFastlaneImport(collects: true, answers: [:])
        for entry in entries {
            guard let category = entry.category else { continue }
            guard let type = PrivacyDataType.matching(category) else {
                result.unknownCategories.append(category)
                continue
            }
            let purposes = Set((entry.purposes ?? []).compactMap(PrivacyPurpose.matching))
            result.answers[type] = PrivacyAnswer(
                collected: true,
                purposes: purposes,
                linked: entry.dataProtections.contains(linked),
                tracking: entry.dataProtections.contains(tracking)
            )
        }
        guard !result.answers.isEmpty else { throw Failure.empty }
        return result
    }
}
