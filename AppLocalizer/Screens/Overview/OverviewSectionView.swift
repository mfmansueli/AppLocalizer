//
//  OverviewSectionView.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// The landing page for the selected app (⌘1): a header with quick actions
/// and summary cards for subscriptions, territory prices, the pricing mode,
/// the store page, App Information, pending changes and the last push. It
/// runs Suggest Everything: Suggest Everything… starts Claude Code when its
/// helper is saved (else copies the prompt) and waits in a popover, and
/// once the assistant announces its plan the progress card takes the
/// assistant card's place until Done, with the run's strip under it.
struct OverviewSectionView: View {
    let app: StoreApp
    /// For the App Store page preview: the page's texts and screenshots.
    let services: any StorePageServices

    @Environment(AppSummaryStore.self) private var summaries
    @Environment(ChangeQueue.self) private var changes
    @Environment(PushHistory.self) private var history
    @Environment(PricingModeStore.self) private var pricingModes
    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(AppPreferences.self) private var preferences
    @Environment(MCPServerController.self) private var assistants
    @Environment(FieldSuggestionStore.self) private var suggestions
    @Environment(ClaudeCodeLauncher.self) private var launcher
    /// What Suggest Everything covers, read once an assistant is connected.
    @State private var scope: SuggestEverythingScope?
    @State private var showsEverythingPopover = false
    /// The page the preview shows, read when Overview opens and on Refresh.
    @State private var content: StorePageContent?
    @State private var width: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                if isLoading {
                    OverviewSkeleton()
                } else {
                    OverviewHeader(
                        app: app,
                        storePage: storePage,
                        territoryCount: pricing.map { $0.equalizedTerritoryCount + $0.customTerritoryCount },
                        showsReviewSuggestions: mode.showsSuggestions && pricing?.sellsAnything == true,
                        onReviewSuggestions: reviewSuggestions,
                        onTranslateMissing: { navigator.open(.storePage, intent: .translateMissing) },
                        onReviewAndPush: { navigator.isReviewPresented = true }
                    )
                    if let message = errorMessage {
                        InlineMessage.error(message)
                            .accessibilityIdentifier("overview.error")
                    }
                    assistantCard
                    OverviewPageAndWaiting(
                        app: app, services: services, content: content, width: width, storePage: storePage, newLanguages: newLanguages
                    )
                    Text("Details")
                        .font(.headline)
                        .padding(.top, Spacing.small)
                        .accessibilityAddTraits(.isHeader)
                    cards
                }
            }
            .padding(Spacing.xxLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
        }
        .accessibilityIdentifier("workspace.overview")
        .task(id: app.id) { await summaries.load(app) }
        .task(id: ContentKey(appID: app.id, refresh: navigator.refreshCount)) { await loadContent() }
        .task(id: ScopeKey(appID: app.id, isConnected: assistants.assistantStatus.isConnected)) {
            scope = nil
            await loadScope()
        }
        .task(id: navigator.requestsSuggestEverything) {
            guard navigator.requestsSuggestEverything else { return }
            navigator.requestsSuggestEverything = false
            // The popover needs its button on screen first.
            try? await Task.sleep(for: .milliseconds(300))
            suggestEverything()
        }
        .onChange(of: suggestions.run?.phase) {
            if suggestions.run?.phase != .waiting { showsEverythingPopover = false }
        }
        .onChange(of: launched?.phase) { launchedRunChanged() }
        #if DEBUG
        .task {
            if Self.debugRequestsSuggestEverything {
                Self.debugRequestsSuggestEverything = false
                navigator.requestsSuggestEverything = true
            }
        }
        #endif
    }

    private struct ScopeKey: Hashable {
        var appID: StoreApp.ID
        var isConnected: Bool
    }

    private struct ContentKey: Hashable {
        var appID: StoreApp.ID
        var refresh: Int
    }

    private func loadContent() async {
        let loaded = try? await services.content(for: app, versionID: nil)
        guard !Task.isCancelled else { return }
        content = loaded
    }

    /// Before an assistant is connected or a key set up, the card
    /// introducing them (until hidden); after, which one and what it can do;
    /// while Suggest Everything runs and until Done, its progress.
    @ViewBuilder
    private var assistantCard: some View {
        let status = assistants.assistantStatus
        if let run, run.phase != .waiting {
            SuggestionRunCard(
                run: run,
                toReviewCount: suggestions.toReview(in: run).count,
                onReview: review,
                onStop: {
                    suggestions.stopRun()
                    if let launched, launched.isActive { launcher.stop(launched.id) }
                },
                onDone: { suggestions.dismissRun() },
                onAcceptAll: { acceptAll(run) }
            )
            if let launched, launched.isActive || launched.failure != nil || !launched.denials.isEmpty {
                ClaudeCodeRunStatusView(run: launched)
            }
        } else if status.isConnected, let client = assistants.assistantClient {
            AssistantConnectedCard(
                client: client,
                editsDrafts: assistants.editsDrafts,
                isPopoverPresented: $showsEverythingPopover,
                onSuggestEverything: suggestEverything,
                onDetails: { navigator.requestsAssistantPopover = true },
                popover: {
                    if let run, run.phase == .waiting {
                        SuggestEverythingPopover(
                            run: run,
                            scope: currentScope,
                            busyRequest: busyRequest,
                            onCopyAgain: { Self.copy(run.prompt) },
                            onCancel: {
                                showsEverythingPopover = false
                                suggestions.dismissRun()
                                if let launched, launched.isActive { launcher.stop(launched.id) }
                            }
                        )
                    }
                }
            )
        } else if case let .ready(client) = status, let summary = assistants.keyAssistant?.summary {
            AssistantConnectedCard(keyClient: client, summary: summary) {
                navigator.open(.storePage, intent: .askForSuggestions(.storePage))
            } onDetails: {
                navigator.requestsAssistantPopover = true
            } onAddAssistant: {
                navigator.assistantSetupMethod = .assistant
                navigator.isAssistantSetupPresented = true
            }
        } else if !status.canSuggest, preferences.showsAssistantIntro {
            AssistantIntroCard(appName: app.name, status: status) {
                navigator.isAssistantSetupPresented = true
            } onWhatItDoes: {
                navigator.requestsAssistantPopover = true
            } onHide: {
                preferences.showsAssistantIntro = false
            }
        }
    }

    private var cards: some View {
        // Not lazy: under the page and what's waiting, the cards start below
        // the fold, and VoiceOver and UI tests need them all.
        AdaptiveGridLayout(minimumWidth: Metrics.overviewCardMinimumWidth, spacing: 14) {
            SuggestionsCard(
                summary: SuggestionsSummary(open: overviewSuggestions),
                assistant: assistants.assistantStatus.clientName,
                run: run,
                lockedPages: storePage?.hasEditableVersion == false ? [.appReview] : [],
                suggestTitle: assistants.assistantStatus.isReady
                    ? String(localized: "Generate Store Page Suggestions…")
                    : String(localized: "Suggest Everything…"),
                newLanguages: newLanguages,
                onSuggest: suggestEverything
            ) {
                navigator.open(.storePage, intent: .reviewFieldSuggestions(.storePage))
            }
            if let pricing {
                SubscriptionsCard(summary: pricing)
                if pricing.sellsAnything {
                    TerritoryPricesCard(summary: pricing)
                    PricingModeCard(
                        mode: mode,
                        summary: pricing,
                        onReviewSuggestions: reviewSuggestions,
                        onShowSuggestions: {
                            pricingModes.setMode(.showSuggestions, for: app.id)
                            navigator.open(.subscriptionPricing, intent: .reviewSuggestions)
                        }
                    )
                }
            }
            if let storePage {
                StorePageCard(summary: storePage, languagesText: newLanguages?.languagesText) { navigator.open(.storePage) }
            }
            if let information = summaries.appInformation[app.id]?.value {
                AppInformationCard(summary: information) {
                    navigator.open(.appInformation)
                } onOpenPrivacy: { tab in
                    navigator.open(.appInformation, intent: .openAppInformationPage(.appPrivacy, privacyTab: tab))
                }
            }
            PendingChangesCard(count: changes.count(for: app.id)) { navigator.isReviewPresented = true }
            LastPushCard(record: history.lastRecord(for: app.id)) { navigator.isActivityPresented = true }
        }
    }

    private var pricing: PricingSummary? { summaries.pricing[app.id]?.value }
    private var storePage: StorePageSummary? { summaries.storePage[app.id]?.value }
    private var mode: PricingMode { pricingModes.mode(for: app.id) }

    /// The open suggestions the Suggestions card counts: drafts of languages
    /// not added yet show as New languages instead.
    private var overviewSuggestions: [FieldSuggestion] {
        let pending = Set((newLanguages?.pending ?? []).map(\.code))
        return suggestions.toReview(for: app.id).filter { suggestion in
            guard case let .storePage(code) = suggestion.target.scope else { return true }
            return !pending.contains(code)
        }
    }

    /// The languages the app supports and its App Store page doesn't, once
    /// its assistant reported the project.
    private var newLanguages: NewLanguagesSummary? {
        guard let storePage, let appSupport = summaries.appSupport, appSupport.profile(for: app.id) != nil else { return nil }
        return NewLanguagesSummary(appID: app.id, storePage: storePage, appSupport: appSupport, changes: changes.changes(for: app.id))
    }

    private var isLoading: Bool {
        let states = [summaries.pricing[app.id]?.isLoading, summaries.storePage[app.id]?.isLoading, summaries.appInformation[app.id]?.isLoading]
        let nothingYet = pricing == nil && storePage == nil && summaries.appInformation[app.id]?.value == nil
        return nothingYet && (states.contains(true) || states.allSatisfy { $0 == nil })
    }

    /// The first failure, so a broken section doesn't hide the others.
    private var errorMessage: String? {
        summaries.pricing[app.id]?.errorMessage
            ?? summaries.storePage[app.id]?.errorMessage
            ?? summaries.appInformation[app.id]?.errorMessage
    }

    private func reviewSuggestions() {
        navigator.open(.subscriptionPricing, intent: .reviewSuggestions)
    }

    // MARK: - Suggest Everything

    /// Suggest Everything for this app, from Suggest Everything… until Done.
    private var run: SuggestionRun? {
        guard let run = suggestions.run, run.appID == app.id else { return nil }
        return run
    }

    /// A per-page Ask for this app that's still sending.
    private var busyRequest: AssistantSuggestionRequest? {
        guard let request = suggestions.request, request.appID == app.id, request.isReceiving else { return nil }
        return request
    }

    private var currentScope: SuggestEverythingScope {
        scope ?? SuggestEverythingScope(appName: app.name, versionString: storePage?.versionString)
    }

    private func loadScope() async {
        guard assistants.assistantStatus.isConnected, let workspace = assistants.workspace else { return }
        let loaded = await SuggestEverythingScope.load(app: app, in: workspace)
        guard !Task.isCancelled else { return }
        scope = loaded
    }

    /// Copies the prompt and waits for the assistant (again, when it already
    /// waits). With an API key it generates on the Store Page; with nothing
    /// set up, setup opens and says why.
    private func suggestEverything() {
        let status = assistants.assistantStatus
        guard case let .connected(client) = status else {
            if status.isReady {
                navigator.open(.storePage, intent: .askForSuggestions(.storePage))
            } else {
                navigator.setupStartsSuggestEverything = true
                navigator.isAssistantSetupPresented = true
            }
            return
        }
        if let run, run.phase == .waiting, run.client == client {
            // Started already: the popover shows that run.
            if launched == nil { Self.copy(run.prompt) }
        } else {
            let prompt = currentScope.prompt
            suggestions.beginRun(appID: app.id, client: client, prompt: prompt)
            if launcher.canStart {
                Task { await launch(prompt) }
            } else {
                Self.copy(prompt)
            }
        }
        showsEverythingPopover = true
        Task { await loadScope() }
    }

    /// The Claude Code run started for the current Suggest Everything.
    private var launched: ClaudeCodeRun? {
        guard let run = suggestions.run, run.appID == app.id else { return nil }
        return launcher.latestRun(appID: app.id, purpose: .suggestEverything, since: run.startedAt)
    }

    /// Starts Claude Code with `prompt`. With no folder chosen nothing was
    /// asked; if the helper went away, it's the paste after all.
    private func launch(_ prompt: String) async {
        guard await launcher.start(.suggestEverything, appID: app.id, appName: app.name, prompt: prompt) == nil else { return }
        if launcher.canStart {
            showsEverythingPopover = false
            suggestions.dismissRun()
        } else {
            Self.copy(prompt)
        }
    }

    /// The run ended: one that never announced a plan goes away (a failure
    /// or refused steps stay for the popover to explain); one that did is
    /// over with what arrived.
    private func launchedRunChanged() {
        guard let run = suggestions.run, run.appID == app.id, let launched else { return }
        switch (launched.phase, run.phase) {
        case (.finished, .waiting) where launched.denials.isEmpty:
            suggestions.dismissRun()
            navigator.toast = WorkspaceToast(message: ToastMessage(text: String(localized: "\(run.client) finished without sending suggestions.")))
        case (.stopped, .waiting):
            suggestions.dismissRun()
        case (.finished, .running):
            suggestions.endRun(id: run.id)
        case (.stopped, .running):
            suggestions.stopRun()
        default:
            break
        }
    }

    /// Review on a row of the progress card: the first language, page or
    /// device with suggestions.
    private func review(_ page: SuggestionPage) {
        if let information = page.appInformationPage {
            navigator.open(.appInformation, intent: .reviewPageSuggestions(information))
        } else {
            navigator.open(.storePage, intent: .reviewFieldSuggestions(.storePage))
        }
    }

    /// Accept All (n): every unreviewed suggestion from the run; the toast
    /// offers Undo.
    private func acceptAll(_ run: SuggestionRun) {
        guard let workspace = assistants.workspace else { return }
        let batch = suggestions.toReview(in: run)
        Task {
            let accepted = await SuggestionRunAcceptance.accept(batch, appID: run.appID, in: workspace, store: suggestions)
            guard accepted.count > 0 else { return }
            if let current = suggestions.run, current.id == run.id, suggestions.toReview(in: current).isEmpty {
                suggestions.dismissRun()
            }
            navigator.toast = .accepted(accepted.count, undo: accepted.undo)
        }
    }

    private static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
