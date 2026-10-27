//
//  ScreenshotProposal.swift
//  AppLocalizer
//

import Foundation

/// A change an assistant sent for an app's screenshots (design README §6):
/// who, when, why, and either template operations on dotted paths with the
/// version they were based on, or captions per locale and slot. Kept with
/// the document, never as a `PendingChange`: accepting one makes a template
/// version or writes captions, and their renders then join Review & Push
/// like any others.
struct ScreenshotProposal: Codable, Hashable, Sendable, Identifiable {
    var id: String
    /// "Claude Code".
    var client: String
    var receivedAt: Date
    /// "Smaller headline, hyphenation on".
    var title: String
    /// The assistant's why, shown as "Why · from Claude Code".
    var reason: String
    var kind: Kind
    /// Set for a template proposal.
    var template: TemplateProposal?
    /// Set for a caption proposal, in the order they were sent.
    var captions: [CaptionProposalItem]
    var status: ScreenshotProposalStatus
    var decidedAt: Date?

    enum Kind: String, Codable, Hashable, Sendable {
        case template
        case captions
    }

    static func template(
        id: String, client: String, receivedAt: Date, title: String, reason: String, proposal: TemplateProposal
    ) -> ScreenshotProposal {
        ScreenshotProposal(
            id: id, client: client, receivedAt: receivedAt, title: title, reason: reason, kind: .template,
            template: proposal, captions: [], status: .waiting
        )
    }

    static func captions(
        id: String, client: String, receivedAt: Date, title: String, reason: String, items: [CaptionProposalItem]
    ) -> ScreenshotProposal {
        ScreenshotProposal(
            id: id, client: client, receivedAt: receivedAt, title: title, reason: reason, kind: .captions,
            template: nil, captions: items, status: .waiting
        )
    }

    var source: ChangeSource { .assistant(client: client) }

    var isWaiting: Bool { status == .waiting }

    /// The template version a template proposal is based on.
    var basedOnVersion: Int? { template?.basedOn }

    /// A waiting template proposal based on an older version than the
    /// current one. Caption proposals never go stale: they're measured
    /// against the current template when shown.
    func isStale(currentVersion: Int) -> Bool {
        guard isWaiting, let basedOn = template?.basedOn else { return false }
        return basedOn < currentVersion
    }

    /// `locale` → slots with a caption still waiting, for the cells' CC
    /// monogram.
    var captionSlots: [String: [Int]] {
        guard isWaiting else { return [:] }
        return Dictionary(grouping: captions, by: \.locale).mapValues { $0.map(\.slot).sorted() }
    }

    func touches(locale: String, slot: Int) -> Bool {
        isWaiting && captions.contains { $0.locale == locale && $0.slot == slot }
    }

    /// "10:42" today, "Oct 20 · 18:05" before.
    func timeText(now: Date = .now, calendar: Calendar = .current) -> String {
        let time = receivedAt.formatted(date: .omitted, time: .shortened)
        guard !calendar.isDate(receivedAt, inSameDayAs: now) else { return time }
        return "\(receivedAt.formatted(.dateTime.month(.abbreviated).day())) · \(time)"
    }
}
