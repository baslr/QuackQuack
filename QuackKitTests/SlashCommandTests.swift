import Testing
import Foundation
@testable import QuackKit

struct SlashCommandTests {
    @Test func parsesGoalWithText() {
        #expect(SlashCommand.parse("/goal ship the release") == .setGoal("ship the release"))
    }

    @Test func trimsSurroundingWhitespace() {
        #expect(SlashCommand.parse("  /goal   ship it   ") == .setGoal("ship it"))
    }

    @Test func parsesBareGoalAsShow() {
        #expect(SlashCommand.parse("/goal") == .showGoal)
        #expect(SlashCommand.parse("/goal   ") == .showGoal)
    }

    @Test func parsesClear() {
        #expect(SlashCommand.parse("/goal clear") == .clearGoal)
        #expect(SlashCommand.parse("/goal CLEAR") == .clearGoal)
    }

    @Test func ignoresNonCommands() {
        #expect(SlashCommand.parse("what is my goal?") == nil)
        #expect(SlashCommand.parse("") == nil)
        #expect(SlashCommand.parse("goal ship it") == nil)
    }

    @Test func requiresGoalToBeAWholeWord() {
        #expect(SlashCommand.parse("/goalpost is a metaphor") == nil)
        #expect(SlashCommand.parse("/goals") == nil)
    }

    @Test func treatsClearAsTextWhenFollowedByMore() {
        #expect(SlashCommand.parse("/goal clear the backlog") == .setGoal("clear the backlog"))
    }
}
