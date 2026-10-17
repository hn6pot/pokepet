import Testing
@testable import PokepetCore

private let link = "claude://code/continue?session=local_00000000-0000-4000-8000-000000000000"

@Test func aWaitingDesktopConversationIsOpened() {
    #expect(ClickRule.action(link: link, claudeIsFrontmost: false) == .openConversation(link))
    #expect(ClickRule.action(link: link, claudeIsFrontmost: true) == .openConversation(link))
}

@Test func withoutAWaitingConversationItHopsAndBringsClaudeForward() {
    #expect(ClickRule.action(link: nil, claudeIsFrontmost: false) == .hopAndShowClaude)
}

@Test func whenClaudeIsAlreadyInFrontItOnlyHops() {
    #expect(ClickRule.action(link: nil, claudeIsFrontmost: true) == .hop)
}
