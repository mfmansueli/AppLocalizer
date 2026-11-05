//
//  NewSubscription+Validation.swift
//  AppLocalizer
//

import Foundation

extension NewSubscription {
    /// Everything App Store Connect would refuse, in the form's order.
    /// `takenProductIDs` are the app's products' and the other new
    /// subscriptions' in Review & Push; `groupNames` are the app's groups'
    /// reference names.
    func problems(takenProductIDs: Set<String>, groupNames: [String]) -> [NewSubscriptionProblem] {
        var problems: [NewSubscriptionProblem] = []
        if case let .new(referenceName, displayName) = group {
            problems += Self.textProblems(referenceName, field: .groupReferenceName)
            if let existing = groupNames.first(where: { $0.compare(Self.trimmed(referenceName), options: .caseInsensitive) == .orderedSame }) {
                problems.append(.groupExists(existing))
            }
            problems += Self.textProblems(displayName, field: .groupDisplayName)
        }
        problems += Self.textProblems(referenceName, field: .referenceName)
        problems += productIDProblems(taken: takenProductIDs)
        problems += Self.textProblems(displayName, field: .displayName)
        problems += Self.textProblems(description, field: .description)
        if let price {
            if !Self.isValidPrice(price) { problems.append(.invalidPrice) }
        } else {
            problems.append(.missing(.price))
        }
        problems += Self.textProblems(reviewNote, field: .reviewNote, isRequired: false)
        return problems
    }

    /// Above zero, with at most two decimals.
    static func isValidPrice(_ price: Decimal) -> Bool {
        price > 0 && price < 100_000 && price.rounded(scale: 2) == price
    }

    /// `9.99`, `9,99` or `$9.99` → 9.99; nil when it isn't a number.
    static func price(from text: String) -> Decimal? {
        let cleaned = text.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "US", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty, cleaned.allSatisfy({ $0.isNumber || $0 == "." }), cleaned.filter({ $0 == "." }).count <= 1 else { return nil }
        return Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
    }

    private func productIDProblems(taken: Set<String>) -> [NewSubscriptionProblem] {
        let id = Self.trimmed(productID)
        var problems = Self.textProblems(id, field: .productID)
        guard !id.isEmpty else { return problems }
        if !id.allSatisfy({ ($0.isASCII && ($0.isLetter || $0.isNumber)) || $0 == "." || $0 == "_" }) {
            problems.append(.invalidProductID)
        }
        if taken.contains(where: { $0.compare(id, options: .caseInsensitive) == .orderedSame }) {
            problems.append(.productIDTaken(id))
        }
        return problems
    }

    private static func textProblems(_ text: String, field: NewSubscriptionField, isRequired: Bool = true) -> [NewSubscriptionProblem] {
        let text = trimmed(text)
        if text.isEmpty { return isRequired ? [.missing(field)] : [] }
        if let limit = field.limit, text.count > limit { return [.tooLong(field, count: text.count)] }
        return []
    }

    static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
