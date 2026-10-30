//
//  ProjectFolderPath.swift
//  AppLocalizer
//

import Foundation

/// A project folder as people read it: "~/Developer/Lumen". The sandbox's
/// home is the app's container, so the person's own home comes from the
/// user database.
enum ProjectFolderPath {
    static var home: String {
        guard let directory = getpwuid(getuid())?.pointee.pw_dir else { return NSHomeDirectory() }
        return String(cString: directory)
    }

    static func abbreviated(_ path: String, home: String = home) -> String {
        guard path == home || path.hasPrefix(home + "/") else { return path }
        return "~" + path.dropFirst(home.count)
    }

    static func expanded(_ path: String, home: String = home) -> String {
        guard path == "~" || path.hasPrefix("~/") else { return path }
        return home + path.dropFirst()
    }
}
