//
//  KeyAssistantSendItem.swift
//  AppLocalizer
//

import Foundation

/// One part of what Generate Suggestions… sends, with its size: "23
/// commit messages since v1.3 · ~/Developer/Lumen", 1.8k.
struct KeyAssistantSendItem: Hashable, Identifiable, Sendable {
    var id: String
    var title: String
    var tokens: Int
}
