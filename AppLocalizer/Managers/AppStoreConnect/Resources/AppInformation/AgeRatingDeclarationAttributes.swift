//
//  AgeRatingDeclarationAttributes.swift
//  AppLocalizer
//

import Foundation

/// The `ageRatingDeclarations` attributes: Apple's 2025 questionnaire.
/// Content answers are `NONE`, `INFREQUENT` or `FREQUENT` (older responses
/// may say `INFREQUENT_OR_MILD` or `FREQUENT_OR_INTENSE`); capabilities,
/// loot boxes, real-money gambling and health or wellness topics are
/// booleans. Decoded as raw values by attribute name, so `AgeRatingQuestion`
/// owns the mapping.
struct AgeRatingDeclarationAttributes: Decodable, Sendable {
    /// Every attribute the response had, by name.
    var values: [String: AppInformationAPIValue]

    init(values: [String: AppInformationAPIValue]) {
        self.values = values
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: AnyKey.self)
        var values: [String: AppInformationAPIValue] = [:]
        for key in container.allKeys {
            if let value = try? container.decode(AppInformationAPIValue.self, forKey: key) {
                values[key.stringValue] = value
            }
        }
        self.values = values
    }

    /// `ageRatingOverrideV2`: `NONE`, `NINE_PLUS` … `EIGHTEEN_PLUS`, `UNRATED`.
    var ageRatingOverride: String? { values["ageRatingOverrideV2"]?.stringValue }

    private struct AnyKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }

        init(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue _: Int) {
            nil
        }
    }
}
