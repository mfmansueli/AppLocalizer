//
//  TemplateProposalReview.swift
//  AppLocalizer
//

import Foundation

/// A template proposal read against the history it was made for (design
/// README §6): its changes as "old → new" from the version it was based
/// on, and, when it's stale, what changed since and which paths both sides
/// changed. Rebasing re-reads each path: untouched paths apply as proposed,
/// and for a path both sides changed the person keeps theirs or uses the
/// assistant's. Pure; the Proposals sheet and the tools share it.
struct TemplateProposalReview {
    var proposal: TemplateProposal
    var history: TemplateHistory
    var applier = TemplateOperationApplier()

    /// For a path both sides changed: the person's current value, or the
    /// assistant's.
    enum Choice: String, Hashable, Sendable {
        case keepYours
        case useTheirs
    }

    /// One operation as an "old → new" row.
    struct Row: Hashable, Identifiable {
        /// Old is the value in the version the proposal was based on.
        var change: TemplateChange
        /// The current version changed this path too.
        var isConflict: Bool
        /// The current version's value, for "Keep yours · 78%".
        var currentValue: JSONValue?

        var id: String { change.path }

        var currentText: String {
            if change.slot != nil, change.fieldPath != "layout", currentValue == nil { return String(localized: "as the template") }
            return TemplateSchema.formatted(currentValue, at: change.fieldPath)
        }
    }

    var currentNumber: Int { history.currentNumber }

    /// The version accepting saves.
    var nextNumber: Int { currentNumber + 1 }

    var isStale: Bool { proposal.basedOn < currentNumber }

    /// The version it was based on; the current one when that version is
    /// gone.
    var base: ScreenshotTemplate? {
        history.version(proposal.basedOn)?.template ?? history.currentTemplate
    }

    /// The versions saved after the one it was based on, oldest first.
    var versionsSince: [TemplateVersion] {
        history.versions.filter { $0.number > proposal.basedOn }
    }

    var rows: [Row] {
        guard let base, let current = history.currentTemplate else { return [] }
        return proposal.operations.map { operation in
            let old = base.operationValue(at: operation.path)
            let now = current.operationValue(at: operation.path)
            let new = operation.value.isNull ? nil : operation.value
            return Row(
                change: TemplateChange(path: operation.path, old: old, new: new),
                isConflict: isStale && !Self.equivalent(old, now),
                currentValue: now
            )
        }
    }

    var conflicts: [Row] { rows.filter(\.isConflict) }

    /// The operations to apply to the current version: all of them, minus
    /// conflicting paths where the person keeps theirs (the default).
    func operations(choices: [String: Choice] = [:]) -> [TemplateOperation] {
        let kept = Set(conflicts.filter { (choices[$0.change.path] ?? .keepYours) == .keepYours }.map(\.change.path))
        return proposal.operations.filter { !kept.contains($0.path) }
    }

    /// The proposal on the current version, conflicts settled by `choices`.
    func rebased(choices: [String: Choice] = [:]) -> TemplateProposal {
        TemplateProposal(basedOn: currentNumber, operations: operations(choices: choices), rebasedFrom: proposal.rebasedFrom ?? proposal.basedOn)
    }

    /// The template accepting would save: the current version with the
    /// operations applied, or every reason it can't be.
    func proposedTemplate(choices: [String: Choice] = [:]) -> Result<ScreenshotTemplate, TemplateRefusals> {
        guard let current = history.currentTemplate else {
            return .failure(TemplateRefusals(items: [TemplateRefusal(path: "", kind: .stale, reason: String(localized: "There’s no template yet."))]))
        }
        return applier.applying(operations(choices: choices), to: current)
    }

    private static func equivalent(_ lhs: JSONValue?, _ rhs: JSONValue?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): true
        case let (lhs?, rhs?): lhs.isEquivalent(to: rhs)
        case let (value?, nil), let (nil, value?): value.isNull
        }
    }
}
