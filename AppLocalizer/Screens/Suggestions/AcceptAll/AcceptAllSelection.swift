//
//  AcceptAllSelection.swift
//  AppLocalizer
//

import Foundation

/// The Accept All sheet's state: every suggestion starts ticked, the person
/// unticks a language, a page or a single field, and only what's ticked is
/// accepted.
struct AcceptAllSelection: Equatable, Sendable {
    let kind: AcceptAllKind
    let groups: [AcceptAllGroup]
    private(set) var selected: Set<String>
    /// The group whose suggestions the right side shows.
    var focusedGroupID: String?
    var dontAskAgain = false

    init(kind: AcceptAllKind, groups: [AcceptAllGroup], focus: String? = nil) {
        self.kind = kind
        self.groups = groups
        selected = Set(groups.flatMap(\.items).map(\.id))
        focusedGroupID = groups.contains { $0.id == focus } ? focus : groups.first?.id
    }

    // MARK: - Reading

    var focusedGroup: AcceptAllGroup? {
        groups.first { $0.id == focusedGroupID }
    }

    var totalCount: Int { groups.reduce(0) { $0 + $1.items.count } }
    var selectedCount: Int { selected.count }

    /// Groups with at least one suggestion ticked.
    var selectedGroupCount: Int {
        groups.count { selectedCount(in: $0) > 0 }
    }

    func selectedCount(in group: AcceptAllGroup) -> Int {
        group.items.count { selected.contains($0.id) }
    }

    func state(of group: AcceptAllGroup) -> AcceptAllCheckState {
        let count = selectedCount(in: group)
        if count == 0 { return .unchecked }
        return count == group.items.count ? .checked : .mixed
    }

    func isSelected(_ item: AcceptAllItem) -> Bool {
        selected.contains(item.id)
    }

    // MARK: - Words

    var subtitle: String {
        let count = kind.countText(totalCount, groups: groups.count)
        return String(localized: "\(count). Untick anything you don’t want. Accepted suggestions wait in Review & Push; the App Store doesn’t change until you push.")
    }

    /// "23 selected in 5 languages".
    var summary: String {
        String(localized: "\(selectedCount) selected in \(selectedGroupCount) \(kind.unit(selectedGroupCount))")
    }

    var acceptTitle: String {
        selectedCount == 1 ? String(localized: "Accept 1 Suggestion") : String(localized: "Accept \(selectedCount) Suggestions")
    }

    /// "3 of 5 selected", for the group on the right.
    var focusedCountText: String {
        guard let group = focusedGroup else { return "" }
        return String(localized: "\(selectedCount(in: group)) of \(group.items.count) selected")
    }

    var focusedToggleTitle: String {
        focusedGroup.map { state(of: $0) == .checked } == true ? String(localized: "Select None") : String(localized: "Select All")
    }

    /// Why accepting makes a new page, when the group on the right is one.
    var focusedNewPageText: String? {
        guard let group = focusedGroup, group.isNewPage else { return nil }
        return String(localized: "\(group.title) isn’t on the App Store yet. Accepting these creates the \(group.title) page when you push.")
    }

    // MARK: - Changing

    mutating func toggle(_ item: AcceptAllItem) {
        if selected.contains(item.id) {
            selected.remove(item.id)
        } else {
            selected.insert(item.id)
        }
    }

    /// Mixed or off ticks the whole group; on unticks it.
    mutating func toggle(_ group: AcceptAllGroup) {
        let ids = group.items.map(\.id)
        if state(of: group) == .checked {
            selected.subtract(ids)
        } else {
            selected.formUnion(ids)
        }
    }

    mutating func toggleFocusedGroup() {
        if let group = focusedGroup { toggle(group) }
    }

    mutating func selectAll() {
        selected = Set(groups.flatMap(\.items).map(\.id))
    }

    mutating func selectNone() {
        selected = []
    }
}
