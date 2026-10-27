//
//  InAppTextColumn.swift
//  AppLocalizer
//

import Foundation

/// One column of the In-App Texts matrix: the group name, or a product's
/// name or description.
struct InAppTextColumn: Identifiable, Hashable, Sendable {
    /// `group.name`, or `<productID>.name` / `<productID>.description`.
    let id: String
    /// "Group name" or "Monthly · name".
    let title: String
    let field: InAppTextField
    /// Nil for the group name.
    let productID: String?

    static let groupName = InAppTextColumn(
        id: "group.name",
        title: InAppTextField.subscriptionGroupName.title,
        field: .subscriptionGroupName,
        productID: nil
    )

    /// The group name, then each product's name and description.
    static func columns(for products: [InAppTextProduct]) -> [InAppTextColumn] {
        [groupName] + products.flatMap { product in
            [product.kind.nameField, product.kind.descriptionField].map { field in
                InAppTextColumn(
                    id: "\(product.id).\(field.isDescription ? "description" : "name")",
                    title: "\(product.referenceName) · \(field.columnSuffix)",
                    field: field,
                    productID: product.id
                )
            }
        }
    }
}
