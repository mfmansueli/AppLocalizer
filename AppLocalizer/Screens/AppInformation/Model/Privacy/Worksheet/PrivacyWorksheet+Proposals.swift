//
//  PrivacyWorksheet+Proposals.swift
//  AppLocalizer
//

import Foundation

// What an assistant sends through `propose_privacy_answers`: suggestions
// that wait for review, open questions, and the scan they came from.
extension PrivacyWorksheet {
    /// An assistant started reading the questionnaire: a running scan, or
    /// more activity on the one already running.
    mutating func beginScan(by assistant: String, at date: Date) {
        if var running = activeScan(at: date), running.assistant == assistant {
            running.lastActivity = date
            runningScan = running
        } else {
            runningScan = PrivacyRunningScan(assistant: assistant, startedAt: date, lastActivity: date)
        }
    }

    /// Adds an assistant's answer for `type`:
    /// - a type nobody answered, or an unreviewed or accepted suggestion
    ///   that differs, takes the suggestion, unreviewed;
    /// - an answer the person gave (their own, edited or rejected) that
    ///   differs keeps theirs and shows the assistant's as a conflict;
    /// - the same answer only refreshes the evidence.
    @discardableResult
    mutating func propose(_ suggestion: PrivacySuggestion, for type: PrivacyDataType, at date: Date) -> PrivacyProposalOutcome {
        recordDeclarations(in: suggestion.evidence)
        let outcome = merge(suggestion, for: type)
        if outcome != .unchanged, suggestion.answer.collected, collects == nil {
            collects = PrivacyCollectsAnswer(value: true, status: .unreviewed, client: suggestion.client, confidence: suggestion.confidence)
        }
        noteActivity(by: suggestion.client, at: date) { running in
            running.answeredTypes.insert(type)
            if outcome != .unchanged { running.changedTypes.insert(type) }
        }
        return outcome
    }

    /// An assistant's answer to the first question. It replaces an
    /// unreviewed one; the person's own answer stays.
    @discardableResult
    mutating func proposeCollects(_ value: Bool, confidence: PrivacyConfidence, by client: String) -> PrivacyProposalOutcome {
        if let collects, collects.status != .unreviewed {
            return collects.value == value ? .unchanged : .conflict
        }
        if collects?.value == value { return .unchanged }
        collects = PrivacyCollectsAnswer(value: value, status: .unreviewed, client: client, confidence: confidence)
        return .queued
    }

    /// Adds an open question, or replaces the open one with the same id. A
    /// question the person already answered stays answered.
    @discardableResult
    mutating func ask(_ question: PrivacyOpenQuestion, at date: Date) -> PrivacyProposalOutcome {
        noteActivity(by: question.client, at: date) { $0.questionIDs.insert(question.id) }
        guard let index = questions.firstIndex(where: { $0.id == question.id }) else {
            questions.append(question)
            return .queued
        }
        guard questions[index].isOpen else { return .unchanged }
        if questions[index] == question { return .unchanged }
        questions[index] = question
        return .queued
    }

    /// Keeps what the assistant said about the scan itself (repository,
    /// SDKs, manifests), merged over earlier calls.
    mutating func recordScanDetails(_ details: PrivacyScan, at date: Date) {
        noteActivity(by: details.assistant, at: date) { running in
            guard var scan = running.scan else {
                running.scan = details
                return
            }
            scan.repository = details.repository ?? scan.repository
            scan.commit = details.commit ?? scan.commit
            scan.sdks = details.sdks.isEmpty ? scan.sdks : details.sdks
            scan.manifestsRead = details.manifestsRead.isEmpty ? scan.manifestsRead : details.manifestsRead
            scan.trackingSignals = details.trackingSignals ?? scan.trackingSignals
            scan.couldNotSee = details.couldNotSee ?? scan.couldNotSee
            running.scan = scan
        }
    }

    /// The assistant sent its last answers: the running scan becomes the
    /// latest scan, with what changed since the one before it.
    mutating func finishScan(at date: Date) {
        guard let running = runningScan else { return }
        var scan = running.scan ?? PrivacyScan(assistant: running.assistant, ranAt: date)
        scan.assistant = running.assistant
        scan.ranAt = date
        scan.suggestionCount = running.answeredTypes.count
        scan.questionCount = running.questionIDs.count
        if let previous = lastScan {
            let before = Set(previous.sdks.map(\.name))
            let after = Set(scan.sdks.map(\.name))
            let changed = PrivacyDataType.allCases.filter(running.changedTypes.contains)
            scan.changes = PrivacyScanChanges(
                since: previous.ranAt,
                addedSDKs: scan.sdks.filter { !before.contains($0.name) },
                removedSDKs: previous.sdks.filter { !after.contains($0.name) },
                changedTypes: changed,
                unchangedCount: max(0, running.answeredTypes.count - changed.count)
            )
        }
        scans.append(scan)
        runningScan = nil
    }

    // MARK: - Private

    private mutating func merge(_ suggestion: PrivacySuggestion, for type: PrivacyDataType) -> PrivacyProposalOutcome {
        guard var entry = entries[type] else {
            entries[type] = .suggested(suggestion)
            return .queued
        }
        defer { entries[type] = entry }
        if entry.answer == suggestion.answer {
            entry.suggestion = suggestion
            entry.conflict = nil
            return .unchanged
        }
        switch entry.status {
        case .unreviewed, .accepted:
            entry = .suggested(suggestion)
            return .queued
        case .yours, .edited, .rejected:
            if entry.conflict?.answer == suggestion.answer {
                entry.conflict = suggestion
                return .unchanged
            }
            entry.conflict = suggestion
            return .conflict
        }
    }

    /// Remembers which SDK manifests declare which types, for the
    /// cross-check.
    private mutating func recordDeclarations(in evidence: [PrivacyEvidence]) {
        for item in evidence {
            guard let type = item.declaredType, let sdk = item.sdkName else { continue }
            if !manifestDeclarations[type, default: []].contains(sdk) {
                manifestDeclarations[type, default: []].append(sdk)
            }
        }
    }

    private mutating func noteActivity(by assistant: String, at date: Date, _ update: (inout PrivacyRunningScan) -> Void) {
        beginScan(by: assistant, at: date)
        guard var running = runningScan else { return }
        update(&running)
        runningScan = running
    }
}
