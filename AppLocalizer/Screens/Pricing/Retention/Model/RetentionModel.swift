//
//  RetentionModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Pricing → Retention for one app: the messages (App Store Connect's,
/// with what waits in Review & Push and unqueued edits on top), the
/// retention offers, the selected message and language, the preview's
/// appearance and the sheets. Editing lives in `+Editing`, Review & Push in
/// `+Queue`, Translate All in `+Translation`.
@MainActor
@Observable
final class RetentionModel {
    let app: StoreApp
    @ObservationIgnored let services: any RetentionServices
    @ObservationIgnored let queue: ChangeQueue
    @ObservationIgnored let store: RetentionDraftStore

    private(set) var loadState: LoadState<RetentionContent> = .idle
    /// App Store Connect's, as last read.
    private(set) var content = RetentionContent.empty
    /// What the page shows, in order: App Store Connect's, then new ones.
    var messages: [RetentionMessage] = []
    /// App Store Connect's offers, then the ones waiting in Review & Push.
    private(set) var offers: [RetentionOffer] = []

    var selectedMessageID: String?
    var selectedLocale = StoreLocale.englishUS.code
    var showsAllLanguages = false
    var isAdvancedExpanded = false
    var isDarkPreview = false
    var isOfferSheetPresented = false
    var isImageSheetPresented = false
    /// Messages whose source words changed since Translate All: it redoes
    /// their translated languages.
    var sourceEdited: Set<String> = []
    /// The language Translate All is on, while it runs.
    var translatingLocale: String?
    /// A line under the editor after Translate All or a refusal.
    var notice: String?
    /// The day the preview says the service ends: a month from now.
    var previewEndDate = Calendar(identifier: .gregorian).date(byAdding: .month, value: 1, to: .now) ?? .now

    var libraryState: LoadState<[RetentionImage]> = .idle
    /// The image sheet's choice, before Use This Image.
    var pickedImageID: String?

    /// Opens Review & Push.
    @ObservationIgnored var onOpenReview: () -> Void = {}

    init(app: StoreApp, services: any RetentionServices, queue: ChangeQueue, store: RetentionDraftStore = .shared) {
        self.app = app
        self.services = services
        self.queue = queue
        self.store = store
    }

    // MARK: - Loading

    /// Reads App Store Connect; with `force` false, only when nothing (or
    /// other subscriptions) was read before.
    func load(subscriptions: [RetentionSubscription], force: Bool = true) async {
        if !force, loadState.value != nil, content.subscriptions.map(\.id) == subscriptions.map(\.id) {
            refresh()
            return
        }
        if loadState.value == nil { loadState = .loading }
        do {
            let loaded = try await services.content(for: app, subscriptions: subscriptions)
            content = loaded
            loadState = .loaded(loaded)
            if !loaded.languages.contains(where: { $0.code == selectedLocale }) { selectedLocale = loaded.sourceLocale.code }
            refresh()
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    /// Messages and offers again from what's loaded, queued and kept:
    /// after a load, and whenever Review & Push changes.
    func refresh() {
        let working = RetentionWorkingSet(appID: app.id, content: content, queue: queue, store: store)
        offers = working.offers
        messages = working.messages.map(withLibraryImage)
        if selectedMessageID.map({ id in !messages.contains { $0.id == id } }) ?? true {
            selectedMessageID = messages.first?.id
        }
    }

    /// A queued image's thumbnail, from the library when it's there.
    private func withLibraryImage(_ message: RetentionMessage) -> RetentionMessage {
        guard message.image?.thumbnailTemplate == nil, let assetID = message.image?.assetID,
              let library = libraryState.value?.first(where: { $0.assetID == assetID })
        else { return message }
        var message = message
        message.image = library
        return message
    }

    // MARK: - Reading

    var selectedMessage: RetentionMessage? {
        messages.first { $0.id == selectedMessageID }
    }

    var subscriptions: [RetentionSubscription] { content.subscriptions }
    var languages: [StoreLocale] { content.languages }
    var sourceLocale: StoreLocale { content.sourceLocale }

    var hasMessages: Bool { !messages.isEmpty }
    var canAddMessage: Bool { messages.count < RetentionLimits.messagesPerApp }

    /// What builds the message's change: the content with the page's
    /// messages and offers (queued ones included).
    var builder: RetentionChangeBuilder {
        var current = content
        current.messages = messages
        current.offers = offers
        return RetentionChangeBuilder(app: app, content: current)
    }

    func isQueued(_ message: RetentionMessage) -> Bool {
        queue.change(id: RetentionChangeBuilder.messageChangeID(appID: app.id, messageID: message.id)) != nil
    }

    /// The pill: In Review & Push while queued, else App Store Connect's
    /// state, Draft for a new one.
    func status(of message: RetentionMessage) -> RetentionMessageStatus {
        if isQueued(message) { return .queued }
        return message.remote?.status ?? .draft
    }

    func status(of offer: RetentionOffer) -> RetentionMessageStatus? {
        offer.isQueued ? .queued : nil
    }

    /// "Lumen Plus Monthly and Annual · 18 languages", or "… · not written yet".
    func listDetail(of message: RetentionMessage) -> String {
        let subscriptions = RetentionSubscription.summary(of: message.subscriptionIDs.compactMap(content.subscription(id:)))
        let count = builder.languages(of: message).count { message.text(for: $0.code).isComplete }
        let written = switch count {
        case 0: String(localized: "not written yet")
        case 1: String(localized: "1 language")
        default: String(localized: "\(count) languages")
        }
        return "\(subscriptions) · \(written)"
    }

    /// "Half price for 3 months (Monthly) · One month free (Annual)".
    func offersSummary(for message: RetentionMessage) -> String {
        let names = message.subscriptionIDs.flatMap { id in
            offers.filter { $0.subscriptionID == id }.map { offer in
                "\(offer.referenceName) (\(content.subscription(id: id)?.shortName ?? id))"
            }
        }
        return names.joined(separator: " · ")
    }

    func detail(of offer: RetentionOffer) -> String {
        let subscription = content.subscription(id: offer.subscriptionID)
        let terms = offer.terms(basePrice: subscription?.basePrice, period: subscription?.period)
        return [subscription?.name, terms].compactMap(\.self).joined(separator: " · ")
    }
}
