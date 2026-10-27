//
//  DeviceFamily.swift
//  AppLocalizer
//

import Foundation

/// A device family an Accessibility Nutrition Label is declared for
/// (`deviceFamily` in `accessibilityDeclarations`), in the cards' order.
enum DeviceFamily: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    case iPhone = "IPHONE"
    case iPad = "IPAD"
    case appleWatch = "APPLE_WATCH"
    case vision = "VISION"
    case mac = "MAC"
    case appleTV = "APPLE_TV"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .iPhone: String(localized: "iPhone")
        case .iPad: String(localized: "iPad")
        case .appleWatch: String(localized: "Apple Watch")
        case .vision: String(localized: "Apple Vision Pro")
        case .mac: String(localized: "Mac")
        case .appleTV: String(localized: "Apple TV")
        }
    }

    var systemImage: String {
        switch self {
        case .iPhone: "iphone"
        case .iPad: "ipad"
        case .appleWatch: "applewatch"
        case .vision: "visionpro"
        case .mac: "laptopcomputer"
        case .appleTV: "appletv"
        }
    }

    /// The families an App Store version of `platform` (`IOS`, `MAC_OS`,
    /// `TV_OS`, `VISION_OS`) reaches. App Store Connect doesn't say which
    /// devices an iOS app supports, so `IOS` stands for iPhone and iPad;
    /// Apple Watch shows once it has a declaration, or from Other Devices.
    static func families(forPlatform platform: String?) -> [DeviceFamily] {
        switch platform {
        case "IOS": [.iPhone, .iPad]
        case "MAC_OS": [.mac]
        case "TV_OS": [.appleTV]
        case "VISION_OS": [.vision]
        default: []
        }
    }

    /// The platform whose live version lets this family's label publish.
    var platform: String {
        switch self {
        case .iPhone, .iPad, .appleWatch: "IOS"
        case .mac: "MAC_OS"
        case .appleTV: "TV_OS"
        case .vision: "VISION_OS"
        }
    }

    /// The features Apple asks about on this family.
    var features: [AccessibilityFeature] {
        AccessibilityFeature.allCases.filter { $0.isAvailable(on: self) }
    }

    /// The features Apple doesn't ask about here, e.g. Voice Control on
    /// Apple Watch.
    var unavailableFeatures: [AccessibilityFeature] {
        AccessibilityFeature.allCases.filter { !$0.isAvailable(on: self) }
    }
}
