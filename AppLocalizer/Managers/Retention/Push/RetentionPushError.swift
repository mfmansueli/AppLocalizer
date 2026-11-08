//
//  RetentionPushError.swift
//  AppLocalizer
//

import Foundation

/// Why a retention step of a push failed, in words for its row in Review &
/// Push.
enum RetentionPushError: LocalizedError, Hashable {
    /// Apple's reference data has no retention placement group for the size.
    case noPlacementGroup(width: Int, height: Int)
    /// The subscription has no price point at the offer's price.
    case noPricePoint(price: Decimal, nearest: [Decimal])
    /// This connection can't upload to the Asset Library.
    case cannotUpload
    case imageMissing(fileName: String)
    case imageRefused(state: String, details: String?)
    case imageTimedOut
    /// App Store Connect refused a new review submission, usually because
    /// one is already being prepared for the app.
    case submissionRefused(detail: String?)

    var errorDescription: String? {
        switch self {
        case let .noPlacementGroup(width, height):
            String(localized: "Apple takes no retention image of \(width) × \(height). Choose one 3840 wide and 160 to 2160 tall.")
        case let .noPricePoint(price, nearest):
            Self.noPricePointText(price: price, nearest: nearest)
        case .cannotUpload:
            String(localized: "The image can’t be uploaded to the Asset Library from here.")
        case let .imageMissing(fileName):
            String(localized: "\(fileName) isn’t on this Mac anymore. Choose the image again.")
        case let .imageRefused(state, details):
            String(localized: "Apple refused the image (\(details ?? state)).")
        case .imageTimedOut:
            String(localized: "Apple is still processing the image. Push again in a few minutes.")
        case let .submissionRefused(detail):
            String(localized: """
            App Store Connect didn’t open a review submission\(detail.map { ": \($0)" } ?? ""). If one is being prepared for \
            the app, submit or cancel it in App Store Connect, then push again.
            """)
        }
    }

    private static func noPricePointText(price: Decimal, nearest: [Decimal]) -> String {
        let amount = CurrencyFormat.usd.format(price)
        guard !nearest.isEmpty else { return String(localized: "Apple has no price of \(amount) for this subscription.") }
        let others = nearest.map { CurrencyFormat.usd.format($0) }.formatted(.list(type: .or))
        return String(localized: "Apple has no price of \(amount) for this subscription; the nearest are \(others).")
    }
}
