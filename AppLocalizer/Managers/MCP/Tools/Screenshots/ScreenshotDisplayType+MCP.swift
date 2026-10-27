//
//  ScreenshotDisplayType+MCP.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotDisplayType {
    /// "iphone" or "ipad", as the screenshot tools name the rendered
    /// display types; App Store Connect's own value also works.
    var mcpValue: String {
        switch self {
        case .iPhone: "iphone"
        case .iPad: "ipad"
        default: rawValue
        }
    }

    init?(mcpValue: String) {
        switch mcpValue.lowercased() {
        case "iphone", "iphone_69", "app_iphone_67": self = .iPhone
        case "ipad", "ipad_13", "app_ipad_pro_3gen_129": self = .iPad
        default: return nil
        }
    }

    var mcpJSON: JSONValue {
        let size = portraitPixelSize
        return [
            "displayType": .string(mcpValue),
            "title": .string(title),
            "portraitPixelSize": ["width": .int(size.width), "height": .int(size.height)],
        ]
    }
}
