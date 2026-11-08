//
//  RetentionTestFixtures.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import ImageIO
@testable import AppLocalizer

/// Lumen Journal's retention data for the unit tests: its two
/// subscriptions, "Before you go" as App Store Connect has it in a given
/// state, and content built from them.
@MainActor
enum RetentionTestFixtures {
    static let app = StoreApp(id: DebugFixtures.AppID.lumen, name: "Lumen Journal", bundleID: "com.northpier.lumen", primaryLocale: "en-US")

    static let monthly = RetentionSubscription(
        id: RetentionSampleData.monthlyID, name: "Lumen Plus Monthly", productID: "lumen.plus.monthly",
        period: .oneMonth, basePrice: Decimal(string: "4.99"), groupName: "Lumen Plus"
    )
    static let annual = RetentionSubscription(
        id: RetentionSampleData.annualID, name: "Lumen Plus Annual", productID: "lumen.plus.annual",
        period: .oneYear, basePrice: Decimal(string: "39.99"), groupName: "Lumen Plus"
    )

    static func content(messages: [RetentionMessage] = [], offers: [RetentionOffer] = []) -> RetentionContent {
        RetentionContent(
            subscriptions: [monthly, annual], messages: messages, offers: offers, languages: RetentionLanguages.standard, sourceLocale: .englishUS
        )
    }

    static func builder(messages: [RetentionMessage] = [], offers: [RetentionOffer] = []) -> RetentionChangeBuilder {
        RetentionChangeBuilder(app: app, content: content(messages: messages, offers: offers))
    }

    /// "Before you go", live, with its version in `state`.
    static func live(state: RetentionVersionState = .approved, imageID: String? = nil) -> RetentionMessage {
        var message = RetentionSampleData.liveMessage
        message.remote?.versionState = state
        message.remote?.imageID = imageID
        return message
    }

    /// A new message in English only.
    static func englishDraft(id: String = "draft-1", name: String = "Before you go") -> RetentionMessage {
        let english = RetentionSampleData.message["en-US"]!
        return RetentionMessage(
            id: id, referenceName: name, subscriptionIDs: [monthly.id],
            texts: ["en-US": RetentionText(header: english.0, body: english.1)]
        )
    }

    /// Request bodies as JSON objects.
    static func object(_ request: PushRequest) -> [String: Any] {
        RetentionRequests.object(of: request) ?? [:]
    }

    static func data(_ request: PushRequest) -> [String: Any] {
        object(request)["data"] as? [String: Any] ?? [:]
    }

    static func attributes(_ request: PushRequest) -> [String: Any] {
        data(request)["attributes"] as? [String: Any] ?? [:]
    }

    /// An opaque (or transparent) PNG of the size, written to a temporary
    /// file.
    static func png(width: Int, height: Int, alpha: Bool = false) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "retention-\(UUID().uuidString).png")
        try pngData(width: width, height: height, alpha: alpha).write(to: url)
        return url
    }

    static func pngData(width: Int, height: Int, alpha: Bool = false) throws -> Data {
        let info = alpha ? CGImageAlphaInfo.premultipliedLast.rawValue : CGImageAlphaInfo.noneSkipLast.rawValue
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: info
        ) else { throw CocoaError(.fileWriteUnknown) }
        context.setFillColor(CGColor(red: 0.1, green: 0.2, blue: 0.4, alpha: alpha ? 0.5 : 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else { throw CocoaError(.fileWriteUnknown) }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else { throw CocoaError(.fileWriteUnknown) }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
        return data as Data
    }
}
#endif
