import Testing
@testable import PokepetCore

private let link = "claude://code/continue?session=local_00000000-0000-4000-8000-000000000000"

@Test func aWaitingDesktopConversationIsOpened() {
    #expect(ClickRule.action(target: .desktop(link), terminalApp: .iterm, claudeIsFrontmost: false) == .openConversation(link))
    #expect(ClickRule.action(target: .desktop(link), terminalApp: .iterm, claudeIsFrontmost: true) == .openConversation(link))
}

@Test func aWaitingBackgroundJobIsAttachedInTheChosenTerminal() {
    #expect(ClickRule.action(target: .job("c5adc286"), terminalApp: .terminal, claudeIsFrontmost: true) == .attachJob("c5adc286", in: .terminal))
}

@Test func aWaitingTerminalConversationBringsItsTerminalForward() {
    #expect(ClickRule.action(target: .terminal(.iterm), terminalApp: .terminal, claudeIsFrontmost: false) == .showTerminal(.iterm))
}

@Test func withoutAWaitingConversationItHopsAndBringsClaudeForward() {
    #expect(ClickRule.action(target: nil, terminalApp: .iterm, claudeIsFrontmost: false) == .hopAndShowClaude)
}

@Test func whenClaudeIsAlreadyInFrontItOnlyHops() {
    #expect(ClickRule.action(target: nil, terminalApp: .iterm, claudeIsFrontmost: true) == .hop)
}
