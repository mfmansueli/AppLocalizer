//
//  ChangeQueuePersistence.swift
//  AppLocalizer
//

import Foundation

/// Where pending changes are kept between launches, so edits stay queued on
/// this Mac while offline or after quitting. `FileChangeQueuePersistence` is
/// the real one; tests and DEBUG scenes keep changes in memory (pass nil).
protocol ChangeQueuePersistence: Sendable {
    func load() throws -> [PendingChange]
    func save(_ changes: [PendingChange]) throws
}
