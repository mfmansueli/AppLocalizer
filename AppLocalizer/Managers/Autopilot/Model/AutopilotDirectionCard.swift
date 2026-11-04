//
//  AutopilotDirectionCard.swift
//  AppLocalizer
//

import Foundation

/// What each of Design's three cards shows. A card only spins while
/// someone works on it: the next direction designs while the assistant
/// works on the run, the ones after it are up next, and while nobody works
/// on it they all wait (the sheet says why, with Continue).
enum AutopilotDirectionCard: Hashable, Sendable {
    case arrived(AutopilotDirection)
    /// Since the assistant read the brief or the last direction arrived,
    /// after the person handed the design over; nil before either.
    case designing(since: Date?)
    case upNext
    case waiting

    var isArrived: Bool {
        if case .arrived = self { return true }
        return false
    }

    static func cards(of run: AutopilotRun, isWorking: Bool) -> [AutopilotDirectionCard] {
        (0..<AutopilotRun.directionCount).map { index in
            if run.directions.indices.contains(index) { return .arrived(run.directions[index]) }
            guard isWorking else { return .waiting }
            return index == run.directions.count ? .designing(since: designingSince(in: run)) : .upNext
        }
    }

    /// The latest of the brief's reading and the directions' arrival since
    /// the person handed the design over.
    private static func designingSince(in run: AutopilotRun) -> Date? {
        let handedOver = run.handedBackAt ?? .distantPast
        return ([run.briefReadAt].compactMap(\.self) + run.directions.map(\.receivedAt)).filter { $0 >= handedOver }.max()
    }
}
