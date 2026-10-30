//
//  AssistantSetupSheet+Debug.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

@MainActor
extension AssistantSetupSheet {
    /// DEBUG scenes set it to open the sheet on a given step (design
    /// `setup-1` … `setup-done`).
    static var debugStep: AssistantSetupStep?
    /// `setup-key-*` open it on the API key's steps.
    static var debugMethod: AssistantSetupMethod?
    /// The key `setup-key-*` paste and check, with the project folder
    /// chosen; on step 4 the test runs too.
    static var debugKey: String?
}

@MainActor
extension AssistantSetupViewModel {
    func debugFill(key text: String) async {
        key.key = text
        key.projectFolder = URL(filePath: ProjectFolderPath.expanded("~/Developer/Lumen"))
        key.readsProjectFolder = true
        await key.checkKey()
        if step == .test { await key.runTest() }
    }
}
#endif
