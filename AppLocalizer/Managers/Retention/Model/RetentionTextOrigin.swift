//
//  RetentionTextOrigin.swift
//  AppLocalizer
//

import Foundation

/// Who wrote one language of a retention message: the person, AppLocalizer's
/// translation, or an assistant (a draft or a shorter version).
enum RetentionTextOrigin: Hashable, Codable, Sendable {
    case written
    case translated
    case assistant(client: String)
}
