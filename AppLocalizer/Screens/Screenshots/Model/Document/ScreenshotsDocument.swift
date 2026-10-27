//
//  ScreenshotsDocument.swift
//  AppLocalizer
//

import Foundation

/// Everything AppLocalizer keeps about one app's screenshots on this Mac:
/// the template history, captions, the capture index, the locale scope,
/// what it pushed and the proposals waiting. Renders aren't kept here;
/// they're derived and cached by render key.
struct ScreenshotsDocument: Codable, Hashable, Sendable {
    static let currentFormat = 1

    var format = Self.currentFormat
    var history: TemplateHistory?
    var captions: CaptionBook
    var captures: CaptureIndex
    var scope: LocaleScope
    /// Names for the slots, from the capture files ("Today", "Week"…).
    var slotNames: [String]
    var pushed: [PushedRender]
    /// Assistants' proposals, decided or not, oldest first.
    var proposals: [ScreenshotProposal]

    init(
        history: TemplateHistory? = nil,
        captions: CaptionBook = CaptionBook(),
        captures: CaptureIndex = CaptureIndex(),
        scope: LocaleScope,
        slotNames: [String] = [],
        pushed: [PushedRender] = [],
        proposals: [ScreenshotProposal] = []
    ) {
        self.history = history
        self.captions = captions
        self.captures = captures
        self.scope = scope
        self.slotNames = slotNames
        self.pushed = pushed
        self.proposals = proposals
    }

    /// A document with nothing in it yet.
    static func empty(primary: String) -> ScreenshotsDocument {
        ScreenshotsDocument(scope: LocaleScope(primary: primary))
    }

    var template: ScreenshotTemplate? { history?.currentTemplate }

    /// Slots in the set: the template's, else as many as the captures use,
    /// else five.
    var slotCount: Int {
        if let template { return template.slots.count }
        let fromCaptures = (captures.captures.map(\.slot).max() ?? -1) + 1
        return fromCaptures > 0 ? fromCaptures : 5
    }

    /// "Today", or "Slot 1" without a name.
    func slotName(_ slot: Int) -> String {
        slotNames.indices.contains(slot) ? slotNames[slot] : String(localized: "Slot \(slot + 1)")
    }

    func pushedRender(for cell: ScreenshotCellKey) -> PushedRender? {
        pushed.last { $0.cell == cell }
    }

    /// The waiting proposal with a caption for `locale` and `slot`.
    func proposal(locale: String, slot: Int) -> ScreenshotProposal? {
        proposals.first { $0.touches(locale: locale, slot: slot) }
    }
}
