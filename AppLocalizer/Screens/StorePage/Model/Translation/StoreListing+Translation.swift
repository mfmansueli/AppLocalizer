//
//  StoreListing+Translation.swift
//  AppLocalizer
//

import Foundation

extension StoreListing {
    /// "Translate Missing…" for a scope; see `TranslationPlanner`.
    func translationPlan(scope: TranslationScope = .everything) -> TranslationJob {
        TranslationPlanner.plan(self, scope: scope)
    }

    /// The finished items of a job as suggestions against the current text.
    func suggestions(from job: TranslationJob) -> TranslationReview {
        TranslationReview(suggestions: job.items.compactMap { item in
            guard let result = item.result else { return nil }
            return TranslationSuggestion(key: item.key, currentText: draft(item.key).local, suggestedText: result)
        })
    }

    /// Applies the accepted suggestions. They stay tagged machine-translated
    /// until edited or marked reviewed; copied URLs aren't tagged. Returns
    /// how many fields were filled.
    @discardableResult
    mutating func apply(_ review: TranslationReview) -> Int {
        for suggestion in review.accepted {
            acceptMachineTranslation(suggestion.suggestedText, for: suggestion.key.field, in: suggestion.key.locale)
        }
        return review.accepted.count
    }

    /// Applies every finished item straight away, without a review step,
    /// tagged machine-translated: what "Send What's New to Every Locale"
    /// does. Returns how many fields were filled.
    @discardableResult
    mutating func applyTranslations(of job: TranslationJob) -> Int {
        var count = 0
        for item in job.items {
            guard let result = item.result else { continue }
            acceptMachineTranslation(result, for: item.key.field, in: item.key.locale)
            count += 1
        }
        return count
    }
}
