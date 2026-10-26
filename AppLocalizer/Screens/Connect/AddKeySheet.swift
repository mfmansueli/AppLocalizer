//
//  AddKeySheet.swift
//  AppLocalizer
//

import SwiftUI

/// "Add Another Key…" from the app menu, the account switcher or Settings →
/// Account: the connect form in a sheet. A key that checks out is saved and
/// becomes the key in use.
struct AddKeySheet: View {
    @Environment(AppSession.self) private var session
    @Environment(\.keyChecker) private var keyChecker
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ConnectView(
            checker: keyChecker,
            onCancel: { dismiss() },
            onConnect: { credentials, check in
                try session.connect(credentials, check: check)
                dismiss()
            }
        )
        .frame(width: 580, height: 680)
    }
}
