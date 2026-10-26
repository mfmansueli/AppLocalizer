//
//  JSONValue+TemplatePaths.swift
//  AppLocalizer
//

import Foundation

// Dotted paths into a template's JSON, e.g. `caption.headline.size` or
// `slots.1.layout`: object members by name, array elements by index.
extension JSONValue {
    /// The value at `components`, or nil when a member or element is missing.
    func value(at components: some Collection<String>) -> JSONValue? {
        var current = self
        for component in components {
            switch current {
            case let .object(members):
                guard let next = members[component] else { return nil }
                current = next
            case let .array(elements):
                guard let index = Int(component), elements.indices.contains(index) else { return nil }
                current = elements[index]
            default:
                return nil
            }
        }
        return current
    }

    /// A copy with `value` at `components`, creating objects on the way;
    /// nil removes the member. Array elements must exist already.
    func setting(_ value: JSONValue?, at components: ArraySlice<String>) -> JSONValue {
        guard let first = components.first else { return value ?? .null }
        let rest = components.dropFirst()
        switch self {
        case var .array(elements):
            guard let index = Int(first), elements.indices.contains(index) else { return self }
            elements[index] = elements[index].setting(value, at: rest)
            return .array(elements)
        case var .object(members):
            if rest.isEmpty {
                members[first] = value
            } else {
                members[first] = (members[first] ?? .object([:])).setting(value, at: rest)
            }
            return .object(members)
        default:
            return rest.isEmpty && value == nil ? self : JSONValue.object([:]).setting(value, at: components)
        }
    }

    /// Numbers compare by value, whether they were written `0` or `0.0`.
    func isEquivalent(to other: JSONValue) -> Bool {
        switch (self, other) {
        case let (.array(lhs), .array(rhs)):
            lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { $0.isEquivalent(to: $1) }
        case let (.object(lhs), .object(rhs)):
            lhs.keys == rhs.keys && lhs.allSatisfy { key, value in rhs[key].map { value.isEquivalent(to: $0) } ?? false }
        default:
            if let lhs = doubleValue, let rhs = other.doubleValue { lhs == rhs } else { self == other }
        }
    }
}
