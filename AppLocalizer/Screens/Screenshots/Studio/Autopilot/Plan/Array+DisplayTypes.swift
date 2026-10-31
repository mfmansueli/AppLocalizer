//
//  Array+DisplayTypes.swift
//  AppLocalizer
//

import Foundation

extension [ScreenshotDisplayType] {
    /// The plan's iPad switch: iPhone always, iPad 13″ when on.
    var hasIPad: Bool {
        get { contains(.iPad) }
        set {
            removeAll { $0 == .iPad }
            if !contains(.iPhone) { insert(.iPhone, at: 0) }
            if newValue { append(.iPad) }
        }
    }
}
