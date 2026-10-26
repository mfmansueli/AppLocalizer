//
//  ChangeAlternative.swift
//  AppLocalizer
//

import Foundation

/// The other version of a field that both the person and an assistant
/// edited. The review sheet shows both side by side; one has to be picked
/// before the change can be pushed.
struct ChangeAlternative: Hashable, Codable, Sendable {
    var newValue: String
    var source: ChangeSource
    var requests: [PushRequest]
    var restoreRequests: [PushRequest] = []
}
