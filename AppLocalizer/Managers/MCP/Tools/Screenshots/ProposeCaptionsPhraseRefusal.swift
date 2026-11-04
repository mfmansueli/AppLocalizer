//
//  ProposeCaptionsPhraseRefusal.swift
//  AppLocalizer
//

import Foundation

/// Why `propose_captions` can't save a phrase item, said to the assistant.
struct ProposeCaptionsPhraseRefusal: Error, Equatable {
    var message: String

    init(_ message: String) {
        self.message = message
    }
}
