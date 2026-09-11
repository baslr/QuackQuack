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

/// Builds Seatbelt profiles for `sandbox-exec`.
nonisolated enum SandboxProfile {
    /// A profile that confines file writes to `root` and its subdirectories.
    ///
    /// Reads stay open by design. A `(deny default)` profile has to enumerate
    /// every dylib, config file and Mach service that arbitrary developer
    /// tooling touches; getting that list wrong does not read as a denied
    /// operation but as the command itself failing, which is worse than the
    /// exposure it buys. Writes are the destructive direction, they are what
    /// the kernel can confine reliably, and that is what this profile does.
    ///
    /// Two deliberate exceptions: the temporary directories, because compilers,
    /// `git` and most package managers cannot run without them, and the handful
    /// of `/dev` entries that stand in for stdout, stderr and a terminal.
    static func writeConfined(to root: URL) -> String {
        """
        (version 1)
        (allow default)

        (deny file-write*)
        (allow file-write* (subpath \(literal(root.path))))

        ; Temporary directories — required by compilers, git and package managers.
        (allow file-write* (subpath "/private/tmp"))
        (allow file-write* (subpath "/private/var/tmp"))
        (allow file-write* (subpath "/private/var/folders"))

        ; Standard streams and terminals.
        (allow file-write*
            (literal "/dev/null")
            (literal "/dev/zero")
            (literal "/dev/tty")
            (literal "/dev/stdout")
            (literal "/dev/stderr")
            (literal "/dev/ptmx")
            (subpath "/dev/fd")
            (regex #"^/dev/ttys[0-9]+$"))
        """
    }

    /// Quotes a path as a Seatbelt string literal.
    private static func literal(_ path: String) -> String {
        let escaped = path
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
