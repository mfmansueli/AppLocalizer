//
//  ActionToast.swift
//  AppLocalizer
//

import SwiftUI

/// What an action did, at the bottom of a section for a few seconds, with
/// Undo when it can be taken back. Nothing asks for confirmation first:
/// the toast is how the person takes a batch back. VoiceOver announces it.
struct ActionToast: View {
    let message: ToastMessage
    /// How long it stays; a toast with Undo stays longer, to reach it.
    var duration: Duration?
    var onUndo: () -> Void = {}
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Palette.accent)
                .accessibilityHidden(true)
            Text(message.text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("toast.text")
            if message.canUndo {
                Button("Undo", action: onUndo)
                    .controlSize(.small)
                    .accessibilityIdentifier("toast.undo")
            }
            Button("Dismiss", systemImage: "xmark", action: onDismiss)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small + 2)
        .frame(maxWidth: 560)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
                .strokeBorder(Palette.separator2, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("toast")
        .task(id: message.id) {
            AccessibilityNotification.Announcement(message.text).post()
            try? await Task.sleep(for: duration ?? (message.canUndo ? .seconds(10) : .seconds(6)))
            guard !Task.isCancelled else { return }
            onDismiss()
        }
    }
}

#Preview {
    VStack(spacing: Spacing.medium) {
        ActionToast(message: ToastMessage(text: "Accepted 5 suggestions in German. Nothing is pushed yet.", canUndo: true)) {}
        ActionToast(message: ToastMessage(text: "Claude Code sent 4 suggestions. Nothing changes until you accept them.")) {}
    }
    .padding()
}
