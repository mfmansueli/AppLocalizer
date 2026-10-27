//
//  Commission+Preference.swift
//  AppLocalizer
//

import Foundation

extension Commission {
    /// Settings → Pricing's commission (0.15 or 0.30) as a `Commission`.
    init(preferenceRate rate: Double) {
        self = rate >= 0.3 ? .standard : .smallBusiness
    }
}
