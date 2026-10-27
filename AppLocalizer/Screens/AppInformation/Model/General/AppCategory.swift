//
//  AppCategory.swift
//  AppLocalizer
//

import Foundation

/// An App Store category as App Store Connect names it (`LIFESTYLE`,
/// `GAMES_PUZZLE`), with the name people see. The API returns IDs only, so
/// the names live here; an ID this list doesn't know shows as itself.
struct AppCategory: Identifiable, Hashable, Sendable {
    let id: String
    let name: String

    static let gamesID = "GAMES"

    /// The categories a primary or secondary category can be, by name.
    static let all: [AppCategory] = [
        AppCategory(id: "BOOKS", name: String(localized: "Books")),
        AppCategory(id: "BUSINESS", name: String(localized: "Business")),
        AppCategory(id: "DEVELOPER_TOOLS", name: String(localized: "Developer Tools")),
        AppCategory(id: "EDUCATION", name: String(localized: "Education")),
        AppCategory(id: "ENTERTAINMENT", name: String(localized: "Entertainment")),
        AppCategory(id: "FINANCE", name: String(localized: "Finance")),
        AppCategory(id: "FOOD_AND_DRINK", name: String(localized: "Food & Drink")),
        AppCategory(id: gamesID, name: String(localized: "Games")),
        AppCategory(id: "GRAPHICS_AND_DESIGN", name: String(localized: "Graphics & Design")),
        AppCategory(id: "HEALTH_AND_FITNESS", name: String(localized: "Health & Fitness")),
        AppCategory(id: "LIFESTYLE", name: String(localized: "Lifestyle")),
        AppCategory(id: "MAGAZINES_AND_NEWSPAPERS", name: String(localized: "Magazines & Newspapers")),
        AppCategory(id: "MEDICAL", name: String(localized: "Medical")),
        AppCategory(id: "MUSIC", name: String(localized: "Music")),
        AppCategory(id: "NAVIGATION", name: String(localized: "Navigation")),
        AppCategory(id: "NEWS", name: String(localized: "News")),
        AppCategory(id: "PHOTO_AND_VIDEO", name: String(localized: "Photo & Video")),
        AppCategory(id: "PRODUCTIVITY", name: String(localized: "Productivity")),
        AppCategory(id: "REFERENCE", name: String(localized: "Reference")),
        AppCategory(id: "SHOPPING", name: String(localized: "Shopping")),
        AppCategory(id: "SOCIAL_NETWORKING", name: String(localized: "Social Networking")),
        AppCategory(id: "SPORTS", name: String(localized: "Sports")),
        AppCategory(id: "TRAVEL", name: String(localized: "Travel")),
        AppCategory(id: "UTILITIES", name: String(localized: "Utilities")),
        AppCategory(id: "WEATHER", name: String(localized: "Weather")),
    ]

    /// Games' subcategories; a game picks up to two.
    static let gamesSubcategories: [AppCategory] = [
        AppCategory(id: "GAMES_ACTION", name: String(localized: "Action")),
        AppCategory(id: "GAMES_ADVENTURE", name: String(localized: "Adventure")),
        AppCategory(id: "GAMES_BOARD", name: String(localized: "Board")),
        AppCategory(id: "GAMES_CARD", name: String(localized: "Card")),
        AppCategory(id: "GAMES_CASINO", name: String(localized: "Casino")),
        AppCategory(id: "GAMES_CASUAL", name: String(localized: "Casual")),
        AppCategory(id: "GAMES_FAMILY", name: String(localized: "Family")),
        AppCategory(id: "GAMES_MUSIC", name: String(localized: "Music")),
        AppCategory(id: "GAMES_PUZZLE", name: String(localized: "Puzzle")),
        AppCategory(id: "GAMES_RACING", name: String(localized: "Racing")),
        AppCategory(id: "GAMES_ROLE_PLAYING", name: String(localized: "Role Playing")),
        AppCategory(id: "GAMES_SIMULATION", name: String(localized: "Simulation")),
        AppCategory(id: "GAMES_SPORTS", name: String(localized: "Sports")),
        AppCategory(id: "GAMES_STRATEGY", name: String(localized: "Strategy")),
        AppCategory(id: "GAMES_TRIVIA", name: String(localized: "Trivia")),
        AppCategory(id: "GAMES_WORD", name: String(localized: "Word")),
    ]

    /// The name for an ID, or the ID itself when it isn't known here.
    static func name(for id: String?) -> String {
        guard let id else { return String(localized: "None") }
        return (all + gamesSubcategories).first { $0.id == id }?.name ?? id
    }
}
