//
//  AppPrivacyViewModel+Checklist.swift
//  AppLocalizer
//

import AppKit
import Foundation

// "Fill in App Store Connect": the steps to copy in, ticks, and Mark as
// Published.
extension AppPrivacyViewModel {
    /// App Store Connect's App Privacy page for this app.
    var appStoreConnectURL: URL {
        URL(string: "https://appstoreconnect.apple.com/apps/\(app.id)/distribution/privacy") ?? URL(filePath: "/")
    }

    var steps: [PrivacyChecklistStep] { worksheet.checklistSteps }

    func isChecked(_ step: PrivacyChecklistStep) -> Bool {
        worksheet.isChecked(step)
    }

    func setChecked(_ step: PrivacyChecklistStep, _ isChecked: Bool) {
        update { $0.setChecked(step, isChecked) }
    }

    /// "3 of 12 steps".
    var progressText: String {
        String(localized: "\(worksheet.checkedStepCount) of \(steps.count) steps")
    }

    var progress: Double {
        let count = steps.count
        return count == 0 ? 0 : Double(worksheet.checkedStepCount) / Double(count)
    }

    func copyStep(_ step: PrivacyChecklistStep) {
        copy("\(step.title): \(step.body)")
        copiedStepID = step.id
    }

    /// Shown once the worksheet is done and isn't marked published as it is.
    var canMarkPublished: Bool {
        let worksheet = worksheet
        if case .published = worksheet.status { return false }
        return worksheet.isDone
    }

    func markPublished() {
        let date = now()
        update { $0.markPublished(at: date) }
        let day = date.formatted(date: .abbreviated, time: .omitted)
        say(String(localized: "Marked as published in App Store Connect on \(day). AppLocalizer will flag the worksheet if a later scan changes these answers."))
    }

    /// "Marked as published in App Store Connect on Oct 26, 2026. …".
    var publishedText: String? {
        guard case let .published(date) = worksheet.status else { return nil }
        let day = date.formatted(date: .abbreviated, time: .omitted)
        return String(localized: "Marked as published in App Store Connect on \(day). A copy of these answers is kept; a later scan that changes them flags the worksheet.")
    }

    /// "Tile with Safari": App Store Connect opens in Safari, and this
    /// window takes the left half of its screen, as the checklist suggests.
    func tileWithSafari() {
        let configuration = NSWorkspace.OpenConfiguration()
        if let safari = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") {
            NSWorkspace.shared.open([appStoreConnectURL], withApplicationAt: safari, configuration: configuration)
        } else {
            NSWorkspace.shared.open(appStoreConnectURL)
        }
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow, let screen = window.screen else { return }
        var frame = screen.visibleFrame
        frame.size.width = (frame.width / 2).rounded()
        window.setFrame(frame, display: true, animate: true)
    }
}
