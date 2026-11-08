//
//  RetentionChangeBuilder.swift
//  AppLocalizer
//

import Foundation

/// Turns a retention message or a new retention offer into one Review &
/// Push change, shown under "Retention" as what it creates, with every
/// language's header and message under it. A message's requests, in order:
///
/// 1. A new message: `POST /v1/retentionMessages`.
/// 2. Each subscription that doesn't show it yet: `PATCH
///    …/relationships/retentionMessage` (it replaces any other message).
/// 3. When the content changed: the image's placement first (a version
///    can't change once made), then the version, then each language. An
///    approved version can't take edits, so new words go into a new
///    version; one still being prepared is edited in place.
/// 4. The subscriptions' existing offers shown or hidden.
/// 5. App Review: a review submission without an app version, the version
///    as its item, then submitted.
///
/// A new offer is created with its prices (the U.S. price, equalized
/// everywhere else) and shown with the subscription's message.
struct RetentionChangeBuilder {
    let app: StoreApp
    let content: RetentionContent

    static let messagePrefix = "retention.message."
    static let offerPrefix = "retention.offer."

    /// `retention.message.<appID>.<messageID>`.
    static func messageChangeID(appID: StoreApp.ID, messageID: String) -> PendingChange.ID {
        "\(messagePrefix)\(appID).\(messageID)"
    }

    /// `retention.offer.<appID>.<subscriptionID>.<offerId>`.
    static func offerChangeID(appID: StoreApp.ID, subscriptionID: String, offerID: String) -> PendingChange.ID {
        "\(offerPrefix)\(appID).\(subscriptionID).\(offerID)"
    }

    static func owns(_ change: PendingChange) -> Bool {
        change.id.hasPrefix(messagePrefix) || change.id.hasPrefix(offerPrefix)
    }

    /// The message a queued message change is for.
    static func messageID(of change: PendingChange) -> String? {
        let prefix = "\(messagePrefix)\(change.appID)."
        guard change.id.hasPrefix(prefix) else { return nil }
        return String(change.id.dropFirst(prefix.count))
    }

    static var group: String { String(localized: "Retention") }

    // MARK: - Problems

    /// What keeps `message` from being pushed; `messageCount` is how many
    /// the app would have with it.
    func problems(for message: RetentionMessage, messageCount: Int) -> [RetentionMessageProblem] {
        var problems = nameProblems(of: message)
        if message.isNew, messageCount > RetentionLimits.messagesPerApp { problems.append(.tooManyMessages) }
        if message.subscriptionIDs.isEmpty { problems.append(.noSubscriptions) }
        problems += textProblems(of: message)
        if let problem = kindProblem(of: message) { problems.append(problem) }
        if contentChanged(message), message.remote?.versionState?.isWithApple == true { problems.append(.withApple) }
        return problems
    }

    /// No name, a long one, or a new message named like one the app has
    /// (names can't change, and a retried push finds its message by it).
    private func nameProblems(of message: RetentionMessage) -> [RetentionMessageProblem] {
        let name = RetentionText.trimmed(message.referenceName)
        if name.isEmpty { return [.noName] }
        if RetentionLimits.length(of: name) > RetentionLimits.referenceNameLength { return [.nameTooLong] }
        let taken = content.messages.contains { $0.id != message.id && RetentionText.trimmed($0.referenceName) == name }
        return taken ? [.nameTaken] : []
    }

    private func textProblems(of message: RetentionMessage) -> [RetentionMessageProblem] {
        var problems: [RetentionMessageProblem] = []
        if !message.text(for: content.sourceLocale.code).isComplete {
            problems.append(.noSourceText(language: content.sourceLocale.name))
        }
        let languages = languages(of: message)
        let incomplete = languages.filter { !message.text(for: $0.code).isEmpty && !message.text(for: $0.code).isComplete }
        if !incomplete.isEmpty { problems.append(.incomplete(languages: incomplete.map(\.name))) }
        let tooLong = languages.filter { message.text(for: $0.code).isTooLong }
        if !tooLong.isEmpty { problems.append(.tooLong(languages: tooLong.map(\.name))) }
        return problems
    }

    /// A missing or unfit image, or no offer to show.
    private func kindProblem(of message: RetentionMessage) -> RetentionMessageProblem? {
        switch message.kind {
        case .message:
            return nil
        case .image:
            guard let image = message.image else { return .noImage }
            return image.problems.first.map { .imageDoesNotFit($0.message) }
        case .offer:
            return message.subscriptionIDs.allSatisfy { content.offers(for: $0).isEmpty } ? .noOffers : nil
        }
    }

    /// Every language the message is written in, in the editor's order,
    /// then any others it has.
    func languages(of message: RetentionMessage) -> [StoreLocale] {
        let known = Set(content.languages.map(\.code))
        let others = message.texts.keys.filter { !known.contains($0) }.sorted().compactMap(StoreLocaleCatalog.locale(code:))
        return content.languages + others
    }

    // MARK: - Message change

    func change(
        for message: RetentionMessage,
        source: ChangeSource = .you,
        messageCount: Int,
        evidence: [String] = [],
        at date: Date = .now
    ) -> PendingChange {
        let id = Self.messageChangeID(appID: app.id, messageID: message.id)
        let summary = summary(of: message)
        var change = PendingChange(
            id: id,
            appID: app.id,
            section: .subscriptionPricing,
            group: Self.group,
            title: String(localized: "Retention message · \(RetentionText.trimmed(message.referenceName))"),
            oldValue: "",
            newValue: summary,
            source: source,
            blockedReason: problems(for: message, messageCount: messageCount).first?.message,
            requests: requests(for: message),
            createdAt: date
        )
        change.creation = PendingCreation(
            id: id,
            title: change.title,
            detail: String(localized: "\(summary). Test it by canceling a sandbox subscription once Apple approves it."),
            source: source,
            fields: fields(of: message, source: source) + evidenceField(evidence, source: source)
        )
        return change
    }

    private func evidenceField(_ evidence: [String], source: ChangeSource) -> [PendingChangePart] {
        guard !evidence.isEmpty else { return [] }
        let found = evidence.joined(separator: "\n")
        return [PendingChangePart(id: "evidence", title: String(localized: "Found in"), oldValue: "", newValue: found, source: source)]
    }

    /// Whether the push writes new words or a new image, which App Review
    /// checks again.
    func contentChanged(_ message: RetentionMessage) -> Bool {
        guard let remote = message.remote, remote.versionID != nil else { return true }
        if imageChanged(message) { return true }
        let locales = Set(message.texts.keys).union(remote.localizations.keys)
        return locales.contains { !message.text(for: $0).hasSameWords(as: remote.localizations[$0]?.text) }
    }

    private func imageChanged(_ message: RetentionMessage) -> Bool {
        let wanted = message.kind == .image ? message.image.map { $0.assetID ?? $0.localPath ?? $0.name } : nil
        return wanted != message.remote?.imageID
    }

    /// Whether the content goes into a new version.
    private func needsNewVersion(_ message: RetentionMessage) -> Bool {
        guard let remote = message.remote, remote.versionID != nil, let state = remote.versionState else { return true }
        return !state.takesEdits || imageChanged(message)
    }

    func requests(for message: RetentionMessage) -> [PushRequest] {
        let messageID = message.remote?.messageID ?? PushRequest.createdIDPlaceholder(type: "retentionMessages")
        var requests: [PushRequest] = []
        if message.isNew {
            requests.append(RetentionRequests.createMessage(appID: app.id, referenceName: RetentionText.trimmed(message.referenceName)))
        }
        let assigned = Set(message.remote?.subscriptionIDs ?? [])
        for subscriptionID in message.subscriptionIDs where !assigned.contains(subscriptionID) {
            requests.append(RetentionRequests.assign(subscriptionID: subscriptionID, messageID: messageID))
        }
        var versionID: String?
        if contentChanged(message) {
            versionID = needsNewVersion(message) ? appendNewVersion(of: message, messageID: messageID, to: &requests) : appendEdits(of: message, to: &requests)
        }
        appendOffers(of: message, to: &requests)
        if let versionID {
            let submission = PushRequest.createdIDPlaceholder(type: "reviewSubmissions")
            requests += [
                RetentionRequests.createReviewSubmission(appID: app.id),
                RetentionRequests.addReviewItem(submissionID: submission, versionID: versionID),
                RetentionRequests.submit(submissionID: submission),
            ]
        }
        return requests
    }

    /// The placement, the version and every language; returns the
    /// version's ID placeholder.
    private func appendNewVersion(of message: RetentionMessage, messageID: String, to requests: inout [PushRequest]) -> String {
        var placementID: String?
        if message.kind == .image, let image = message.image {
            let imageID = image.assetID ?? image.localPath.map { RetentionPushSteps.uploadPlaceholder(path: $0, appID: app.id) } ?? ""
            requests.append(RetentionRequests.placeImage(imageID: imageID, pixelWidth: image.pixelWidth, pixelHeight: image.pixelHeight))
            placementID = PushRequest.createdIDPlaceholder(type: "appAssetLibraryPlacements")
        }
        requests.append(RetentionRequests.createVersion(messageID: messageID, placementID: placementID))
        let versionID = PushRequest.createdIDPlaceholder(type: "retentionMessageVersions")
        for locale in languages(of: message) where message.text(for: locale.code).isComplete {
            requests.append(RetentionRequests.createLocalization(versionID: versionID, locale: locale.code, text: message.text(for: locale.code)))
        }
        return versionID
    }

    /// Each language's words into the version that takes edits; returns its ID.
    private func appendEdits(of message: RetentionMessage, to requests: inout [PushRequest]) -> String? {
        guard let remote = message.remote, let versionID = remote.versionID else { return nil }
        var locales = languages(of: message).map(\.code)
        locales += remote.localizations.keys.sorted().filter { !locales.contains($0) }
        for locale in locales {
            let text = message.text(for: locale)
            let existing = remote.localizations[locale]
            if text.isComplete {
                if let existing {
                    if !text.hasSameWords(as: existing.text) {
                        requests.append(RetentionRequests.updateLocalization(id: existing.id, text: text))
                    }
                } else {
                    requests.append(RetentionRequests.createLocalization(versionID: versionID, locale: locale, text: text))
                }
            } else if text.isEmpty, let existing {
                requests.append(RetentionRequests.deleteLocalization(id: existing.id))
            }
        }
        return versionID
    }

    /// Shows the subscriptions' existing offers with a "With offer"
    /// message, and hides them otherwise. New offers show themselves.
    private func appendOffers(of message: RetentionMessage, to requests: inout [PushRequest]) {
        for subscriptionID in message.subscriptionIDs {
            let existing = content.offers(for: subscriptionID).filter { !$0.isQueued }
            if message.kind == .offer {
                let hidden = existing.filter { !$0.isShown }.map(\.id)
                if !hidden.isEmpty { requests.append(RetentionRequests.showOffers(subscriptionID: subscriptionID, offerIDs: hidden)) }
            } else {
                let shown = existing.filter(\.isShown).map(\.id)
                if !shown.isEmpty { requests.append(RetentionRequests.hideOffers(subscriptionID: subscriptionID, offerIDs: shown)) }
            }
        }
    }

    // MARK: - Review & Push

    /// "Message and image · 18 languages · goes to App Review".
    func summary(of message: RetentionMessage) -> String {
        let count = languages(of: message).count { message.text(for: $0.code).isComplete }
        let languages = count == 1 ? String(localized: "1 language") : String(localized: "\(count) languages")
        var parts = [message.kind.summary, languages]
        if contentChanged(message) { parts.append(String(localized: "goes to App Review")) }
        return parts.joined(separator: " · ")
    }

    private func fields(of message: RetentionMessage, source: ChangeSource) -> [PendingChangePart] {
        let names = message.subscriptionIDs.compactMap(content.subscription(id:))
        var fields = [
            PendingChangePart(id: "name", title: String(localized: "Name"), oldValue: message.remote?.referenceName ?? "",
                              newValue: RetentionText.trimmed(message.referenceName), source: source),
            PendingChangePart(id: "subscriptions", title: String(localized: "Subscriptions"), oldValue: "",
                              newValue: names.map(\.name).formatted(.list(type: .and)), source: source),
            PendingChangePart(id: "shows", title: String(localized: "Shows"), oldValue: "", newValue: message.kind.summary, source: source),
        ]
        if message.kind == .image, let image = message.image {
            let from = image.assetID == nil ? String(localized: "uploaded to the Asset Library when you push") : String(localized: "from the Asset Library")
            fields.append(PendingChangePart(id: "image", title: String(localized: "Image"), oldValue: "",
                                            newValue: "\(image.name) · \(image.sizeText) · \(from)", source: source))
        }
        if message.kind == .offer {
            let offers = message.subscriptionIDs.flatMap { content.offers(for: $0) }.map(\.referenceName)
            fields.append(PendingChangePart(id: "offers", title: String(localized: "Offers"), oldValue: "",
                                            newValue: offers.formatted(.list(type: .and)), source: source))
        }
        for locale in languages(of: message) {
            let text = message.text(for: locale.code)
            let old = message.remote?.localizations[locale.code]
            guard !text.isEmpty || old != nil else { continue }
            let partSource = Self.source(of: text.origin, base: source)
            fields.append(PendingChangePart(id: "header.\(locale.code)", title: String(localized: "\(locale.name) · Header"),
                                            oldValue: old?.header ?? "", newValue: text.header, source: partSource))
            fields.append(PendingChangePart(id: "body.\(locale.code)", title: String(localized: "\(locale.name) · Message"),
                                            oldValue: old?.body ?? "", newValue: text.body, source: partSource))
        }
        return fields
    }

    /// Who wrote a language, for its rows in Review & Push.
    static func source(of origin: RetentionTextOrigin, base: ChangeSource) -> ChangeSource {
        switch origin {
        case .written: base
        case .translated: .machineTranslation
        case let .assistant(client): .assistant(client: client)
        }
    }

    // MARK: - Offer change

    func offerChange(for offer: RetentionOffer, source: ChangeSource = .you, evidence: [String] = [], at date: Date = .now) -> PendingChange {
        let id = Self.offerChangeID(appID: app.id, subscriptionID: offer.subscriptionID, offerID: offer.offerID)
        let subscription = content.subscription(id: offer.subscriptionID)
        let terms = offer.terms(basePrice: subscription?.basePrice, period: subscription?.period)
        let title = String(localized: "Retention offer · \(offer.referenceName)")
        var change = PendingChange(
            id: id,
            appID: app.id,
            section: .subscriptionPricing,
            group: Self.group,
            title: title,
            oldValue: "",
            newValue: [subscription?.name, terms].compactMap(\.self).joined(separator: " · "),
            source: source,
            requests: [
                RetentionRequests.createOffer(offer),
                RetentionRequests.showOffers(subscriptionID: offer.subscriptionID, offerIDs: [PushRequest.createdIDPlaceholder(type: "retentionOffers")]),
            ],
            createdAt: date
        )
        var fields = [
            ("subscription", String(localized: "Subscription"), subscription?.name ?? offer.subscriptionID),
            ("type", String(localized: "Type"), offer.mode.title),
            ("duration", String(localized: "Duration"), offer.term.totalMonths.map(RetentionOfferDuration.monthsTitle) ?? offer.duration.title),
            ("offerId", String(localized: "Offer ID"), offer.offerID),
            ("eligibility", String(localized: "Eligible after"), String(localized: "\(RetentionOfferDuration.monthsTitle(offer.paidMonths)) paid")),
        ]
        if let price = offer.usPrice {
            fields.insert(("price", String(localized: "Price"), String(localized: "\(CurrencyFormat.usd.format(price)) in the United States · equalized everywhere else")), at: 3)
        }
        if !evidence.isEmpty { fields.append(("evidence", String(localized: "Found in"), evidence.joined(separator: "\n"))) }
        change.creation = PendingCreation(
            id: id,
            title: title,
            detail: String(localized: "A retention offer (offer type 5). Apple decides who’s eligible and shows the best offer with the message."),
            source: source,
            fields: fields.map { PendingChangePart(id: $0.0, title: $0.1, oldValue: "", newValue: $0.2, source: source) }
        )
        return change
    }
}
