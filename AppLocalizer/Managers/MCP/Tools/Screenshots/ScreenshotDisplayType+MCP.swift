//
//  ScreenshotDisplayType+MCP.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotDisplayType {
    /// "iphone", "iphone_duo", "ipad", "watch" or "vision", as the
    /// screenshot tools name the display types; App Store Connect's own
    /// value also works.
    var mcpValue: String {
        switch self {
        case .iPhone: "iphone"
        case .iPhoneDuo: "iphone_duo"
        case .iPad: "ipad"
        case .watch: "watch"
        case .visionPro: "vision"
        default: rawValue
        }
    }

    init?(mcpValue: String) {
        switch mcpValue.lowercased() {
        case "iphone", "iphone_69", "app_iphone_67": self = .iPhone
        case "iphone_duo", "iphoneduo", "duo", "app_iphone_duo": self = .iPhoneDuo
        case "ipad", "ipad_13", "app_ipad_pro_3gen_129": self = .iPad
        case "watch", "applewatch", "apple_watch", "watchos", "app_watch_ultra": self = .watch
        case "vision", "visionpro", "vision_pro", "apple_vision_pro", "visionos", "app_apple_vision_pro": self = .visionPro
        default: return nil
        }
    }

    var mcpJSON: JSONValue {
        let size = portraitPixelSize
        var json: [String: JSONValue] = [
            "displayType": .string(mcpValue),
            "title": .string(title),
            "portraitPixelSize": ["width": .int(size.width), "height": .int(size.height)],
        ]
        if self == .iPhoneDuo { json["display"] = "inner (unfolded)" }
        if let upcomingRequirement { json["requirement"] = .string(upcomingRequirement) }
        return .object(json)
    }
}
