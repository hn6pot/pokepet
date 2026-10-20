import Testing
@testable import PokepetCore

@Test("tokens : arrondi, une décimale sous 10, unité k, M ou G", arguments: [
    (0, "0"), (999, "999"), (1_000, "1,0\u{202F}k"), (4_520, "4,5\u{202F}k"), (9_960, "10\u{202F}k"),
    (400_737, "401\u{202F}k"), (1_200_000, "1,2\u{202F}M"), (144_030_563, "144\u{202F}M"), (2_500_000_000, "2,5\u{202F}G"),
])
func tokens(n: Int, expected: String) {
    #expect(NumberFormat.tokens(n) == expected)
}

@Test("compte : milliers séparés", arguments: [(575, "575"), (1_042, "1\u{202F}042"), (1_234_567, "1\u{202F}234\u{202F}567")])
func count(n: Int, expected: String) {
    #expect(NumberFormat.count(n) == expected)
}
