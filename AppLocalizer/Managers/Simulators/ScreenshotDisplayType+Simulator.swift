//
//  ScreenshotDisplayType+Simulator.swift
//  AppLocalizer
//

import Foundation

/// The simulators a device's captures can come from; Mac's come from this
/// Mac itself.
extension ScreenshotDisplayType {
    /// Device types whose screens are the set's size, preferred first.
    var simulatorDeviceTypes: [String] {
        switch self {
        case .iPhone: ["iPhone 17 Pro Max", "iPhone 16 Pro Max"]
        case .iPhoneDuo: ["iPhone Duo"]
        case .iPad: ["iPad Pro 13-inch (M5)", "iPad Pro 13-inch (M5) (16GB)", "iPad Pro 13-inch (M4)", "iPad Pro 13-inch (M4) (16GB)"]
        case .watch: ["Apple Watch Ultra 3 (49mm)", "Apple Watch Ultra 2 (49mm)"]
        case .visionPro: ["Apple Vision Pro"]
        case .mac: []
        case .appleTV: [deviceName]
        }
    }

    /// The platform `xcodebuild -downloadPlatform` takes for it.
    var simulatorPlatform: String {
        switch self {
        case .iPhone, .iPhoneDuo, .iPad: "iOS"
        case .watch: "watchOS"
        case .visionPro: "visionOS"
        case .appleTV: "tvOS"
        case .mac: "macOS"
        }
    }

    /// The platform names `simctl` gives its runtimes.
    var simulatorRuntimePlatforms: Set<String> {
        self == .visionPro ? ["xrOS", "visionOS"] : [simulatorPlatform]
    }

    /// Its simulator starts closed, with apps on its cover display, and
    /// only the person can open it, in Device Hub (`DeviceHub`): iPhone Duo.
    var simulatorStartsClosed: Bool { self == .iPhoneDuo }
}
