//
//  TranslationMethod.swift
//  AppLocalizer
//

import Foundation

/// How a missing cell gets its text.
enum TranslationMethod: Hashable, Sendable {
    /// Sent to the translator, with glossary terms protected.
    case translate
    /// Copied as is: URLs, and locales sharing the source's language and
    /// script (en-US → en-GB, pt-BR → pt-PT).
    case copy
}
