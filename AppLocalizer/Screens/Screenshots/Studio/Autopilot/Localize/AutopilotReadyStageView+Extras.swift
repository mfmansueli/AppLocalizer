//
//  AutopilotReadyStageView+Extras.swift
//  AppLocalizer
//

import Foundation

/// Ready for review's notes on the extras, first: the header and search
/// artwork (See in Preview) and the App Preview (Play).
extension AutopilotReadyStageView {
    /// ", plus header and search artwork and an App Preview in every
    /// language"; empty without extras.
    var extrasSummaryPart: String {
        run.plan.extrasTitle.map { ", " + String(localized: "plus \($0)") } ?? ""
    }

    /// The artwork the run makes couldn't be made: it isn't in Review &
    /// Push.
    var artworkMissing: Bool {
        AutopilotCenter.artworkMissing(run, extras: studio.screenshots.document?.extras)
    }

    /// "Header artwork couldn’t be made, so it isn’t in Review & Push…"
    var missingArtworkSummary: String {
        let what = run.plan.alsoMakes.artworkSize.artworkTitle
        return String(localized: "\(what) couldn’t be made, so it isn’t in Review & Push. Make Again tries again with what you chose.")
    }

    func extrasNotes(direction: String) -> [AutopilotReadyNote] {
        var notes: [AutopilotReadyNote] = []
        let extras = studio.screenshots.document?.extras
        if artworkMissing {
            notes.append(missingArtworkNote)
        } else if !run.plan.artworkKinds.isEmpty {
            let size = run.plan.alsoMakes.artworkSize
            let sizes = size.sizesDetail
            var detail = run.plan.alsoMakes.makesMotion
                ? String(localized: "\(sizes) in each language, as 20-second silent loops (.mov, 30 fps) with a still poster frame, in \(direction). Shown in the preview.")
                : String(localized: "\(sizes) in each language, in \(direction). Shown in the preview.")
            if let tooLong = extras?.tooLongLocales, !tooLong.isEmpty {
                let names = tooLong.map { StoreLocaleCatalog.locale(code: $0)?.shortName ?? $0 }.formatted(.list(type: .and))
                detail += " " + String(localized: "The headline is too long for it in \(names): shorten that caption and run Autopilot again, or leave the artwork out there.")
            }
            notes.append(AutopilotReadyNote(
                title: size.artworkTitle + (size == .wide ? " · 16:9" : ""),
                detail: detail, button: String(localized: "See in Preview"), identifier: "autopilot.ready.artwork",
                checks: AutopilotCenter.checks(of: extras?.artwork ?? [])
            ) {
                studio.isAutopilotPresented = false
                studio.choice = .new
            })
        }
        if !run.plan.previewDisplays.isEmpty {
            let file = extras?.preview(on: .iPhone, locale: run.plan.primaryLocale, primary: run.plan.primaryLocale)
                ?? extras?.previews.first
            let planned = run.hasRecordingMoments ? Double(run.pickedPreviewSeconds) : Double(AutopilotExtras.previewSeconds)
            let length = file?.lengthTitle ?? ExtrasPreviewFile.lengthTitle(planned)
            let devices = run.plan.previewDisplays.map(\.shortTitle).formatted(.list(type: .and))
            let primary = StoreLocaleCatalog.locale(code: run.plan.primaryLocale)?.name ?? run.plan.primaryLocale
            var detail = run.plan.alsoMakes.previewLanguages == .all
                ? String(localized: "One per language, from each language’s recording, for \(devices). Poster frame at 0:05.")
                : String(localized: "\(primary) only, for \(devices). Other languages show it until they have their own. Poster frame at 0:05.")
            if let problem = run.extrasProgress?.previewProblems.first { detail += " " + problem }
            notes.append(AutopilotReadyNote(
                title: String(localized: "App Preview · \(length)"),
                detail: detail, button: file == nil ? nil : String(localized: "Play"), identifier: "autopilot.ready.appPreview"
            ) {
                guard let file else { return }
                studio.openPreview(file)
            })
        }
        return notes
    }

    /// Why the artwork couldn't be made, and Make Again.
    private var missingArtworkNote: AutopilotReadyNote {
        let size = run.plan.alsoMakes.artworkSize
        let reason = run.extrasProgress?.artworkProblem.map { $0.hasSuffix(".") ? $0 : $0 + "." }
            ?? String(localized: "Nothing of it was saved with the set.")
        return AutopilotReadyNote(
            title: String(localized: "\(size.artworkTitle) couldn’t be made"),
            detail: reason + " " + String(localized: "Make Again makes it again from your choices, without designing anything again."),
            button: String(localized: "Make Again"), identifier: "autopilot.ready.artworkMissing"
        ) {
            studio.makeExtrasAgain()
        }
    }
}
