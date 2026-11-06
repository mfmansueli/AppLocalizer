//
//  GuidedStep.swift
//  AppLocalizer
//

import Foundation

/// The guided Autopilot's steps: three to set the run up, then Making it,
/// and the person's two: Choose and Review & push. Done follows the push.
enum GuidedStep: Int, CaseIterable, Hashable, Sendable {
    case make
    case look
    case plan
    case making
    case choose
    case review
    case done

    /// The steps the stepper shows, in order.
    static let stepper: [GuidedStep] = [.make, .look, .plan, .making, .choose, .review]

    var title: String {
        switch self {
        case .make: String(localized: "What to make")
        case .look: String(localized: "Look")
        case .plan: String(localized: "Plan")
        case .making: String(localized: "Making it")
        case .choose: String(localized: "Choose")
        case .review: String(localized: "Review & push")
        case .done: String(localized: "Sent")
        }
    }

    /// 1–6 on the stepper.
    var number: Int { rawValue + 1 }

    /// "make", "choose": the step in accessibility identifiers.
    var identifier: String { String(describing: self) }

    /// One of the two stops: the stepper marks it You.
    var isYours: Bool { self == .choose || self == .review }

    /// Make, Look and Plan: the run isn't started yet.
    var isSetup: Bool { self == .make || self == .look || self == .plan }

    /// Where a run is: the setup step the person is on while it's planned,
    /// Making it while anything works on it (and at Pick captures, which
    /// it shows), Choose, Review & push at Watch and Ready, and Done once
    /// it's pushed from here.
    static func step(of run: AutopilotRun?, setup: GuidedStep) -> GuidedStep {
        guard let run else { return setup.isSetup ? setup : .make }
        switch run.stage {
        case .plan: return setup.isSetup ? setup : .make
        case .waiting, .capture, .pick, .design, .localize: return .making
        case .choose: return .choose
        case .watchPreview: return .review
        case .ready: return run.guidedReview?.pushedAt == nil ? .review : .done
        }
    }

    /// The stepper's position: a step's index, and between Choose and
    /// Review & push while localizing, so Choose shows done and nothing
    /// shows current.
    static func position(of run: AutopilotRun?, setup: GuidedStep) -> Double {
        if run?.stage == .localize { return Double(GuidedStep.choose.rawValue) + 0.5 }
        return Double(step(of: run, setup: setup).rawValue)
    }

    /// How the stepper draws this step at `position`.
    func state(at position: Double) -> GuidedStepState {
        let index = Double(rawValue)
        if index < position { return .done }
        return index == position ? .current : .upcoming
    }
}
