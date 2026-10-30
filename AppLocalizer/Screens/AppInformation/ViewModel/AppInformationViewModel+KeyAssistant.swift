//
//  AppInformationViewModel+KeyAssistant.swift
//  AppLocalizer
//

import Foundation

// With an API key, App Information can't be generated: its answers come
// from what the app's code does. The page says how many.
extension AppInformationViewModel {
    /// How many answers in `scope` only an assistant that reads the code
    /// can suggest: the categories, App Review's notes, and the Age Rating
    /// questions and a device's features still unanswered. Those with a
    /// suggestion already don't count.
    func codeOnlyAnswerCount(in scope: SuggestionScope) -> Int {
        suggestionSlots(in: scope).count { slot in
            guard canSuggest(slot), shownSuggestion(slot, filter: .all) == nil else { return false }
            return switch slot {
            case let .field(field): [.primaryCategory, .secondaryCategory, .notes].contains(field)
            case .ageRating, .accessibility: suggestionValue(slot).isEmpty
            }
        }
    }
}
