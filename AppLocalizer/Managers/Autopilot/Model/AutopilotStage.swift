//
//  AutopilotStage.swift
//  AppLocalizer
//

import Foundation

/// Where a Screenshot Autopilot run is. The sheet lists seven steps;
/// `waiting` (the prompt is copied, the assistant hasn't picked the plan
/// up yet) shows as Capture.
enum AutopilotStage: String, Codable, CaseIterable, Hashable, Sendable {
    case plan
    case waiting
    case capture
    case pick
    case design
    case choose
    case localize
    case ready

    /// The sheet's seven steps, in order.
    static let steps: [AutopilotStage] = [.plan, .capture, .pick, .design, .choose, .localize, .ready]

    /// The step this stage shows as.
    var step: AutopilotStage { self == .waiting ? .capture : self }

    /// 1–7.
    var number: Int { (Self.steps.firstIndex(of: step) ?? 0) + 1 }

    var title: String {
        switch self {
        case .plan: String(localized: "Plan")
        case .waiting, .capture: String(localized: "Capture")
        case .pick: String(localized: "Pick captures")
        case .design: String(localized: "Design")
        case .choose: String(localized: "Choose a direction")
        case .localize: String(localized: "Localize and check")
        case .ready: String(localized: "Review & Push")
        }
    }

    /// Something works on its own: the strip shows progress and the sheet
    /// can be hidden.
    var isRunning: Bool {
        switch self {
        case .waiting, .capture, .design, .localize: true
        case .plan, .pick, .choose, .ready: false
        }
    }

    /// A checkpoint: the run waits for the person ("Your turn").
    var waitsForPerson: Bool { self == .pick || self == .choose }

    /// Whether this stage comes before `other` among the steps.
    func isBefore(_ other: AutopilotStage) -> Bool { number < other.number }
}
