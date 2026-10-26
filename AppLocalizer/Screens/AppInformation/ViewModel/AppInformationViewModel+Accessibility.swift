//
//  AppInformationViewModel+Accessibility.swift
//  AppLocalizer
//

import Foundation

// Accessibility: one card per device family, the editor sheet, Copy from
// iPhone, Delete Draft and the accessibility URL. Every write is a pending
// change; publishing is the change's option in Review & Push.
extension AppInformationViewModel {
    /// The cards, with what's queued laid on top.
    var accessibilityCards: [AccessibilityCard] {
        accessibility.value.map { builder.accessibilityCards($0, with: changes) } ?? []
    }

    func card(for family: DeviceFamily) -> AccessibilityCard? {
        accessibilityCards.first { $0.family == family }
    }

    /// Nothing declared, published or queued for any family yet.
    var isNeverDeclared: Bool {
        let cards = accessibilityCards
        return !cards.isEmpty && cards.allSatisfy { $0.state == .notDeclared }
    }

    /// Families the app may run on that App Store Connect doesn't list,
    /// for Other Devices: Apple Watch for an iOS app, since an iOS version
    /// doesn't say whether it ships a watch app. Declaring one adds its
    /// card.
    var otherFamilies: [DeviceFamily] {
        let shown = Set(accessibilityCards.map(\.family))
        guard shown.contains(.iPhone), !shown.contains(.appleWatch) else { return [] }
        return [.appleWatch]
    }

    /// The answer Copy from iPhone copies: what iPhone's card shows.
    var iPhoneAnswer: AccessibilityAnswer? {
        card(for: .iPhone)?.shown
    }

    func canCopyFromIPhone(to family: DeviceFamily) -> Bool {
        family != .iPhone && iPhoneAnswer != nil
    }

    // MARK: - Editor

    /// Edit… or Declare…: opens the sheet on the family's current answer.
    func openEditor(_ family: DeviceFamily) {
        guard let card = card(for: family) ?? otherCard(family) else { return }
        editorMessage = nil
        editor = AccessibilityEditorDraft(card: card, suggestions: notes.accessibilitySuggestions[family.rawValue] ?? [])
    }

    /// Copy from iPhone inside the sheet.
    func copyIntoEditor() {
        guard var draft = editor, let source = iPhoneAnswer else { return }
        let dropped = draft.copy(source)
        editor = draft
        editorMessage = Self.copyMessage(to: draft.family, dropped: dropped)
    }

    /// Save: queues the answer as a pending change.
    func saveEditor() {
        guard let draft = editor, let answer = draft.answer else { return }
        queueDeclaration(answer, for: draft.family)
        editor = nil
        toast = String(localized: "Saved. It’s waiting in Review & Push, where you choose whether to publish it.")
    }

    func cancelEditor() {
        editor = nil
        editorMessage = nil
    }

    // MARK: - Card actions

    /// Copy from iPhone on a card: queues iPhone's answer for the family,
    /// without what it doesn't have.
    func copyFromIPhone(to family: DeviceFamily) {
        guard canCopyFromIPhone(to: family), let source = iPhoneAnswer else { return }
        let available = source.features.intersection(family.features)
        let dropped = source.orderedFeatures.filter { !$0.isAvailable(on: family) }
        queueDeclaration(AccessibilityAnswer(features: available), for: family)
        toast = Self.copyMessage(to: family, dropped: dropped)
    }

    /// Delete Draft: a pending change too.
    func deleteDraft(_ family: DeviceFamily) {
        guard let card = card(for: family), card.canDeleteDraft else { return }
        apply(builder.deleteDraftChange(for: card), id: builder.accessibilityChangeID(family))
        toast = String(localized: "The draft will be deleted when you push. Published declarations can’t be deleted, only replaced.")
    }

    private func queueDeclaration(_ answer: AccessibilityAnswer, for family: DeviceFamily) {
        guard let card = card(for: family) ?? otherCard(family) else { return }
        var base = card
        base.queued = nil
        base.isDeletionQueued = false
        apply(builder.declarationChange(for: base, answer: answer), id: builder.accessibilityChangeID(family))
    }

    /// A card for a family from Other Devices, which has no declaration.
    private func otherCard(_ family: DeviceFamily) -> AccessibilityCard? {
        guard let content = accessibility.value else { return nil }
        return AccessibilityCard(family: family, isLive: content.liveFamilies.contains(family), upcomingVersion: content.upcomingVersion)
    }

    /// "Copied iPhone’s answers to Apple Watch. Voice Control isn’t
    /// available there, so it was left out. Check that they hold on Apple
    /// Watch before you publish."
    static func copyMessage(to family: DeviceFamily, dropped: [AccessibilityFeature]) -> String {
        var message = String(localized: "Copied iPhone’s answers to \(family.name).")
        if !dropped.isEmpty {
            let names = dropped.map(\.name).formatted(.list(type: .and))
            message += " " + (dropped.count == 1
                ? String(localized: "\(names) isn’t available there, so it was left out.")
                : String(localized: "\(names) aren’t available there, so they were left out."))
        }
        return message + " " + String(localized: "Check that they hold on \(family.name) before you publish.")
    }

    // MARK: - URL

    /// The accessibility URL with a queued edit on top.
    var accessibilityURL: String {
        accessibility.value.map { builder.accessibilityURL($0.accessibilityURL, with: changes) } ?? ""
    }

    var accessibilityURLProblem: String? {
        AccessibilityURLValidator.problem(in: accessibilityURL)
    }

    func setAccessibilityURL(_ text: String) {
        guard let content = accessibility.value, text != accessibilityURL else { return }
        apply(
            builder.accessibilityURLChange(from: content.accessibilityURL, to: text),
            id: builder.changeID(.accessibility, AppInformationChangeBuilder.accessibilityURLKey)
        )
    }
}
