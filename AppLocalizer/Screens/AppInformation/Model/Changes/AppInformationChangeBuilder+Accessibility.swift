//
//  AppInformationChangeBuilder+Accessibility.swift
//  AppLocalizer
//

import Foundation

// Accessibility: one change per device family, saving its draft (`POST` a
// new one, or `PATCH` the draft App Store Connect has) with a "Publish to
// the App Store" option that publishes it right after (`PATCH` with
// `publish: true`, by the ID the `POST` returned when there was no draft).
// Deleting a draft is a change too. The URL is an attribute of the app.
extension AppInformationChangeBuilder {
    static let declarationType = "accessibilityDeclarations"
    static let accessibilityURLKey = "url"

    func accessibilityChangeID(_ family: DeviceFamily) -> String {
        changeID(.accessibility, family.rawValue)
    }

    /// Saves `answer` as the family's draft and, with the option on,
    /// publishes it. Nil when there's nothing to save or publish.
    func declarationChange(for card: AccessibilityCard, answer: AccessibilityAnswer, source: ChangeSource = .you) -> PendingChange? {
        let unchangedDraft = card.draftID != nil && card.draft == answer
        if card.draftID == nil, card.published == answer { return nil }
        if unchangedDraft, !card.isLive { return nil }
        var requests: [PushRequest] = []
        var conflictCheck: ConflictCheck?
        let targetID: String
        if let draftID = card.draftID {
            targetID = draftID
            conflictCheck = draftCheck(draftID)
            if !unchangedDraft {
                requests = [Self.patch(Self.declarationType, id: draftID, attributes: answer.attributes(for: card.family))]
            }
        } else {
            targetID = PushRequest.createdIDPlaceholder
            requests = [createRequest(card.family, answer: answer)]
        }
        var change = PendingChange(
            id: accessibilityChangeID(card.family),
            appID: appID,
            section: .appInformation,
            group: group(.accessibility),
            title: card.family.name,
            oldValue: Self.oldValue(of: card),
            newValue: unchangedDraft ? String(localized: "Publish the draft") : answer.summary,
            source: source,
            requests: requests,
            conflictCheck: conflictCheck
        )
        change.option = publishOption(for: card, declarationID: targetID)
        return change
    }

    /// Delete Draft: only a draft can be deleted.
    func deleteDraftChange(for card: AccessibilityCard) -> PendingChange? {
        guard let draftID = card.draftID else { return nil }
        return PendingChange(
            id: accessibilityChangeID(card.family),
            appID: appID,
            section: .appInformation,
            group: group(.accessibility),
            title: card.family.name,
            oldValue: Self.oldValue(of: card),
            newValue: String(localized: "Delete draft"),
            requests: [PushRequest(method: .delete, path: "/v1/\(Self.declarationType)/\(draftID)")],
            conflictCheck: draftCheck(draftID)
        )
    }

    /// The app's accessibility URL: https only, or empty.
    func accessibilityURLChange(from old: String, to new: String, source: ChangeSource = .you) -> PendingChange? {
        let new = new.trimmingCharacters(in: .whitespaces)
        guard old != new else { return nil }
        return PendingChange(
            id: changeID(.accessibility, Self.accessibilityURLKey),
            appID: appID,
            section: .appInformation,
            group: group(.accessibility),
            title: String(localized: "Accessibility URL"),
            oldValue: Self.display(old),
            newValue: Self.display(new),
            source: source,
            blockedReason: AccessibilityURLValidator.problem(in: new),
            requests: [Self.patch("apps", id: appID, attributes: ["accessibilityUrl": .text(new)])],
            restoreRequests: [Self.patch("apps", id: appID, attributes: ["accessibilityUrl": .text(old)])],
            conflictCheck: Self.attributeCheck("/v1/apps/\(appID)?fields[apps]=accessibilityUrl", key: "accessibilityUrl", expected: old.isEmpty ? nil : old)
        )
    }

    // MARK: - Reading

    /// The cards, with what's queued for each family laid on top. A family
    /// declared from Other Devices gets a card once it has a change.
    func accessibilityCards(_ content: AccessibilityContent, with changes: [PendingChange]) -> [AccessibilityCard] {
        let families = DeviceFamily.allCases.filter { family in
            content.families.contains(family) || Self.change(accessibilityChangeID(family), in: changes) != nil
        }
        return families.map { family in
            let draft = content.declaration(for: family, state: .draft)
            var card = AccessibilityCard(
                family: family,
                published: content.declaration(for: family, state: .published)?.answer,
                draft: draft?.answer,
                draftID: draft?.id,
                isLive: content.liveFamilies.contains(family),
                upcomingVersion: content.upcomingVersion
            )
            if let change = Self.change(accessibilityChangeID(family), in: changes) {
                if change.requests.first?.method == .delete {
                    card.isDeletionQueued = true
                } else if let attributes = Self.document(of: change)?.data.attributes {
                    card.queued = AccessibilityAnswer(supports: attributes.compactMapValues(\.boolValue))
                } else {
                    card.queued = card.draft
                }
            }
            return card
        }
    }

    /// The accessibility URL with a queued edit on top.
    func accessibilityURL(_ url: String, with changes: [PendingChange]) -> String {
        guard let change = Self.change(changeID(.accessibility, Self.accessibilityURLKey), in: changes) else { return url }
        return Self.document(of: change)?.attribute("accessibilityUrl")?.stringValue ?? ""
    }

    // MARK: - Helpers

    /// "Draft · 6 features: …", "Published · …" or "Not declared".
    static func oldValue(of card: AccessibilityCard) -> String {
        if let draft = card.draft { return String(localized: "Draft · \(draft.summary)") }
        if let published = card.published { return String(localized: "Published · \(published.summary)") }
        return AccessibilityCardState.notDeclared.title
    }

    private func createRequest(_ family: DeviceFamily, answer: AccessibilityAnswer) -> PushRequest {
        var attributes = answer.attributes(for: family)
        attributes["deviceFamily"] = .string(family.rawValue)
        let document = AppInformationWriteDocument.create(
            type: Self.declarationType,
            attributes: attributes,
            parent: "app",
            parentType: "apps",
            parentID: appID
        )
        return PushRequest(method: .post, path: "/v1/\(Self.declarationType)", body: document.encoded())
    }

    /// The draft must still be a draft: published or deleted meanwhile, the
    /// write would fail.
    private func draftCheck(_ draftID: String) -> ConflictCheck {
        Self.attributeCheck("/v1/\(Self.declarationType)/\(draftID)", key: "state", expected: AccessibilityDeclarationState.draft.rawValue)
    }

    /// "Publish to the App Store": on by default for a family with a live
    /// version, disabled with the reason otherwise.
    private func publishOption(for card: AccessibilityCard, declarationID: String) -> ChangeOption {
        let document = AppInformationWriteDocument.update(type: Self.declarationType, id: declarationID, attributes: ["publish": .bool(true)])
        let version = card.upcomingVersion ?? String(localized: "the next version")
        return ChangeOption(
            title: String(localized: "Publish to the App Store"),
            isOn: card.isLive,
            onNote: String(localized: "Goes on the product page as soon as it’s pushed. It can take up to 24 hours to show everywhere."),
            offNote: String(localized: "Saved in App Store Connect as a draft; nothing changes on the product page."),
            disabledReason: card.isLive ? nil : String(localized: """
            \(card.family.name) has no live version yet, so this is saved as a draft. Publish it after \(version) is released.
            """),
            requests: [PushRequest(method: .patch, path: "/v1/\(Self.declarationType)/\(declarationID)", body: document.encoded())],
            progressTitle: String(localized: "Publishing…"),
            doneTitle: String(localized: "Published"),
            offDoneTitle: String(localized: "Saved as a draft"),
            footnote: ChangeOptionFootnote(
                one: String(localized: "1 declaration publishes immediately when pushed"),
                other: String(localized: "{count} declarations publish immediately when pushed")
            )
        )
    }
}
