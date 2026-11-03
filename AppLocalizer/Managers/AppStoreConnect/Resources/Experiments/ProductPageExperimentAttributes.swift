//
//  ProductPageExperimentAttributes.swift
//  AppLocalizer
//

import Foundation

/// An `appStoreVersionExperiments` (v2) resource's attributes, read
/// leniently: Apple adds states over time.
struct ProductPageExperimentAttributes: Decodable, Sendable {
    var name: String?
    /// `IOS`, `MAC_OS`, …
    var platform: String?
    /// The share of the page's traffic the test gets, in percent.
    var trafficProportion: Int?
    /// `PREPARE_FOR_SUBMISSION`, `READY_FOR_REVIEW`, `WAITING_FOR_REVIEW`,
    /// `IN_REVIEW`, `ACCEPTED`, `APPROVED`, `REJECTED`, `COMPLETED`,
    /// `STOPPED`.
    var state: String?

    private enum CodingKeys: String, CodingKey {
        case name, platform, trafficProportion, state
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try? container.decodeIfPresent(String.self, forKey: .name)
        platform = try? container.decodeIfPresent(String.self, forKey: .platform)
        trafficProportion = try? container.decodeIfPresent(Int.self, forKey: .trafficProportion)
        state = try? container.decodeIfPresent(String.self, forKey: .state)
    }
}
