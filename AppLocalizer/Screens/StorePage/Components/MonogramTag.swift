//
//  MonogramTag.swift
//  AppLocalizer
//

import SwiftUI

/// The assistant's monogram on its own ("CC" for Claude Code), for cells
/// too small for `SourceTag`'s full "Proposed by Claude Code".
struct MonogramTag: View {
    let client: String

    var body: some View {
        Text(ChangeSource.assistant(client: client).monogram ?? "")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(Color(nsColor: .windowBackgroundColor))
            .frame(width: 14, height: 14)
            .background(Palette.label, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
            .accessibilityLabel(Text("Proposed by \(client)"))
    }
}
