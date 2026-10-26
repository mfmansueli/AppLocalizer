//
//  PrivacyAnswer.swift
//  AppLocalizer
//

import Foundation

/// One data type's answer, as App Store Connect asks it: whether it's
/// collected, and for a collected type its purposes, whether it's linked to
/// the person's identity and whether it's used for tracking. A type that
/// isn't collected has none of those.
struct PrivacyAnswer: Hashable, Codable, Sendable {
    private(set) var collected: Bool
    private(set) var purposes: Set<PrivacyPurpose>
    private(set) var linked: Bool
    private(set) var tracking: Bool

    init(collected: Bool, purposes: Set<PrivacyPurpose> = [], linked: Bool = false, tracking: Bool = false) {
        self.collected = collected
        self.purposes = collected ? purposes : []
        self.linked = collected && linked
        self.tracking = collected && tracking
    }

    static let notCollected = PrivacyAnswer(collected: false)

    /// A collected type needs at least one purpose before it can count.
    var isMissingPurpose: Bool { collected && purposes.isEmpty }

    /// The purposes in App Store Connect's order.
    var sortedPurposes: [PrivacyPurpose] { purposes.sorted() }

    // MARK: - Editing

    /// Collected or not. Turning collection on starts with `purposes` (App
    /// Functionality when there's nothing better).
    func settingCollected(_ isCollected: Bool, purposes fallback: Set<PrivacyPurpose> = [.appFunctionality]) -> PrivacyAnswer {
        guard isCollected != collected else { return self }
        return isCollected ? PrivacyAnswer(collected: true, purposes: fallback) : .notCollected
    }

    func togglingPurpose(_ purpose: PrivacyPurpose) -> PrivacyAnswer {
        var purposes = purposes
        if purposes.contains(purpose) { purposes.remove(purpose) } else { purposes.insert(purpose) }
        return PrivacyAnswer(collected: collected, purposes: purposes, linked: linked, tracking: tracking)
    }

    func settingLinked(_ isLinked: Bool) -> PrivacyAnswer {
        PrivacyAnswer(collected: collected, purposes: purposes, linked: isLinked, tracking: tracking)
    }

    func settingTracking(_ isTracking: Bool) -> PrivacyAnswer {
        PrivacyAnswer(collected: collected, purposes: purposes, linked: linked, tracking: isTracking)
    }

    // MARK: - Text

    /// "Collected · Analytics · linked", or "Not collected": the conflict
    /// buttons and the evidence popover's first line.
    var summary: String {
        guard collected else { return String(localized: "Not collected") }
        let purposes = sortedPurposes.map(\.title).joined(separator: ", ")
        let linkage = linked ? String(localized: "linked") : String(localized: "not linked")
        return [String(localized: "Collected"), purposes.isEmpty ? nil : purposes, linkage].compactMap(\.self).joined(separator: " · ")
    }

    /// "Collected · App Functionality · linked to the user · not used for
    /// tracking", for the evidence popover.
    var longSummary: String {
        guard collected else { return String(localized: "Not collected") }
        return [
            String(localized: "Collected"),
            sortedPurposes.map(\.title).joined(separator: ", "),
            linked ? String(localized: "linked to the user") : String(localized: "not linked"),
            tracking ? String(localized: "used for tracking") : String(localized: "not used for tracking"),
        ].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    // MARK: - Coding

    private enum CodingKeys: String, CodingKey {
        case collected
        case purposes
        case linked
        case tracking
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            collected: container.decode(Bool.self, forKey: .collected),
            purposes: container.decodeIfPresent(Set<PrivacyPurpose>.self, forKey: .purposes) ?? [],
            linked: container.decodeIfPresent(Bool.self, forKey: .linked) ?? false,
            tracking: container.decodeIfPresent(Bool.self, forKey: .tracking) ?? false
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(collected, forKey: .collected)
        try container.encode(sortedPurposes, forKey: .purposes)
        try container.encode(linked, forKey: .linked)
        try container.encode(tracking, forKey: .tracking)
    }
}
