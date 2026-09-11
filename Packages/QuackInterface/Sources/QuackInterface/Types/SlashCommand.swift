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

/// A command typed into the composer that the app handles locally instead of
/// sending to the model.
public enum SlashCommand: Equatable, Sendable {
    /// Set the session goal to the given text.
    case setGoal(String)
    /// Report the current session goal.
    case showGoal
    /// Remove the session goal.
    case clearGoal

    private static let goalPrefix = "/goal"

    /// Parse composer input as a slash command.
    ///
    /// Returns `nil` when the input is not a recognized command, in which case
    /// the caller should send it to the model unchanged.
    public static func parse(_ input: String) -> SlashCommand? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(goalPrefix) else { return nil }

        let remainder = trimmed.dropFirst(goalPrefix.count)

        // Guard against `/goalpost` and friends: the prefix must be the whole
        // word, so anything following it has to start with whitespace.
        guard remainder.isEmpty || remainder.first?.isWhitespace == true else {
            return nil
        }

        let argument = remainder.trimmingCharacters(in: .whitespacesAndNewlines)

        switch argument.lowercased() {
        case "":
            return .showGoal
        case "clear":
            return .clearGoal
        default:
            return .setGoal(argument)
        }
    }
}
