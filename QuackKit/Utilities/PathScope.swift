// Copyright 2026 Link Dupont
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

/// Confines tool-supplied paths to a session's working directory.
///
/// Paths reaching the built-in tools are chosen by the model, so `..`, a
/// symlink, or a plain absolute path can all point outside the directory the
/// user scoped the session to. ``resolve(_:)`` rejects those.
nonisolated struct PathScope: Sendable {
    /// The canonical root every resolved path must stay inside.
    let root: URL

    /// Creates a scope for a session's working directory.
    ///
    /// Returns `nil` when the session has no working directory, which leaves
    /// the tools unrestricted — the behaviour before a directory is chosen.
    init?(workingDirectory: String?) {
        guard let directory = workingDirectory?.trimmingCharacters(in: .whitespacesAndNewlines),
              !directory.isEmpty
        else { return nil }

        let expanded = NSString(string: directory).expandingTildeInPath
        root = Self.canonicalize(URL(fileURLWithPath: expanded))
    }

    /// Resolves a tool-supplied path against the scope.
    ///
    /// Relative paths resolve against ``root``, matching how the tools behaved
    /// before scoping. Returns `nil` when the result lies outside the scope.
    func resolve(_ path: String) -> URL? {
        let expanded = NSString(string: path).expandingTildeInPath
        let candidate = expanded.hasPrefix("/")
            ? URL(fileURLWithPath: expanded)
            : root.appendingPathComponent(expanded)

        let canonical = Self.canonicalize(candidate)
        return contains(canonical) ? canonical : nil
    }

    /// Whether an already-canonical URL lies at or below ``root``.
    func contains(_ url: URL) -> Bool {
        url.path == root.path || url.path.hasPrefix(root.path + "/")
    }

    /// Standardizes a URL and resolves symlinks in its deepest existing
    /// ancestor.
    ///
    /// Resolving only the existing prefix is what makes this usable for files
    /// that are about to be created: the components that do not exist yet are
    /// appended back unchanged. A symlinked parent therefore cannot smuggle a
    /// write out of the scope, and `..` is already gone after standardizing.
    private static func canonicalize(_ url: URL) -> URL {
        var existing = url.standardizedFileURL
        var missing: [String] = []

        while !FileManager.default.fileExists(atPath: existing.path),
              existing.pathComponents.count > 1 {
            missing.append(existing.lastPathComponent)
            existing = existing.deletingLastPathComponent()
        }

        var resolved = existing.resolvingSymlinksInPath()
        for component in missing.reversed() {
            resolved = resolved.appendingPathComponent(component)
        }
        return resolved.standardizedFileURL
    }
}
