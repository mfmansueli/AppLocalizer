//
//  PriceIndexEdition+Codable.swift
//  AppLocalizer
//

import Foundation

// Dates are `yyyy-MM-dd` strings in PriceIndexSnapshot.json.
extension PriceIndexEdition: Codable {
    private enum CodingKeys: String, CodingKey {
        case label, badge, provenanceLabel, date, newerEdition
    }

    static func parseDay(_ text: String) throws -> Date {
        try Date(text, strategy: Date.ISO8601FormatStyle(timeZone: .gmt).year().month().day())
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            label: container.decode(String.self, forKey: .label),
            badge: container.decode(String.self, forKey: .badge),
            provenanceLabel: container.decode(String.self, forKey: .provenanceLabel),
            date: Self.parseDay(container.decode(String.self, forKey: .date)),
            newerEdition: container.decodeIfPresent(String.self, forKey: .newerEdition)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(badge, forKey: .badge)
        try container.encode(provenanceLabel, forKey: .provenanceLabel)
        try container.encode(date.formatted(Date.ISO8601FormatStyle(timeZone: .gmt).year().month().day()), forKey: .date)
        try container.encodeIfPresent(newerEdition, forKey: .newerEdition)
    }
}
