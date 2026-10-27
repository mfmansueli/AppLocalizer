//
//  TemplateInspectorSection+Untitled.swift
//  AppLocalizer
//

import SwiftUI

/// Sections with nothing on the title's line.
extension TemplateInspectorSection where Accessory == EmptyView {
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, accessory: { EmptyView() }, content: content)
    }
}
