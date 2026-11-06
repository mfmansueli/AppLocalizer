//
//  GuidedSheetModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// What the guided Autopilot sheet shows that isn't the run's: the setup
/// step the person is on, what the Look step previews, the plan's folds,
/// Review & push's tab, language and device, and the push confirmation.
@MainActor
@Observable
final class GuidedSheetModel {
    /// Make, Look or Plan while the run is planned.
    var setupStep: GuidedStep = .make
    /// The template the Look step previews large; nil is the first pick,
    /// else Cinema.
    var templateFocus: TemplateStarter?
    /// The template list's style filter; nil shows every template.
    var templateStyle: TemplateStarter.Style?
    /// The language the template preview shows; nil is the primary one.
    var templateLocale: String?
    /// The header scene the Look step previews large; nil is the first
    /// pick, else the recommended one.
    var headerFocus: AutopilotHeaderTemplate?
    /// The plan's screens under the capture line.
    var showsScreens = false
    /// The plan's simulator options.
    var showsSimulator = false
    /// Making it's log.
    var showsDetails = false
    /// Review & push's tab; nil is the first part not approved yet.
    var reviewPart: GuidedReviewPart?
    /// Review & push's language; nil is the primary one.
    var reviewLocale: String?
    var reviewDevice: ScreenshotDisplayType = .iPhone
    var isConfirmingPush = false
    /// Why the push couldn't start.
    var pushError: String?
    /// The push from Done, while it's being planned.
    var isPreparingPush = false

    /// A new run starts at What to make.
    func reset() {
        setupStep = .make
        templateFocus = nil
        templateStyle = nil
        templateLocale = nil
        headerFocus = nil
        showsScreens = false
        showsSimulator = false
        showsDetails = false
        reviewPart = nil
        reviewLocale = nil
        reviewDevice = .iPhone
        isConfirmingPush = false
        pushError = nil
        isPreparingPush = false
    }
}
