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
import AgentRunKit
import QuackInterface

/// Built-in tool that reads the contents of a file at a given path.
public struct ReadFileTool: AnyTool, Sendable {
    public typealias Context = QuackToolContext

    public var name: String { "builtin-read_file" }
    public var description: String { "Read the contents of a file at a given path." }

    public init() {}

    public var parametersSchema: JSONSchema {
        .object(
            properties: [
                "path": .string(description: "The path to the file to read. Relative paths resolve against the session's working directory, and the path must be inside it when one is set."),
            ],
            required: ["path"]
        )
    }

    public func execute(arguments: Data, context: QuackToolContext) async throws -> ToolResult {
        struct Args: Decodable {
            let path: String
        }

        let args: Args
        do {
            args = try JSONDecoder().decode(Args.self, from: arguments)
        } catch {
            return .error("Invalid arguments: expected { \"path\": \"...\" }")
        }

        // A session working directory scopes the tool; without one the path is
        // unrestricted, as it was before scoping.
        let url: URL
        if let scope = PathScope(workingDirectory: context.workingDirectory) {
            guard let resolved = scope.resolve(args.path) else {
                return .error(
                    "Path is outside this session's scope (\(scope.root.path)): \(args.path)"
                )
            }
            url = resolved
        } else {
            url = URL(fileURLWithPath: NSString(string: args.path).expandingTildeInPath)
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            return .error("File not found: \(args.path)")
        }

        guard FileManager.default.isReadableFile(atPath: url.path) else {
            return .error("Permission denied: cannot read \(args.path)")
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return .success(content)
        } catch {
            return .error("Failed to read file: \(error.localizedDescription)")
        }
    }
}
