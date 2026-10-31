//
//  OverviewSectionView+Debug.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

@MainActor
extension OverviewSectionView {
    /// DEBUG scenes set it to click Suggest Everything… once Overview
    /// appears (design `ev-wait`, `ev-busy`).
    static var debugRequestsSuggestEverything = false
}
#endif
