//
//  ScreenshotStudioModel+Guided.swift
//  AppLocalizer
//

import Foundation

/// The guided Autopilot: which front shows, the setup steps' changes,
/// Review & push's approvals and checks, and the push from the sheet.
extension ScreenshotStudioModel {
    // MARK: - Steps

    /// The step the guided sheet shows.
    var guidedStep: GuidedStep { GuidedStep.step(of: run, setup: guided.setupStep) }

    /// The Screenshots page's strip for the guided front. Between runs it
    /// says what the assistant sent for the next plan.
    func guidedStrip(assistant: String?) -> AutopilotStripContent {
        var strip = AutopilotStripContent.guided(
            run: run, appName: app.name, assistant: assistant, designProject: designProject, hasNewSet: hasNewSet,
            stall: stall, now: autopilot?.now() ?? .now
        )
        if [nil, .plan, .ready].contains(run?.stage), let line = planProposalsLine { strip.text += " " + line }
        return strip
    }

    /// The stepper's position (between Choose and Review & push while
    /// localizing).
    var guidedPosition: Double { GuidedStep.position(of: run, setup: guided.setupStep) }

    // MARK: - Setup

    /// Start…, Continue Setup… and New Run…: a new plan starts at What to
    /// make with the guided stops; an open plan or a run in progress opens
    /// where it is.
    func runGuidedAutopilot() {
        let before = run?.id
        runAutopilot()
        guard let run, run.stage == .plan, run.id != before else { return }
        guided.reset()
        updatePlan { GuidedDefaults.apply(to: &$0) }
    }

    /// What to make's cards.
    func setGuidedMakes(_ part: GuidedReviewPart, _ isOn: Bool) {
        guard let current = run else { return }
        let devices = planDevices(current.plan)
        let canReuse = current.keptFrom != nil
        updatePlan { GuidedDefaults.setMakes(part, isOn, in: &$0, devices: devices, canReuse: canReuse) }
    }

    /// Start Autopilot from the plan, asking once to send "Autopilot needs
    /// you" notifications.
    func startGuided() {
        if autopilot?.holdsStages != true { AutopilotTurnNotifier.shared.requestAuthorization() }
        start()
    }

    /// "On the App Store now: Caption above device · template v4".
    var guidedLiveLookText: String {
        Self.liveLookText(
            template: screenshots.document?.template?.name, app: app.name, version: keptTemplateVersion,
            isLive: screenshots.live.screenshotSets.contains(where: { !$0.screenshots.isEmpty })
        )
    }

    /// The set's look, and whether it's on the App Store: Bruma's said
    /// "On the App Store now: Bruma… Caption above device · template v1"
    /// with nothing pushed yet, and the app's name in front of the look's.
    static func liveLookText(template: String?, app: String, version: Int?, isLive: Bool) -> String {
        guard var name = template else {
            return isLive
                ? String(localized: "On the App Store now: screenshots made outside AppLocalizer")
                : String(localized: "On the App Store now: no screenshots yet")
        }
        // A starter is named "Bruma – Gay Dating Nearby · Caption above device".
        if name.hasPrefix(app + " · ") { name.removeFirst(app.count + 3) }
        let look = version.map { String(localized: "\(name) · template v\($0)") } ?? name
        return isLive ? String(localized: "On the App Store now: \(look)") : String(localized: "Your look so far: \(look), not on the App Store yet")
    }

    /// The live set's first screenshots on iPhone in the primary language,
    /// for What to make and Keep your current look.
    func guidedLiveShots(count: Int) -> [StudioShot] {
        var builder = builder
        builder.choice = .live
        builder.displayType = .iPhone
        builder.locale = primaryLocale.code
        let shots = builder.preview().shots.filter { shot in
            if case .none = shot.image { return false }
            return true
        }
        return Array(shots.prefix(count))
    }

    // MARK: - Choose

    /// Ask for Changes… on one screenshot look: the note names it, and only
    /// the looks go back to the design AI; the headers stay as they are.
    func askForChanges(_ note: String, to direction: AutopilotDirection) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let run else { return }
        let named = Self.directionNote(trimmed, name: direction.name)
        if run.usesConcepts {
            // No concepts: the note is for the directions only.
            autopilot?.requestConceptChanges(named, conceptIDs: [], forDirections: true, appID: app.id)
        } else {
            autopilot?.requestRevision(named, appID: app.id)
        }
        viewedStep = nil
        let goOn = goingOn()
        Task { await goOn() }
    }

    /// "For “Night Ink”: bigger headline".
    static func directionNote(_ note: String, name: String) -> String {
        String(localized: "For “\(name)”: \(note)")
    }

    // MARK: - Review & push

    /// The parts the run makes, in tab order.
    var guidedParts: [GuidedReviewPart] {
        run.map { GuidedReviewPart.parts(of: $0.plan) } ?? []
    }

    func isApproved(_ part: GuidedReviewPart) -> Bool {
        run?.guidedReview?.isApproved(part) == true
    }

    /// The tab shown: the one chosen, else the first not approved yet.
    var guidedShownPart: GuidedReviewPart? {
        let parts = guidedParts
        if let part = guided.reviewPart, parts.contains(part) { return part }
        return parts.first { !isApproved($0) } ?? parts.first
    }

    var guidedApprovedCount: Int { guidedParts.count(where: isApproved) }

    /// Every part is approved and the run is ready: Push to App Store…
    /// can go.
    var canPushGuided: Bool {
        run?.stage == .ready && !guidedParts.isEmpty && guidedApprovedCount == guidedParts.count && !isPushingGuided
    }

    /// A watched part can't be approved while the design source revises
    /// it or AppLocalizer makes it again.
    func canApprove(_ part: GuidedReviewPart) -> Bool {
        guard let run else { return false }
        guard GuidedReviewPart.watched(in: run).contains(part) else { return run.stage == .ready || run.stage == .watchPreview }
        return run.previewReview?.isBusy != true && !AutopilotCenter.loopIsBusy(run)
    }

    /// Approve (or take back) a part; on to the next one not approved.
    /// Approving the last part Watch the App Preview holds approves it,
    /// and the run is ready to push.
    func toggleApproval(_ part: GuidedReviewPart) {
        guard let autopilot else { return }
        let approving = !isApproved(part)
        autopilot.update(app.id) { run in
            var review = run.guidedReview ?? AutopilotGuidedReview()
            review.toggle(part)
            run.guidedReview = review
        }
        guard approving, let run else { return }
        if let next = guidedParts.first(where: { !isApproved($0) }) { guided.reviewPart = next }
        let watched = GuidedReviewPart.watched(in: run)
        if !watched.isEmpty, watched.allSatisfy(isApproved) { approvePreview() }
    }

    /// The checks beside `part`.
    func guidedChecks(for part: GuidedReviewPart) -> [GuidedCheck] {
        guard let run else { return [] }
        return GuidedReviewChecks.checks(for: part, run: run, previews: runPreviews, app: app.name)
    }

    /// Looks Good on a shortened caption.
    func confirmShortenings(_ check: GuidedCheck) {
        autopilot?.update(app.id) { run in
            var review = run.guidedReview ?? AutopilotGuidedReview()
            review.confirm(check.shortenings)
            run.guidedReview = review
        }
    }

    /// Edit… on a shortened caption, and Edit Captions…: the Captions
    /// tab, where every language's captions are.
    func editGuidedCaptions() {
        isAutopilotPresented = false
        screenshots.tab = .captions
    }

    /// The new set's screenshots in `locale` on `device`.
    func guidedNewShots(locale: String, device: ScreenshotDisplayType) -> [StudioShot] {
        var builder = builder
        builder.choice = .new
        builder.displayType = device
        builder.locale = locale
        return builder.preview().shots
    }

    /// Review & push's screenshots full size, from `index`: "English (U.S.)
    /// · iPhone 6.9″ · 1320 × 2868 · not pushed".
    func openGuidedShots(_ shots: [StudioShot], locale: String, device: ScreenshotDisplayType, at index: Int) {
        show(guidedViewerItems(shots, locale: locale, device: device), at: index)
        viewerReviewDevice = viewer == nil ? nil : device
    }

    private func guidedViewerItems(_ shots: [StudioShot], locale: String, device: ScreenshotDisplayType) -> [StudioViewerItem] {
        let language = StoreLocaleCatalog.locale(code: locale)?.name ?? locale
        return shots.map { shot in
            StudioViewerItem(
                id: "guided.\(shot.slot)", title: shot.label,
                subtitle: [language, device.title, shot.pixelSize.title, String(localized: "not pushed")].joined(separator: " · "),
                content: .shot(shot)
            )
        }
    }

    /// The viewer's language switch over Review & push's screenshots: the
    /// same screen in `code`, and the strip behind it too.
    func setViewerReviewLocale(_ code: String) {
        guided.reviewLocale = code
        guard let device = viewerReviewDevice, let index = viewer?.index else { return }
        let items = guidedViewerItems(guidedNewShots(locale: code, device: device), locale: code, device: device)
        guard !items.isEmpty else { return }
        viewer = StudioViewer(items: items, index: min(index, items.count - 1))
    }

    /// The languages the viewer offers over Review & push's screenshots:
    /// the ones side by side, and the one shown when it's from the menu.
    var viewerReviewLocales: [String] {
        let picked = guidedReviewLocales
        let shown = guidedReviewLocale
        return picked.contains(shown) ? picked : picked + [shown]
    }

    /// The devices Review & push shows the screenshots on: the plan's that
    /// have a set.
    var guidedReviewDevices: [ScreenshotDisplayType] {
        guard let plan = run?.plan else { return [] }
        return GuidedTemplatePreviewDevices.order.filter { plan.displayTypes.contains($0) && ScreenshotDisplayType.studio.contains($0) }
    }

    /// The new set's header and search (or the one image) in `locale`.
    /// The run's header or search artwork couldn't be made: Review & push
    /// says why, with Make Again.
    var guidedArtworkMissing: GuidedArtworkMissing? {
        run.flatMap { GuidedArtworkMissing(run: $0, extras: screenshots.document?.extras) }
    }

    func guidedArtwork(locale: String) -> [StudioArtworkItem] {
        guard let document = screenshots.document, let extras = document.extras, let size = extras.artworkSize else { return [] }
        let template = document.template ?? conceptLook
        return [size.headerKind, size.searchKind].compactMap(\.self).reduce(into: []) { items, kind in
            guard !items.contains(where: { $0.kind == kind }) else { return }
            items.append(artworkItem(extras.place(kind), template: template, locale: locale))
        }
    }

    /// The languages Review & push offers side by side; the rest go in a
    /// menu.
    var guidedReviewLocales: [String] {
        guard let plan = run?.plan else { return [primaryLocale.code] }
        return GuidedPreviewLocales.pick(from: plan.localeCodes, primary: plan.primaryLocale)
    }

    var guidedReviewLocale: String {
        guard let plan = run?.plan else { return primaryLocale.code }
        if let locale = guided.reviewLocale, plan.localeCodes.contains(locale) { return locale }
        return plan.primaryLocale
    }

    // MARK: - Push

    var isPushingGuided: Bool { guided.isPreparingPush }

    /// Push to App Store…: the set's images and extras go to App Store
    /// Connect through Review & Push's own pushes, shown on Done.
    func pushGuided(with push: PushController) async {
        guard run?.stage == .ready, !guided.isPreparingPush else { return }
        let controller = push.screenshots
        guard controller.canPush else {
            guided.pushError = String(localized: "App Store Connect isn’t connected for pushing. Open Review & Push… to see why.")
            return
        }
        guard !controller.isRunning, !controller.extras.isPushing else {
            guided.pushError = String(localized: "A push is already going. Wait for it to finish, then push again.")
            return
        }
        guided.pushError = nil
        guided.isPreparingPush = true
        defer { guided.isPreparingPush = false }
        await controller.loadPlan(for: app)
        let plans = controller.plans(for: [app.id]).filter(\.canPush)
        let extras = controller.extras.plans(for: [app.id])
        let hasImages = plans.contains { !$0.items.isEmpty }
        let hasExtras = extras.contains { !controller.extras.checkedItems(in: $0).isEmpty }
        guard hasImages || hasExtras else {
            if let reason = controller.plans(for: [app.id]).first?.blockedReason {
                guided.pushError = reason
            } else {
                guided.pushError = String(localized: "Nothing new to push: App Store Connect already has all of it.")
            }
            return
        }
        if hasImages { controller.push(plans) }
        if hasExtras { controller.pushExtras(extras) }
        let now = autopilot?.now() ?? .now
        autopilot?.update(app.id) { run in
            var review = run.guidedReview ?? AutopilotGuidedReview()
            review.pushedAt = now
            run.guidedReview = review
        }
        guided.isConfirmingPush = false
    }

    /// Open Review & Push…: what couldn't be sent, retried from there.
    func openReviewPush(_ navigator: WorkspaceNavigator?) {
        isAutopilotPresented = false
        navigator?.isReviewPresented = true
    }
}
