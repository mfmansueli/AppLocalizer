//
//  Territory+Locale.swift
//  AppLocalizer
//

import Foundation

extension Territory {
    /// The locale people in this territory most likely use, such as `pt-Latn-BR`
    /// for Brazil, so a price reads the way it does there (“R$ 219,90”).
    var localeIdentifier: String {
        Locale.Language(identifier: "und-" + alpha2).maximalIdentifier
    }
}
