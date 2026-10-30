//
//  WorkspaceIntent.swift
//  AppLocalizer
//

import Foundation

/// Something another part of the window asks a section to do when it opens:
/// an overview quick action, a menu command, the review sheet's "Edit…".
/// The section handles it and calls `WorkspaceNavigator.consume(_:)`.
enum WorkspaceIntent: Hashable, Sendable {
    /// Pricing: show suggestions (switching out of Keep my prices if needed).
    case reviewSuggestions
    /// Pricing: "Apply Recommended Prices…".
    case applyRecommendedPrices
    /// Pricing: the Results tab.
    case showResults
    /// Pricing: the schedule sheet for one subscription's pending prices.
    case editPriceSchedule(productID: String?)
    /// Pricing: the Prices tab as a table, tile map or histogram.
    case showPrices(PricingDisplay)
    /// App Information: one page, and App Privacy's tab, e.g. the overview's
    /// "Open Privacy URLs".
    case openAppInformationPage(AppInformationPage, privacyTab: AppPrivacyTab? = nil)
    /// Store Page: the "Translate Missing…" sheet.
    case translateMissing
    /// Store Page: Find and Replace Across Locales.
    case findAndReplace
    /// Store Page: Import Translations.
    case importTranslations
    /// Store Page: Screenshots, for Review & Push's Show in Captions (the
    /// Screenshots view then opens Captions on the render).
    case showScreenshots
    /// Store Page or App Information: the fields with suggestions, from the
    /// overview's Suggestions card or the Assistant button.
    case reviewFieldSuggestions(SuggestionArea)
    /// Store Page or App Information: "Ask Claude Code…", from the Assistant
    /// button's Ask for Suggestions….
    case askForSuggestions(SuggestionArea)
    /// Any section: focus its search field.
    case search
}
