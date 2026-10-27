//
//  ReviewAppGroup.swift
//  AppLocalizer
//

import Foundation

/// One app's changes in the review sheet, under the app's name.
struct ReviewAppGroup: Identifiable, Hashable, Sendable {
    var id: StoreApp.ID
    var appName: String
    var groups: [ReviewChangeGroup]
}
