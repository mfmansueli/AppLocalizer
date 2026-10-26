//
//  Banner.swift
//  AppLocalizer
//

import SwiftUI

/// A full-width notice above a section's content, shown with
/// `.safeAreaInset(edge: .top)`: offline, rate limited, an API error with
/// Apple's detail, a partial push failure, or plain information.
struct Banner<Actions: View>: View {
    let kind: BannerKind
    let title: String
    var message: String?
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: kind.systemImage)
                .foregroundStyle(kind.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.semibold))
                if let message {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
            Spacer(minLength: Spacing.medium)
            HStack(spacing: Spacing.small) {
                actions()
            }
            .controlSize(.small)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(kind.background, in: RoundedRectangle(cornerRadius: Radius.banner))
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .contain)
    }
}

extension Banner where Actions == EmptyView {
    init(kind: BannerKind, title: String, message: String? = nil) {
        self.init(kind: kind, title: title, message: message) { EmptyView() }
    }
}

#Preview {
    VStack(spacing: 0) {
        Banner(kind: .offline, title: "You're offline", message: "Edits stay queued on this Mac.")
        Banner(kind: .rateLimited, title: "Rate limited", message: "Pushing resumes at 12:00; nothing is lost.")
        Banner(kind: .apiError, title: "App Store Connect returned an error (409)", message: "ENTITY_ERROR.ATTRIBUTE.INVALID") {
            Button("Try Again") {}
        }
    }
    .frame(width: 700)
}
