//
//  InAppTextChangeBuilder+Reading.swift
//  AppLocalizer
//

import Foundation

extension InAppTextChangeBuilder {
    /// Lays queued in-app text changes onto a matrix with App Store
    /// Connect's values, as your edits.
    func apply(_ changes: [PendingChange], to matrix: inout InAppTextMatrix) {
        for change in changes where owns(change) {
            guard let document = StorePageWriteDocument.decode(change.requests.first?.body),
                  let (owner, locale) = target(of: change, document: document)
            else { continue }
            for column in matrix.columns where column.productID == owner.productID {
                let attribute = column.field.isDescription ? "description" : "name"
                guard document.data.attributes.keys.contains(attribute) else { continue }
                let text = document.attribute(attribute) ?? ""
                guard text != matrix.value(column, in: locale) else { continue }
                matrix.edit(column, in: locale, to: text)
            }
        }
    }

    /// The owner from the id, the locale from the body (new) or the id.
    private func target(of change: PendingChange, document: StorePageWriteDocument) -> (Owner, StoreLocale)? {
        let parts = change.id.dropFirst(idPrefix.count).split(separator: ".").map(String.init)
        guard parts.count >= 4 else { return nil }
        let ownerComponent = "\(parts[0]).\(parts[1])"
        guard let owner = owners.first(where: { $0.idComponent == ownerComponent }) else { return nil }
        let code = document.attribute("locale") ?? parts[2]
        guard let locale = StoreLocaleCatalog.locale(code: code) else { return nil }
        return (owner, locale)
    }
}
