//
//  AccountSwitcher.swift
//  AppLocalizer
//

import SwiftUI

/// The top of the sidebar: the connected team, its role and key ID, and a
/// menu of saved keys plus "Add Another Key…" and "Manage Keys…".
struct AccountSwitcher: View {
    let accounts: [TeamAccount]
    let currentAccountID: TeamAccount.ID?
    var onSelect: (TeamAccount) -> Void = { _ in }
    var onAddKey: () -> Void = {}

    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Menu {
            Section("App Store Connect Keys") {
                ForEach(accounts) { account in
                    Toggle(isOn: Binding(get: { account.id == currentAccountID }, set: { _ in onSelect(account) })) {
                        Text(account.name)
                        Text("\(account.role) · Key \(account.keyID)")
                    }
                }
            }
            Divider()
            Button("Add Another Key…", action: onAddKey)
            Button("Manage Keys…") { openSettings() }
                .keyboardShortcut(",")
        } label: {
            label
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .accessibilityIdentifier("sidebar.accountSwitcher")
    }

    private var label: some View {
        HStack(spacing: Spacing.small) {
            Text(current?.initials ?? "?")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(nsColor: .windowBackgroundColor))
                .frame(width: 28, height: 28)
                .background(Palette.label, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(current?.name ?? String(localized: "No key"))
                    .font(.headline)
                    .lineLimit(1)
                if let current {
                    Text("\(current.role) · Key \(current.keyID)")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Palette.label2)
        }
        .padding(Spacing.small)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityTitle))
    }

    private var accessibilityTitle: String {
        guard let current else { return String(localized: "No key") }
        return String(localized: "\(current.name), \(current.role), Key \(current.keyID)")
    }

    private var current: TeamAccount? {
        accounts.first { $0.id == currentAccountID }
    }
}

#Preview {
    AccountSwitcher(
        accounts: [
            TeamAccount(id: "2X9R4HXF34", name: "Northpier Studio", role: "Admin"),
            TeamAccount(id: "Q7MZ3K8PLA", name: "Brightline Apps", role: "App Manager"),
        ],
        currentAccountID: "2X9R4HXF34"
    )
    .frame(width: 240)
    .padding()
}
