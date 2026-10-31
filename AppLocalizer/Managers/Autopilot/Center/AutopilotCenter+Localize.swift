//
//  AutopilotCenter+Localize.swift
//  AppLocalizer
//

import Foundation

/// Using a direction: the set is saved, every language checked, and the
/// captions that don't fit go to the assistant.
extension AutopilotCenter {
    /// Use This Direction: saves it as the next template version with the
    /// picked captures, then checks every language.
    func useDirection(_ directionID: String, appID: StoreApp.ID, context: AutopilotContext) async {
        guard let run = runs[appID], run.stage == .choose || run.stage == .design,
              let direction = run.directions.first(where: { $0.id == directionID }) else { return }
        update(appID) { run in
            run.stage = .localize
            run.chosenDirectionID = directionID
            run.overflows = []
            run.localeStatus = Dictionary(uniqueKeysWithValues: run.plan.localeCodes.map { ($0, AutopilotLocaleStatus.waiting) })
            run.appendLog(String(localized: "Using \(direction.name)"), kind: .event, at: now())
        }
        guard !holdsStages, let current = runs[appID] else { return }
        let localizer = AutopilotLocalizer(context: context, now: now())
        do {
            let version = try await localizer.apply(direction, of: current)
            update(appID) { $0.templateVersion = version }
            await check(appID, with: localizer)
        } catch {
            update(appID) { run in
                run.appendLog(String(localized: "Couldn’t save the set: \(error.localizedDescription)"), kind: .problem, at: now())
                run.stage = .choose
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
        }
        await check(appID, with: localizer)
    }

    /// Checks every language, one at a time; ready when every caption fits.
    private func check(_ appID: StoreApp.ID, with localizer: AutopilotLocalizer) async {
        guard let run = runs[appID], let document = await localizer.document() else { return }
        var overflows: [AutopilotOverflow] = []
        for locale in run.plan.localeCodes {
            update(appID) { $0.localeStatus[locale] = .checking }
            await Task.yield()
            let result = localizer.check(locale: locale, of: run, in: document)
            overflows += result.overflows
            update(appID) { $0.localeStatus[locale] = result.status }
        }
        update(appID) { run in
            run.overflows = overflows
            if overflows.isEmpty {
                run.stage = .ready
                run.finishedAt = now()
                run.appendLog(String(localized: "\(run.totalScreenshots) screenshots ready in Review & Push"), kind: .event, at: now())
            } else {
                run.appendLog(String(localized: "\(overflows.count) captions sent to \(run.client ?? String(localized: "the assistant")) to write or shorten"), kind: .command, at: now())
            }
        }
    }
}
