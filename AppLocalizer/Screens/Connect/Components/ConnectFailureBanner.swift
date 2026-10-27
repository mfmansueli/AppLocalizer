//
//  ConnectFailureBanner.swift
//  AppLocalizer
//

import SwiftUI

/// Why "Connect" failed, above the Connect button: Apple rejected the key
/// (401), the role is too low (403), the Mac is offline (with Try Again),
/// or another error.
struct ConnectFailureBanner: View {
    let failure: KeyCheckFailure
    let onRetry: () -> Void

    var body: some View {
        HStack(alignment: isOffline ? .center : .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: isOffline ? "wifi.slash" : "exclamationmark.circle")
                .foregroundStyle(isOffline ? Palette.label2 : Palette.dangerMark)
                .accessibilityHidden(true)
            if isOffline {
                Text("\(Text(failure.title).bold()) \(Text(failure.message).foregroundStyle(Palette.label2))")
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.small)
                Button("Try Again", action: onRetry)
                    .controlSize(.small)
                    .accessibilityIdentifier("connect.retry")
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(failure.title)
                        .bold()
                    Text(failure.message)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
                Spacer(minLength: 0)
            }
        }
        .font(.callout)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small + 1)
        .background(isOffline ? Palette.fill2 : Palette.dangerTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("connect.error")
    }

    private var isOffline: Bool { failure == .offline }
}

#Preview {
    VStack {
        ConnectFailureBanner(failure: .rejected) {}
        ConnectFailureBanner(failure: .roleTooLow) {}
        ConnectFailureBanner(failure: .offline) {}
    }
    .padding()
    .frame(width: 500)
}
