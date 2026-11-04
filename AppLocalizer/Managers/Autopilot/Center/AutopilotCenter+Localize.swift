//
//  AutopilotCenter+Localize.swift
//  AppLocalizer
//

import Foundation

/// Using a direction: the set is saved, every language checked, and the
/// captions that don't fit go to the assistant. Once they all fit, the
/// extras are made.
extension AutopilotCenter {
    /// Use This Direction: saves it as the next template version with the
    /// picked captures, then checks every language.
    func useDirection(_ directionID: String, appID: StoreApp.ID, context: AutopilotContext) async {
        guard let run = runs[appID], run.stage == .choose || run.stage == .design,
              let direction = run.directions.first(where: { $0.id == directionID }) else { return }
        update(appID) { run in
            run.stage = .localize
            run.chosenDirectionID = directionID
            run.handedBackAt = now()
            run.overflows = []
            run.localeStatus = Dictionary(uniqueKeysWithValues: run.plan.localeCodes.map { ($0, AutopilotLocaleStatus.waiting) })
            run.appendLog(String(localized: "Using \(direction.name)"), kind: .event, at: now())
        }
        guard !holdsStages, let current = runs[appID] else { return }
        // Without screenshots the set stays as it is: only the extras.
        guard current.plan.makesScreenshots else {
            await checkExtrasOnly(appID, context: context)
            return
        }
        await whileLocalizing(appID) {
            let localizer = AutopilotLocalizer(context: context, now: now())
            do {
                let version = try await localizer.apply(direction, of: current)
                // Cancel Run while it saved: the version stays in the set's history.
                guard runs[appID]?.stage == .localize else { return }
                update(appID) { $0.templateVersion = version }
                await check(appID, with: localizer)
            } catch {
                update(appID) { run in
                    guard run.stage == .localize else { return }
                    run.appendLog(String(localized: "Couldn’t save the set: \(error.localizedDescription)"), kind: .problem, at: now())
                    run.stage = .choose
                }
            }
        }
    }

    /// Captions the assistant wrote or shortened while localizing, saved
    /// right away; the shortened ones are listed for the person to check.
    func applyCaptions(_ captions: [AutopilotCaptionUpdate], client: String, appID: StoreApp.ID, context: AutopilotContext) async throws {
        guard let run = runs[appID], run.stage == .localize else {
            throw AutopilotError(String(localized: "The run isn’t localizing now. Without run, propose_captions queues a proposal instead."))
        }
        let localizer = AutopilotLocalizer(context: context, now: now())
        let shortened = try await localizer.save(captions, client: client, overflows: run.overflows)
        update(appID) { run in
            for item in shortened {
                run.shortenings.removeAll { $0.locale == item.locale && $0.slot == item.slot }
                run.shortenings.append(item)
            }
            for caption in captions {
                run.appendLog(String(localized: "\(client) wrote \(caption.locale) slot \(caption.slot + 1): “\(caption.headline)”"), kind: .event, at: now())
            }
            run.appendLog(
                String(localized: "\(client) sent \(AutopilotCaptionWork.captions(captions.count)); checking every language again"),
                kind: .command, at: now()
            )
        }
        await check(appID, with: localizer)
    }

    /// Checks every language, one at a time; ready when every caption fits.
    /// Cancel Run stops it between languages.
    func check(_ appID: StoreApp.ID, with localizer: AutopilotLocalizer) async {
        await whileLocalizing(appID) { await checkEveryLanguage(appID, with: localizer) }
    }

    private func checkEveryLanguage(_ appID: StoreApp.ID, with localizer: AutopilotLocalizer) async {
        // The set's captions stay as they are: only the artwork's texts.
        if runs[appID]?.plan.makesScreenshots == false {
            await checkExtrasOnly(appID, context: localizer.context)
            return
        }
        guard let run = runs[appID], run.stage == .localize, let document = await localizer.document() else { return }
        var overflows: [AutopilotOverflow] = []
        for locale in run.plan.localeCodes {
            guard runs[appID]?.stage == .localize else { return }
            update(appID) { $0.localeStatus[locale] = .checking }
            await Task.yield()
            let result = localizer.check(locale: locale, of: run, in: document)
            overflows += result.overflows
            update(appID) { $0.localeStatus[locale] = result.status }
        }
        guard runs[appID]?.stage == .localize else { return }
        update(appID) { run in
            run.overflows = overflows
            guard !overflows.isEmpty else { return }
            let client = run.client ?? String(localized: "the assistant")
            run.appendLog(String(localized: "Sent to \(client): \(AutopilotCaptionWork(overflows).summary)"), kind: .command, at: now())
        }
        guard overflows.isEmpty else { return }
        // Every caption fits: then each placement's own text.
        let needs = await artworkTextNeeds(of: run, in: document, context: localizer.context)
        guard runs[appID]?.stage == .localize else { return }
        update(appID) { run in
            run.artworkTextNeeds = needs.isEmpty ? nil : needs
            guard !needs.isEmpty else { return }
            let client = run.client ?? String(localized: "the assistant")
            run.appendLog(String(localized: "Sent to \(client): \(AutopilotArtworkTextWork(needs).summary)"), kind: .command, at: now())
        }
        guard needs.isEmpty else { return }
        // The header, search artwork and App Preview are made with them,
        // then the person watches the App Preview, or the set is ready.
        let extras = await makeExtras(appID, context: localizer.context)
        let total = runs[appID]?.totalScreenshots ?? 0
        finishMaking(appID, extras: extras, readyLine: String(localized: "\(total) screenshots ready in Review & Push"))
    }
}
