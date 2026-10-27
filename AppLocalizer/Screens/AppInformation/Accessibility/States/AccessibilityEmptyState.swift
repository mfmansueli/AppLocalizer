//
//  AccessibilityEmptyState.swift
//  AppLocalizer
//

import SwiftUI

/// Nothing declared for any device yet: what the labels are, that they're
/// voluntary now and will be required, and where to start.
struct AccessibilityEmptyState: View {
    let appName: String
    let firstFamily: DeviceFamily
    let onDeclare: () -> Void

    var body: some View {
        Card(padding: Spacing.xLarge) {
            HStack(alignment: .top, spacing: Spacing.large) {
                Image(systemName: "accessibility")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Palette.label2)
                    .frame(width: 36)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Nothing declared yet")
                        .font(.title3.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    Text("""
                    Accessibility Nutrition Labels tell people, before they download, which features work in \(appName): VoiceOver, Larger \
                    Text, Reduced Motion and six others. You answer per device; Apple shows the answers on the product page. They’re voluntary \
                    today, and Apple has said they’ll be required to submit new apps and updates.
                    """)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: Spacing.small) {
                        Button(String(localized: "Declare for \(firstFamily.name)"), action: onDeclare)
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("appInformation.accessibility.declareFirst")
                        ExternalLinkButton(title: String(localized: "How Apple Evaluates Support"), url: AccessibilityFeature.overviewURL)
                            .accessibilityIdentifier("appInformation.accessibility.howApple")
                    }
                    .padding(.top, Spacing.xxSmall)
                }
            }
        }
        .accessibilityIdentifier("appInformation.accessibility.empty")
    }
}

#Preview {
    AccessibilityEmptyState(appName: "Lumen", firstFamily: .iPhone) {}
        .frame(width: 720)
        .padding()
}
