//
//  AccessibilityEditorBar.swift
//  AppLocalizer
//

import SwiftUI

/// The bar a feature has to meet, above the checklist: people can complete
/// the app's common tasks with it.
struct AccessibilityEditorBar: View {
    let appName: String
    /// E.g. "writing an entry", "finding one"; from an assistant when it
    /// has read the project.
    let tasks: [String]

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: "info.circle")
                .imageScale(.small)
                .foregroundStyle(Palette.label2)
                .accessibilityHidden(true)
            Text("\(Text(lead).fontWeight(.semibold))\(Text(rest).foregroundStyle(Palette.label2))")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small + 1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill2, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("appInformation.accessibility.editor.bar")
    }

    private var lead: String {
        tasks.isEmpty
            ? String(localized: "Check a feature only if people can complete \(appName)’s common tasks with it.")
            : String(localized: "Check a feature only if people can complete \(appName)’s common tasks with it:")
    }

    private var rest: String {
        let tail = String(localized: "Calling an API somewhere isn’t enough. Each feature links to Apple’s criteria.")
        return tasks.isEmpty ? " " + tail : " " + tasks.joined(separator: ", ") + ". " + tail
    }
}

#Preview {
    AccessibilityEditorBar(appName: "Lumen", tasks: ["writing an entry", "finding one", "reading the weekly reflection", "unlocking"])
        .frame(width: 600)
        .padding()
}
