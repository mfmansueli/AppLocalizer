//
//  AppInformationToast.swift
//  AppLocalizer
//

import SwiftUI

/// What an action did, at the bottom of the page for a few seconds, e.g.
/// "Saved. It’s waiting in Review & Push…". VoiceOver announces it.
struct AppInformationToast: View {
    let text: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Palette.accent)
                .accessibilityHidden(true)
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Button("Dismiss", systemImage: "xmark", action: onDismiss)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small + 2)
        .frame(maxWidth: 520)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
                .strokeBorder(Palette.separator2, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.toast")
        .task(id: text) {
            AccessibilityNotification.Announcement(text).post()
            try? await Task.sleep(for: .seconds(6))
            onDismiss()
        }
    }
}

#Preview {
    AppInformationToast(text: "Saved. It’s waiting in Review & Push, where you choose whether to publish it.") {}
        .padding()
}
