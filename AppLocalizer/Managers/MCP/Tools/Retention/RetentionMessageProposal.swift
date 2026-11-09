//
//  RetentionMessageProposal.swift
//  AppLocalizer
//

import Foundation

/// `propose_retention_message`'s arguments applied to the message they
/// name (or a new one): its name, subscriptions, kind, words by locale and
/// image. What App Store Connect would refuse is collected in `refusals`.
@MainActor
struct RetentionMessageProposal {
    var message: RetentionMessage
    /// The locales the proposal wrote, in order.
    var locales: [String] = []
    var refusals: [String] = []
    /// Subscriptions that showed another message, which this one replaces.
    var replaces: [String] = []

    var isNew: Bool { message.isNew }

    static func make(
        from arguments: MCPToolArguments,
        in context: RetentionMCPContext,
        client: String,
        imageDirectory: URL = RetentionImageFiles.directory
    ) throws -> RetentionMessageProposal {
        var proposal = try RetentionMessageProposal(message: base(from: arguments, in: context))
        try proposal.applyName(arguments)
        try proposal.applySubscriptions(arguments, in: context)
        if let kindText = try arguments.optionalString("kind") {
            guard let kind = RetentionMessageKind(rawValue: kindText.lowercased()) else {
                throw MCPToolError.invalidArgument(name: "kind", expected: String(localized: "message, image or offer"))
            }
            proposal.message.kind = kind
        }
        try proposal.applyTexts(arguments, origin: .assistant(client: client))
        try proposal.applyImage(arguments, appID: context.app.id, directory: imageDirectory)
        return proposal
    }

    /// The message `messageId` names, else a new one.
    private static func base(from arguments: MCPToolArguments, in context: RetentionMCPContext) throws -> RetentionMessage {
        if let identifier = try arguments.optionalString("messageId"), !identifier.isEmpty {
            guard let message = context.message(matching: identifier) else {
                let names = context.messages.map { "\($0.referenceName) (\($0.id))" }
                let known = names.isEmpty ? String(localized: "It has none yet.") : String(localized: "Its messages are \(names.formatted(.list(type: .or))).")
                throw MCPToolError.notFound(String(localized: "\(context.app.name) has no retention message “\(identifier)”. \(known) Leave messageId out to make a new one."))
            }
            return message
        }
        return RetentionMessage(id: RetentionMessage.draftID(notIn: context.messages), referenceName: "")
    }

    // MARK: - Fields

    private mutating func applyName(_ arguments: MCPToolArguments) throws {
        guard let name = try arguments.optionalString("referenceName").map(RetentionText.trimmed), !name.isEmpty else {
            if RetentionText.trimmed(message.referenceName).isEmpty { refusals.append(RetentionMessageProblem.noName.message) }
            return
        }
        if isNew {
            message.referenceName = name
        } else if name != RetentionText.trimmed(message.referenceName) {
            refusals.append(String(localized: "App Store Connect can’t rename a retention message; leave referenceName out for “\(message.referenceName)”."))
        }
    }

    /// A new message shows on the subscriptions named; an existing one adds
    /// them (App Store Connect can't take a message off a subscription,
    /// only give it another).
    private mutating func applySubscriptions(_ arguments: MCPToolArguments, in context: RetentionMCPContext) throws {
        guard let identifiers = try arguments.optionalStrings("subscriptions") else { return }
        let ids = try identifiers.map { try context.requireSubscription($0).id }
        var result = isNew ? [] : message.subscriptionIDs
        for id in ids where !result.contains(id) { result.append(id) }
        message.subscriptionIDs = result
        let messageID = message.id
        replaces = ids.filter { id in context.messages.contains { $0.id != messageID && $0.subscriptionIDs.contains(id) } }
    }

    /// `texts` and the single `locale`/`header`/`body`; a header or body
    /// left out keeps what's there.
    private mutating func applyTexts(_ arguments: MCPToolArguments, origin: RetentionTextOrigin) throws {
        var entries: [[String: JSONValue]] = try (arguments.optionalArray("texts") ?? []).map { value in
            guard case let .object(object) = value else {
                throw MCPToolError.invalidArgument(name: "texts", expected: String(localized: "objects with locale, header and body"))
            }
            return object
        }
        if let locale = try arguments.optionalString("locale") {
            var entry: [String: JSONValue] = ["locale": .string(locale)]
            entry["header"] = arguments.values["header"]
            entry["body"] = arguments.values["body"]
            entries.append(entry)
        }
        for entry in entries {
            try apply(entry, origin: origin)
        }
    }

    private mutating func apply(_ entry: [String: JSONValue], origin: RetentionTextOrigin) throws {
        guard let code = entry["locale"]?.stringValue, let locale = StoreLocaleCatalog.locale(code: code) else {
            throw MCPToolError.invalidArgument(name: "locale", expected: String(localized: "an App Store Connect locale code, e.g. de-DE"))
        }
        let header = entry["header"]?.stringValue
        let body = entry["body"]?.stringValue
        guard header != nil || body != nil else {
            throw MCPToolError.invalidArgument(name: "header", expected: String(localized: "a header or body for \(locale.code)"))
        }
        var text = message.text(for: locale.code)
        if let header { text.header = RetentionText.trimmed(header) }
        if let body { text.body = RetentionText.trimmed(body) }
        text.origin = origin
        message.texts[locale.code] = text
        if !locales.contains(locale.code) { locales.append(locale.code) }
        if text.isHeaderTooLong {
            refusals.append(String(localized: "\(locale.code): the header is \(text.headerCount) characters; Apple allows \(RetentionLimits.headerLength)."))
        }
        if text.isBodyTooLong {
            refusals.append(String(localized: "\(locale.code): the body is \(text.bodyCount) characters; Apple allows \(RetentionLimits.bodyLength)."))
        }
    }

    // MARK: - Image

    /// `imagePath` or `imageBase64`: a PNG kept in AppLocalizer's container
    /// until the push uploads it to the Asset Library.
    private mutating func applyImage(_ arguments: MCPToolArguments, appID: StoreApp.ID, directory: URL) throws {
        guard let data = try Self.imageData(arguments) else { return }
        let name = try arguments.optionalString("imageName").map(RetentionText.trimmed).flatMap { $0.isEmpty ? nil : $0 }
            ?? String(localized: "\(RetentionText.trimmed(message.referenceName)) image")
        let url: URL
        do {
            url = try RetentionImageFiles.save(data, name: name, appID: appID, in: directory)
        } catch {
            throw MCPToolError.unavailable(String(localized: "AppLocalizer couldn’t keep the image: \(error.localizedDescription)"))
        }
        guard let image = RetentionImageRule.image(at: url, name: name) else {
            try? FileManager.default.removeItem(at: url)
            refusals.append(RetentionImageProblem.unreadable.message)
            return
        }
        guard image.fits else {
            try? FileManager.default.removeItem(at: url)
            refusals += image.problems.map(\.message)
            return
        }
        message.image = image
        if (try? arguments.optionalString("kind")) == nil { message.kind = .image }
    }

    private static func imageData(_ arguments: MCPToolArguments) throws -> Data? {
        if let base64 = try arguments.optionalString("imageBase64"), !base64.isEmpty {
            let trimmed = base64.components(separatedBy: ",").last ?? base64
            guard let data = Data(base64Encoded: trimmed, options: .ignoreUnknownCharacters) else {
                throw MCPToolError.invalidArgument(name: "imageBase64", expected: String(localized: "a PNG in base64"))
            }
            return data
        }
        guard let path = try arguments.optionalString("imagePath"), !path.isEmpty else { return nil }
        guard let data = try? Data(contentsOf: URL(filePath: (path as NSString).expandingTildeInPath)) else {
            throw MCPToolError.unavailable(String(localized: "AppLocalizer can’t read \(path) (it’s sandboxed). Pass the PNG as imageBase64 instead."))
        }
        return data
    }
}
