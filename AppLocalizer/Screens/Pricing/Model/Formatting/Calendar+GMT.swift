//
//  Calendar+GMT.swift
//  AppLocalizer
//

import Foundation

extension Calendar {
    /// Gregorian in GMT, so day counts don't shift with the Mac's time zone.
    static let gmtGregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
}
