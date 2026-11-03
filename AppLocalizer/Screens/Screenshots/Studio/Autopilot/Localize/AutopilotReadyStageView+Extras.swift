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

    func extrasNotes(direction: String) -> [AutopilotReadyNote] {
        var notes: [AutopilotReadyNote] = []
        let extras = studio.screenshots.document?.extras
        if !run.plan.artworkKinds.isEmpty {
            let wide = run.plan.alsoMakes.artworkSize == .wide
            let header = AutopilotArtworkKind.header.pixelSize.title
            let search = AutopilotArtworkKind.search.pixelSize.title
            var detail = wide
                ? String(localized: "One \(AutopilotArtworkKind.wide.pixelSize.title) image per language for both places, in \(direction). Shown in the preview.")
                : run.plan.alsoMakes.artworkMotion == .loop
                ? String(localized: "Header \(header) and search \(search) in each language, as 20-second silent loops (.mov, 30 fps) with a still poster frame, in \(direction). Shown in the preview.")
                : String(localized: "Header \(header) and search \(search) in each language, in \(direction). Shown in the preview.")
            if let tooLong = extras?.tooLongLocales, !tooLong.isEmpty {
                let names = tooLong.map { StoreLocaleCatalog.locale(code: $0)?.shortName ?? $0 }.formatted(.list(type: .and))
                detail += " " + String(localized: "The headline is too long for it in \(names): shorten that caption and run Autopilot again, or leave the artwork out there.")
            }
            notes.append(AutopilotReadyNote(
                title: wide ? String(localized: "Header and search image · 16:9") : String(localized: "Header and search results artwork"),
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
}
