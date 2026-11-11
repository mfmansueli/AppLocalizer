//
//  CaptionSlotMove.swift
//  AppLocalizer
//

import Foundation

/// Where each slot's captions come from when a run puts the set's screens
/// in a new order: the old slot with the same screen name, else the same
/// position when the screen there was renamed. Alba's 1.1.0 run moved
/// Animated scenes from slot 4 to slot 2: its English caption followed it,
/// but the other 13 languages kept theirs by position, and every Animated
/// scenes screenshot went live with the Styles caption.
struct CaptionSlotMove: Equatable, Sendable {
    /// For each new slot, the old slot whose captions it takes; nil for a
    /// screen the set didn't have.
    let sources: [Int?]
    private let oldCount: Int

    init(from old: [String], to new: [String]) {
        var used = Set<Int>()
        var sources: [Int?] = new.map { name in
            let key = Self.key(name)
            guard !key.isEmpty, let index = old.indices.first(where: { !used.contains($0) && Self.key(old[$0]) == key }) else { return nil }
            used.insert(index)
            return index
        }
        // Renamed where it stood: the old screen there went nowhere else.
        for slot in sources.indices where sources[slot] == nil && old.indices.contains(slot) && !used.contains(slot) {
            sources[slot] = slot
            used.insert(slot)
        }
        self.sources = sources
        oldCount = old.count
    }

    /// Every screen stays where it was.
    var isIdentity: Bool {
        sources.enumerated().allSatisfy { slot, source in source == slot || (source == nil && slot >= oldCount) }
    }

    private static func key(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
