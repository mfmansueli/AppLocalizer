//
//  AssetLibraryModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The App Asset Library sheet: every image and video uploaded for an app,
/// whether each is on a page, and deleting several at once. Apple refuses
/// to delete a file a page still shows, so only files on no page can be
/// picked (or ones whose check failed: Apple then says no itself).
@MainActor
@Observable
final class AssetLibraryModel: Identifiable {
    enum Phase: Hashable {
        case loading
        case loaded
        case failed(String)
    }

    /// How many placements are checked at once.
    static let checkWidth = 4

    let id = UUID()
    let appID: StoreApp.ID
    let appName: String
    private let manager: any AssetLibraryManaging

    private(set) var phase: Phase = .loading
    private(set) var files: [AssetLibraryFile] = []
    /// How many pages show each file, once checked.
    private(set) var placementCounts: [AssetLibraryFile.ID: Int] = [:]
    /// Files whose check failed.
    private(set) var uncheckedIDs: Set<AssetLibraryFile.ID> = []
    var selection: Set<AssetLibraryFile.ID> = []
    var kind: AssetLibraryKindFilter = .all
    var onlyUnused = false
    var search = ""

    private(set) var isDeleting = false
    private(set) var deletingID: AssetLibraryFile.ID?
    private(set) var deletedCount = 0
    private(set) var deleteTotal = 0
    /// Why a file couldn't be deleted, in Apple's words.
    private(set) var deleteErrors: [AssetLibraryFile.ID: String] = [:]
    private(set) var notice: String?

    init(appID: StoreApp.ID, appName: String, manager: any AssetLibraryManaging) {
        self.appID = appID
        self.appName = appName
        self.manager = manager
    }

    // MARK: - Loading

    /// Reads the library, then checks which files are on a page.
    func load() async {
        phase = .loading
        notice = nil
        do {
            files = try await manager.assetLibraryFiles(appID: appID)
        } catch {
            phase = .failed(Self.describe(error))
            return
        }
        phase = .loaded
        let ids = Set(files.map(\.id))
        selection.formIntersection(ids)
        await checkPlacements()
    }

    private func checkPlacements() async {
        let pending = files.filter { placementCounts[$0.id] == nil }
        let manager = manager
        await withTaskGroup(of: (AssetLibraryFile.ID, Int?).self) { group in
            var next = 0
            while next < min(Self.checkWidth, pending.count) {
                let file = pending[next]
                group.addTask { await (file.id, try? manager.assetLibraryPlacementCount(file.asset)) }
                next += 1
            }
            while let (id, count) = await group.next() {
                if let count { placementCounts[id] = count } else { uncheckedIDs.insert(id) }
                if next < pending.count {
                    let file = pending[next]
                    group.addTask { await (file.id, try? manager.assetLibraryPlacementCount(file.asset)) }
                    next += 1
                }
            }
        }
    }

    // MARK: - What's shown

    var visibleFiles: [AssetLibraryFile] {
        let query = search.trimmingCharacters(in: .whitespaces)
        return files.filter { file in
            kind.includes(file)
                && (!onlyUnused || placementCounts[file.id] == 0)
                && (query.isEmpty || file.title.localizedStandardContains(query) || (file.fileName ?? "").localizedStandardContains(query))
        }
    }

    /// No page shows it, so Apple lets it go.
    func isUnused(_ file: AssetLibraryFile) -> Bool { placementCounts[file.id] == 0 }

    func canSelect(_ file: AssetLibraryFile) -> Bool {
        !isDeleting && (isUnused(file) || uncheckedIDs.contains(file.id))
    }

    /// "On 2 pages", "Not on any page", "Checking…", "Couldn’t check".
    func placementTitle(of file: AssetLibraryFile) -> String {
        if let count = placementCounts[file.id] {
            switch count {
            case 0: return String(localized: "Not on any page")
            case 1: return String(localized: "On 1 page")
            default: return String(localized: "On \(count) pages")
            }
        }
        return uncheckedIDs.contains(file.id) ? String(localized: "Couldn’t check") : String(localized: "Checking…")
    }

    /// "42 files · 30 on no page"; while checking, how far it got.
    var summaryTitle: String {
        let unused = files.count { isUnused($0) }
        let checked = placementCounts.count + uncheckedIDs.count
        let total = files.count == 1 ? String(localized: "1 file") : String(localized: "\(files.count) files")
        guard checked >= files.count else {
            return String(localized: "\(total) · checking which are on a page, \(checked) of \(files.count)")
        }
        return String(localized: "\(total) · \(unused) on no page")
    }

    // MARK: - Choosing

    func toggle(_ file: AssetLibraryFile) {
        guard canSelect(file) else { return }
        if selection.contains(file.id) { selection.remove(file.id) } else { selection.insert(file.id) }
    }

    /// Every shown file no page uses.
    func selectUnused() {
        selection = Set(visibleFiles.filter(isUnused).map(\.id))
    }

    func selectNone() {
        selection = []
    }

    var selectedFiles: [AssetLibraryFile] { files.filter { selection.contains($0.id) } }

    /// "Delete 5 Files…".
    var deleteTitle: String {
        selection.count == 1 ? String(localized: "Delete 1 File…") : String(localized: "Delete \(selection.count) Files…")
    }

    /// "5 selected · 23.4 MB".
    var selectionTitle: String? {
        guard !selection.isEmpty else { return nil }
        let bytes = Int64(selectedFiles.compactMap(\.fileSize).reduce(0, +))
        return String(localized: "\(selection.count) selected · \(bytes.formatted(.byteCount(style: .file)))")
    }

    var confirmationTitle: String {
        selection.count == 1
            ? String(localized: "Delete 1 file from \(appName)’s asset library?")
            : String(localized: "Delete \(selection.count) files from \(appName)’s asset library?")
    }

    // MARK: - Deleting

    /// Deletes the chosen files one by one. One Apple refuses keeps its
    /// reason on its row; the rest go on.
    func deleteSelected() async {
        let targets = selectedFiles
        guard !targets.isEmpty, !isDeleting else { return }
        isDeleting = true
        deleteTotal = targets.count
        deletedCount = 0
        deleteErrors = [:]
        notice = nil
        defer {
            isDeleting = false
            deletingID = nil
        }
        for file in targets {
            deletingID = file.id
            do {
                try await manager.deleteAssetLibraryAsset(file.asset)
                files.removeAll { $0.id == file.id }
                selection.remove(file.id)
                placementCounts[file.id] = nil
                deletedCount += 1
            } catch {
                deleteErrors[file.id] = Self.describe(error)
            }
        }
        notice = deleteErrors.isEmpty
            ? (deletedCount == 1 ? String(localized: "Deleted 1 file.") : String(localized: "Deleted \(deletedCount) files."))
            : String(localized: "Deleted \(deletedCount) of \(deleteTotal). \(deleteErrors.count) couldn’t be deleted: the reason is on each.")
    }

    /// "Deleting 3 of 5…" while it deletes.
    var deletingTitle: String? {
        guard isDeleting else { return nil }
        return String(localized: "Deleting \(min(deletedCount + deleteErrors.count + 1, deleteTotal)) of \(deleteTotal)…")
    }

    private static func describe(_ error: any Error) -> String {
        let text = (error as? AppStoreConnectError)?.pushFailureText ?? error.localizedDescription
        return text.hasSuffix(".") ? text : text + "."
    }
}
