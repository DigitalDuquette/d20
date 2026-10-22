import Testing
@testable import TapD20

/// Seeded generator so a failing random test repeats.
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

struct RollTests {
    @Test(arguments: [4, 6, 8, 10, 12, 20, 100])
    func valuesStayInRangeAndEveryFaceShows(sides: Int) {
        var generator = SplitMix64(state: 7)
        var seen = Set<Int>()
        for _ in 0..<100_000 {
            let value = Dice.roll(RollSpec(sides: sides), using: &generator).values[0]
            #expect((1...sides).contains(value))
            seen.insert(value)
        }
        #expect(seen == Set(1...sides))
    }

    @Test func advantageRollsTwoDice() {
        var generator = SplitMix64(state: 1)
        #expect(Dice.roll(RollSpec(mode: .advantage), using: &generator).values.count == 2)
        #expect(Dice.roll(RollSpec(mode: .disadvantage), using: &generator).values.count == 2)
    }

    @Test func plainDiceRollTheirCount() {
        var generator = SplitMix64(state: 1)
        #expect(Dice.roll(RollSpec(sides: 6, count: 3), using: &generator).values.count == 3)
    }

    @Test func advantageIgnoredOffOneD20() {
        #expect(RollSpec(sides: 6, mode: .advantage).diceToRoll == 1)
        #expect(RollSpec(count: 2, mode: .advantage).diceToRoll == 2)
    }
}

struct ResolveTests {
    @Test func advantageKeepsHigher() {
        let r = Dice.resolve(RollSpec(mode: .advantage), values: [9, 18])
        #expect(r.total == 18)
        #expect(r.droppedIndex == 0)
    }

    @Test func disadvantageKeepsLower() {
        let r = Dice.resolve(RollSpec(mode: .disadvantage), values: [9, 18])
        #expect(r.total == 9)
        #expect(r.droppedIndex == 1)
    }

    @Test(arguments: [RollMode.advantage, .disadvantage])
    func tieKeepsFirst(mode: RollMode) {
        let r = Dice.resolve(RollSpec(mode: mode), values: [9, 9])
        #expect(r.droppedIndex == 1)
        #expect(r.breakdown == "9 (9 dropped)")
    }

    @Test func naturalIsJudgedBeforeModifier() {
        let crit = Dice.resolve(RollSpec(modifier: -2), values: [20])
        #expect(crit.isNatural20)
        #expect(crit.total == 18)
        let fumble = Dice.resolve(RollSpec(modifier: 5), values: [1])
        #expect(fumble.isNatural1)
        #expect(fumble.total == 6)
    }

    @Test func naturalComesFromKeptDie() {
        #expect(Dice.resolve(RollSpec(mode: .advantage), values: [20, 4]).isNatural20)
        #expect(!Dice.resolve(RollSpec(mode: .disadvantage), values: [20, 4]).isNatural20)
        #expect(Dice.resolve(RollSpec(mode: .disadvantage), values: [1, 20]).isNatural1)
    }

    @Test func noNaturalOffOneD20() {
        #expect(Dice.resolve(RollSpec(sides: 6), values: [1]).natural == nil)
        #expect(Dice.resolve(RollSpec(count: 2), values: [20, 20]).natural == nil)
    }

    @Test func multiDiceTotal() {
        let r = Dice.resolve(RollSpec(sides: 6, count: 8, modifier: 3), values: [4, 3, 6, 1, 5, 2, 4, 4])
        #expect(r.total == 32)
        #expect(r.droppedIndex == nil)
    }

    @Test(arguments: [
        (RollSpec(), [12], ""),
        (RollSpec(modifier: 3), [12], "12 + 3"),
        (RollSpec(modifier: -2), [12], "12 \u{2212} 2"),
        (RollSpec(mode: .advantage), [9, 18], "18 (9 dropped)"),
        (RollSpec(modifier: 3, mode: .advantage), [9, 18], "18 (9 dropped) + 3"),
        (RollSpec(modifier: -1, mode: .disadvantage), [9, 18], "9 (18 dropped) \u{2212} 1"),
    ])
    func breakdownMatchesWebApp(spec: RollSpec, values: [Int], text: String) {
        #expect(Dice.resolve(spec, values: values).breakdown == text)
    }

    @Test func signedUsesRealMinus() {
        #expect(Dice.signed(3) == "+3")
        #expect(Dice.signed(0) == "+0")
        #expect(Dice.signed(-2) == "\u{2212}2")
    }
}
