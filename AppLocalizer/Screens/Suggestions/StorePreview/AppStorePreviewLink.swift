//
//  AppStorePreviewLink.swift
//  AppLocalizer
//

import Foundation

/// A tag on the Overview's preview that opens the section editing that part
/// of the page, with how many suggestions wait there.
struct AppStorePreviewLink {
    var title: String
    var count: Int
    var open: () -> Void
}
