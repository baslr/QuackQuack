import Testing
import Foundation
@testable import QuackKit

struct PathScopeTests {

    /// Creates a scope root with a `nested/` subdirectory and returns both,
    /// canonicalized the same way `PathScope` canonicalizes its root.
    private func makeScope() throws -> (scope: PathScope, root: URL) {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("PathScopeTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("nested"),
            withIntermediateDirectories: true
        )
        let scope = try #require(PathScope(workingDirectory: root.path))
        return (scope, scope.root)
    }

    @Test func noScopeWithoutWorkingDirectory() {
        #expect(PathScope(workingDirectory: nil) == nil)
        #expect(PathScope(workingDirectory: "") == nil)
        #expect(PathScope(workingDirectory: "   ") == nil)
    }

    @Test func acceptsRelativePathInsideScope() throws {
        let (scope, root) = try makeScope()
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(scope.resolve("nested/file.txt")?.path == root.appendingPathComponent("nested/file.txt").path)
    }

    @Test func acceptsAbsolutePathInsideScope() throws {
        let (scope, root) = try makeScope()
        defer { try? FileManager.default.removeItem(at: root) }

        let inside = root.appendingPathComponent("nested/file.txt").path
        #expect(scope.resolve(inside)?.path == inside)
    }

    @Test func acceptsTheRootItself() throws {
        let (scope, root) = try makeScope()
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(scope.resolve(root.path)?.path == root.path)
    }

    @Test func rejectsAbsolutePathOutsideScope() throws {
        let (scope, root) = try makeScope()
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(scope.resolve("/etc/hosts") == nil)
    }

    @Test func rejectsTraversalOutOfScope() throws {
        let (scope, root) = try makeScope()
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(scope.resolve("nested/../../escaped.txt") == nil)
        #expect(scope.resolve("../escaped.txt") == nil)
        #expect(scope.resolve(root.appendingPathComponent("../escaped.txt").path) == nil)
    }

    @Test func allowsTraversalThatStaysInsideScope() throws {
        let (scope, root) = try makeScope()
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(scope.resolve("nested/../file.txt")?.path == root.appendingPathComponent("file.txt").path)
    }

    @Test func rejectsSymlinkPointingOutOfScope() throws {
        let (scope, root) = try makeScope()
        defer { try? FileManager.default.removeItem(at: root) }

        let link = root.appendingPathComponent("escape-hatch")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: URL(fileURLWithPath: "/etc"))

        #expect(scope.resolve("escape-hatch/hosts") == nil)
    }

    @Test func acceptsFileThatDoesNotExistYet() throws {
        let (scope, root) = try makeScope()
        defer { try? FileManager.default.removeItem(at: root) }

        // Writes target files, and often directories, that are not there yet.
        let target = root.appendingPathComponent("brand/new/file.txt")
        #expect(scope.resolve("brand/new/file.txt")?.path == target.path)
    }

    @Test func rejectsSiblingDirectoryWithScopeAsPrefix() throws {
        let (scope, root) = try makeScope()
        defer { try? FileManager.default.removeItem(at: root) }

        // "/scope-evil" must not pass just because it starts with "/scope".
        #expect(scope.resolve(root.path + "-evil/file.txt") == nil)
    }
}

struct SandboxProfileTests {
    @Test func confinesWritesToTheGivenRoot() {
        let profile = SandboxProfile.writeConfined(to: URL(fileURLWithPath: "/tmp/scope"))

        #expect(profile.hasPrefix("(version 1)"))
        #expect(profile.contains("(deny file-write*)"))
        #expect(profile.contains("(allow file-write* (subpath \"/tmp/scope\"))"))
    }

    @Test func escapesQuotesInTheRootPath() {
        let profile = SandboxProfile.writeConfined(to: URL(fileURLWithPath: "/tmp/we\"ird"))

        #expect(profile.contains("(subpath \"/tmp/we\\\"ird\")"))
    }
}
