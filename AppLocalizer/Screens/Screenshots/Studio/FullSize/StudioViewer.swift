//
//  StudioViewer.swift
//  AppLocalizer
//

import Foundation

/// The studio's full-size viewer over the app: the items it moves through
/// (a screenshot's neighbours, the header and search artwork, a
/// direction's set) and the one shown.
typealias StudioViewer = FullSizeViewerList<StudioViewerItem>
